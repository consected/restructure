# frozen_string_literal: true

# Benchmark spec (issue #1362 final stage - `immutable` browser-cache decision).
#
# PagesController#template currently answers a matching version token with
# `Cache-Control: private, max-age=604800, immutable`. That is only safe because
# partial_cache_key embeds current_sign_in_at, so the URL token rotates on every login and
# a user always has an escape hatch from a bad payload. The final stage of #1362 removes
# current_sign_in_at to stop the fragment/browser caches going cold on every login - which
# would leave a broken or stale payload pinned in a browser for 7 days with no revalidation
# and no in-app action that can clear it.
#
# The proposed trade is to drop `immutable` and let the existing ETag path answer 304, so
# the browser revalidates cheaply instead of never. This spec measures what that trade
# actually costs, since the answer turns entirely on how expensive a 304 is:
#
#   1. 304 conditional GET (If-None-Match matches)     - the cost `immutable` avoids today
#   2. 200 with a WARM fragment cache                  - an ETag miss, no ERB re-render
#   3. 200 with a COLD fragment cache                  - the full ERB render, for scale
#
# Note the ETag is Digest::SHA256(partial_cache_key(...)) and `stale?` returns BEFORE
# `render`, so scenario 1 never renders the partial at all - its cost is purely the
# cache-key queries. Measuring it is what makes the `immutable` decision evidence-based
# rather than a guess.
#
# Opt-in only (see spec/rails_helper.rb config.filter_run_excluding benchmark: true) -
# run explicitly with:
#   RUN_BENCHMARKS=true bundle exec rspec \
#     spec/requests/pages/template_revalidation_cost_benchmark_spec.rb
#
# Primary metric is SQL query count per request (deterministic - unlike wall clock, immune
# to machine load), with elapsed time and response bytes as secondary.

require 'rails_helper'

RSpec.describe 'Cost of revalidating pages#template instead of caching it immutably (issue #1362)',
               type: :request, benchmark: true do
  include ModelSupport
  include MasterSupport
  include DynamicModelSupport

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @admin, = create_admin
    @user, = create_user
    @app_type = @user.app_type
    create_master(@user)

    setup_dm_resource('rv_recs', 'RV Rec')
    create_resource_panel
    setup_access :dynamic_model__rv_recs, user: @user

    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name: panel_name).each do |pl|
      pl.disable!(@admin)
    end
    Rails.application.routes_reloader.reload!
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  before do
    sign_in @user
  end

  def panel_name
    'rv-panel'
  end

  def setup_dm_resource(table_name, label)
    class_name = table_name.singularize.camelize.to_sym
    DynamicModel.active.where(table_name:).reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    DynamicModel.create!(
      current_admin: @admin,
      name: label,
      schema_name: 'dynamic_test',
      table_name:,
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id'
    )
  end

  def create_resource_panel
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name:).each { |pl| pl.disable!(@admin) }
    Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @app_type.id,
      layout_name: 'master',
      panel_name:,
      panel_label: 'RV Panel',
      panel_position: 200,
      options: <<~YAML
        contains:
          resources:
            - dynamic_model__rv_recs
      YAML
    )
  end

  # The token the browser reads from _setup_app.html.erb and later uses as the URL segment
  # in its deferred AJAX GET /pages/:id/template - only a MATCHING token takes the
  # immutable/ETag path being measured here (issue #1287).
  def embedded_template_version
    get '/masters/search'
    expect(response.status).to eq 200
    match = response.body.match(/_fpa\.state\.template_version\s*=\s*'([a-f0-9]{64})'/)
    expect(match).to be_present, 'expected _fpa.state.template_version to be embedded in the page HTML'
    match[1]
  end

  # Clears the outer per-user page-fragment cache WITHOUT rotating server_cache_version, so
  # the next request re-executes the view while still reusing the already-compiled
  # Handlebars artifacts (see the equivalent helper in
  # handlebars_compile_cost_benchmark_spec.rb).
  def bust_page_fragment_cache!
    scv = Rails.cache.read('server_cache_version')
    Rails.cache.clear
    Rails.cache.write('server_cache_version', scv) if scv
  end

  # Count real (non-SCHEMA, non-TRANSACTION) SQL statements issued while serving one
  # request, alongside its elapsed time and response size.
  def measure
    queries = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name])
    end

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(1)

    { queries:, elapsed_ms:, bytes: response.body.bytesize, status: response.status }
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it 'reports the cost of a 304 revalidation against a warm and a cold 200' do
    token = embedded_template_version

    # Warm everything first: compiled Handlebars artifacts AND the outer fragment cache,
    # so the measurements below isolate revalidation cost rather than first-request cost.
    get "/pages/#{token}/template"
    expect(response).to have_http_status(:ok)
    etag = response.headers['ETag']
    expect(etag).to be_present

    revalidation = measure do
      get "/pages/#{token}/template", headers: { 'HTTP_IF_NONE_MATCH' => etag }
    end
    expect(revalidation[:status]).to eq 304

    warm_200 = measure do
      get "/pages/#{token}/template", headers: { 'HTTP_IF_NONE_MATCH' => '"deliberately-stale-etag"' }
    end
    expect(warm_200[:status]).to eq 200

    bust_page_fragment_cache!
    token = embedded_template_version
    cold_200 = measure do
      get "/pages/#{token}/template", headers: { 'HTTP_IF_NONE_MATCH' => '"deliberately-stale-etag"' }
    end
    expect(cold_200[:status]).to eq 200

    message = <<~REPORT
      issue #1362 immutable-vs-revalidate benchmark:
        304 revalidation   queries=#{revalidation[:queries]} elapsed=#{revalidation[:elapsed_ms]}ms bytes=#{revalidation[:bytes]}
        200 warm fragment  queries=#{warm_200[:queries]} elapsed=#{warm_200[:elapsed_ms]}ms bytes=#{warm_200[:bytes]}
        200 cold fragment  queries=#{cold_200[:queries]} elapsed=#{cold_200[:elapsed_ms]}ms bytes=#{cold_200[:bytes]}
    REPORT
    Rails.logger.warn message
    warn message

    # The decision criterion: a 304 must cost materially less than serving the body, and
    # must not re-render the partial - otherwise dropping `immutable` trades a real
    # per-page-load cost for recoverability, rather than a negligible one.
    expect(revalidation[:bytes]).to eq 0
    expect(revalidation[:queries]).to be < cold_200[:queries]
  end
end
