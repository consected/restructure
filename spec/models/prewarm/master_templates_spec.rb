# frozen_string_literal: true

# Prewarm::MasterTemplates unit tests (issue #1362 Stage 2, Phase 1).
#
# Verifies the offline render harness: renders the master template partial for a real
# user via ActionController::Renderer (no HTTP request, no signed-in session), producing
# the same content-addressed compiled Handlebars artifacts a real login would - and that
# it does so WITHOUT ever persisting the app_type_id it assigns in memory to drive the
# render for a specific app type.

require 'rails_helper'

RSpec.describe Prewarm::MasterTemplates do
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

    setup_dm_resource('pw_recs', 'PW Rec')
    create_resource_panel
    setup_access :dynamic_model__pw_recs, user: @user

    Rails.application.routes_reloader.reload!
    HandlebarsPrecompiler.cleanup_compiled_output
    HandlebarsPrecompiler.cleanup_tmp_dir
  end

  after(:all) do
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name:).each { |pl| pl.disable!(@admin) }
    Rails.application.routes_reloader.reload!
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  def panel_name
    'pw-panel'
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
      panel_label: 'PW Panel', panel_position: 200,
      options: "contains:\n  resources:\n    - dynamic_model__pw_recs\n"
    )
  end

  it 'renders without a signed-in user or raising Devise::MissingWarden' do
    expect { described_class.render_for(@user, @app_type) }.not_to raise_error
  end

  it 'produces a compiled master_main_inner partial file on disk' do
    described_class.render_for(@user, @app_type)

    files = Dir.glob(HandlebarsPrecompiler.partials_compiled_dir.join('master_main_inner-*.js'))
    expect(files).not_to be_empty
  end

  it 'never persists the app_type_id it assigns in memory to drive the render' do
    other_app_type = Admin::AppType.active.where.not(id: @app_type.id).first
    skip 'requires a second active app type' unless other_app_type

    original_app_type_id = @user.app_type_id
    described_class.render_for(@user, other_app_type)

    expect(@user.reload.app_type_id).to eq(original_app_type_id)
  end

  it 'rescues a render failure for one combination without raising' do
    broken_app_type = Admin::AppType.new(id: -1)

    expect { described_class.render_for(@user, broken_app_type) }.not_to raise_error
  end
end
