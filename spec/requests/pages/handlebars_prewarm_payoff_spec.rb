# frozen_string_literal: true

# The Stage 2 payoff spec (issue #1362) - proves prewarming actually delivers what it's
# for: a real user's FIRST-EVER request after a restart hits zero node-CLI compile calls,
# because Prewarm::MasterTemplates already compiled and content-addressed the artifacts
# their render needs before they ever signed in - not just that later users share what an
# earlier real user already compiled (that's Stage 1, covered by
# handlebars_cross_user_artifact_sharing_spec.rb).
#
# Paired with a negative example proving the same request DOES invoke the node CLI when
# nothing has warmed the generation first, so a regression that silently breaks warming
# (e.g. a variant key mismatch) would show up as this spec failing, not as ambiguous
# doubt about whether the assertion is even meaningful.

require 'rails_helper'

RSpec.describe 'Handlebars prewarm payoff (issue #1362 Stage 2)', type: :request do
  include ModelSupport
  include MasterSupport
  include DynamicModelSupport

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @admin, = create_admin
    @warm_user, = create_user
    @app_type = @warm_user.app_type
    create_master(@warm_user)
    @real_user, = create_user(app_type: @app_type)

    setup_dm_resource('pp_recs', 'PP Rec')
    create_resource_panel

    [@warm_user, @real_user].each { |u| setup_access :dynamic_model__pp_recs, user: u }

    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name:).each { |pl| pl.disable!(@admin) }
    Rails.application.routes_reloader.reload!
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  def panel_name
    'pp-panel'
  end

  def setup_dm_resource(table_name, label)
    class_name = table_name.singularize.camelize.to_sym
    DynamicModel.active.where(table_name:).reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    DynamicModel.create!(
      current_admin: @admin, name: label, schema_name: 'dynamic_test', table_name:,
      category: :details, field_list: 'description', primary_key_name: 'id', foreign_key_name: 'master_id'
    )
  end

  def create_resource_panel
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name:).each { |pl| pl.disable!(@admin) }
    Admin::PageLayout.create!(
      current_admin: @admin, app_type_id: @app_type.id, layout_name: 'master', panel_name:,
      panel_label: 'PP Panel', panel_position: 200,
      options: "contains:\n  resources:\n    - dynamic_model__pp_recs\n"
    )
  end

  def simulate_restart!
    HandlebarsPrecompiler.cleanup_compiled_output
    HandlebarsPrecompiler.cleanup_tmp_dir
    Rails.cache.delete('server_cache_version')
  end

  def bust_page_fragment_cache!
    scv = Rails.cache.read('server_cache_version')
    Rails.cache.clear
    Rails.cache.write('server_cache_version', scv) if scv
  end

  def pipe_in_out_calls_for(user)
    bust_page_fragment_cache!
    sign_in user
    call_count = 0
    allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_wrap_original do |original, *args|
      call_count += 1
      original.call(*args)
    end

    get '/pages/test/template'
    expect(response).to have_http_status(:ok)
    sign_out(:user)

    call_count
  end

  it "invokes the node CLI on a real user's first request when nothing prewarmed the generation" do
    simulate_restart!

    expect(pipe_in_out_calls_for(@real_user)).to be > 0
  end

  it "never invokes the node CLI on a real user's first request once Prewarm::MasterTemplates has warmed it" do
    simulate_restart!

    warmed = Prewarm::MasterTemplates.render_for(@warm_user, @app_type)
    expect(warmed).to be_present

    expect(pipe_in_out_calls_for(@real_user)).to eq(0)
  end
end
