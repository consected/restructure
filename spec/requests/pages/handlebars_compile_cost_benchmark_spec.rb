# frozen_string_literal: true

# Benchmark spec (issue #1362 Stage 2, Phase 0 - measurement gate).
#
# Stage 1 (#1377) content-addressed compiled Handlebars templates/partials, so identical
# rendered source is only ever compiled once, however many users request it. This spec
# measures what that leaves: after a simulated restart, how many users pay the node CLI
# compile cost before a page request stops shelling out at all.
#
# It exists to answer the open question from the Stage 1/Stage 2 split: if the 2nd and
# 3rd distinct user already show zero Utilities::ProcessPipes.pipe_in_out calls, only the
# very first request after a restart is expensive, and Stage 2 (an offline render
# harness, candidate selection, and a warmer) only buys back that single request plus
# brand-new users - a narrow benefit that should be re-justified before building it.
#
# Opt-in only (see spec/rails_helper.rb config.filter_run_excluding benchmark: true) -
# run explicitly with:
#   RUN_BENCHMARKS=true app-scripts/headless_rspec.sh \
#     spec/requests/pages/handlebars_compile_cost_benchmark_spec.rb
#
# Primary metric is the number of Utilities::ProcessPipes.pipe_in_out calls per request
# (deterministic - unlike wall clock, immune to machine load), not elapsed time.

require 'rails_helper'

RSpec.describe 'Handlebars compile cost per distinct user after a restart (issue #1362 Stage 2 Phase 0)',
               type: :request do
  include ModelSupport
  include MasterSupport
  include DynamicModelSupport

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @admin, = create_admin
    @user_one, = create_user
    @app_type = @user_one.app_type
    create_master(@user_one)
    @user_two, = create_user(app_type: @app_type)
    @user_three, = create_user(app_type: @app_type)

    setup_dm_resource('bm_recs', 'BM Rec')
    create_resource_panel

    # All three users are granted IDENTICAL access, so their rendered master_main_inner
    # source - and therefore its content-addressed compiled filename - is byte-identical.
    [@user_one, @user_two, @user_three].each do |u|
      setup_access :dynamic_model__bm_recs, user: u
    end

    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name: panel_name).each do |pl|
      pl.disable!(@admin)
    end
    Rails.application.routes_reloader.reload!
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  def panel_name
    'bm-panel'
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
      panel_label: 'BM Panel',
      panel_position: 200,
      options: <<~YAML
        contains:
          resources:
            - dynamic_model__bm_recs
      YAML
    )
  end

  # Simulates a full server restart: wipes all compiled generations and rotates
  # server_cache_version, exactly as HandlebarsPrecompiler.startup_cleanup! does on boot.
  def simulate_restart!
    HandlebarsPrecompiler.cleanup_compiled_output
    HandlebarsPrecompiler.cleanup_tmp_dir
    Rails.cache.delete('server_cache_version')
  end

  # Clears the outer per-user page-fragment cache without rotating server_cache_version,
  # so every request below genuinely re-executes the view (see the equivalent helper in
  # handlebars_cross_user_artifact_sharing_spec.rb).
  def bust_page_fragment_cache!
    scv = Rails.cache.read('server_cache_version')
    Rails.cache.clear
    Rails.cache.write('server_cache_version', scv) if scv
  end

  # Signs in as +user+, requests the app template page, and returns the number of
  # Utilities::ProcessPipes.pipe_in_out calls made while serving that single request.
  def pipe_in_out_calls_for(user)
    sign_out(:user) if @signed_in
    bust_page_fragment_cache!
    sign_in user
    @signed_in = true

    call_count = 0
    allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_wrap_original do |original, *args|
      call_count += 1
      original.call(*args)
    end

    get '/pages/test/template'
    expect(response).to have_http_status(:ok)

    call_count
  end

  it 'reports the node-CLI compile cost for the 1st, 2nd and 3rd distinct user after a restart' do
    simulate_restart!

    first = pipe_in_out_calls_for(@user_one)
    second = pipe_in_out_calls_for(@user_two)
    third = pipe_in_out_calls_for(@user_three)

    message = "issue #1362 Stage 2 Phase 0 benchmark: user 1 pipe_in_out calls=#{first}, " \
              "user 2=#{second}, user 3=#{third}"
    Rails.logger.warn message
    warn message

    # The first user after a restart must compile - this is the expected, unavoidable cost.
    expect(first).to be > 0
    # The gate: users 2 and 3 share the same content-addressed compiled file as user 1,
    # so they must never invoke the node CLI at all.
    expect(second).to eq(0)
    expect(third).to eq(0)
  end
end
