# frozen_string_literal: true

# Request specs for issue #1238 performance follow-up — the global master page
# template (pages#template, served at /pages/:id/template) must NOT emit
# version-keyed template-config <script> blocks for historical (non-current)
# definition versions of dynamic models, activity logs, or external identifiers.
#
# Background:
# PR #1242 fixed issue #1238 by adding `all_versions` loops to the three global
# template partials so that records created under an older definition version
# could still resolve their `.v<def_version>` template-config key at page-load
# time. However this introduces a performance regression: on every page load the
# global template parses the full option-config YAML for every historical version
# of every definition. With many definitions and long histories this causes
# noticeably slow page loads.
#
# The fix is to remove the `all_versions` loops from the global partials and rely
# instead on the on-demand per-record `template_config` endpoint, which already:
#   - emits the `.v<def_version>` config block and the DM plural-resource aliasing
#     for exactly the versions referenced by records currently being rendered;
#   - gates rendering via a promise (`_fpa.prepare_template_configs`) so the
#     versioned config is guaranteed present before Handlebars renders the item.
# The CURRENT definition's template state is keyed by its latest history-row ID,
# while the live definition's `def_version` metadata remains nil.
#
# These specs assert the DETERMINISTIC signal: the global page template emits
# These specs assert the DETERMINISTIC signal: the global page template emits
# config blocks for current definition versions, aliases that state under `v0`,
# and does not emit historical version blocks. This count is independent of
# wall-clock timing and remains robust under any server load.
# Form responses promote v0 for current-definition New and Edit forms only when no newer v0 is
# installed, and never for historical records. Secondary option-type forms must not replace
# the base list aliases.
# Skeleton renders promote shared base aliases from the generated or configured
# default option type, while each activity-log option type promotes its own alias.
#
# Companion system spec:
#   spec/system/activity_log/embedded_versioned_show_mode_spec.rb
# verifies that the on-demand path fully substitutes for the removed global loops
# from the end-user perspective.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'
require './db/table_generators/external_identifiers_table'

RSpec.describe 'Global page template historical version emission', type: :request do
  include MasterSupport
  include ModelSupport
  include ActivityLogSupport
  include PlayerContactSupport
  include DynamicModelSupport
  include ExternalIdentifierSupport

  # -------------------------------------------------------------------
  # Table / definition names used exclusively by this spec file.
  # Using fixed names (rather than random) keeps log output readable and
  # avoids cluttering the test DB with ever-growing sets of tables.
  # The `before(:each)` block disables any stale same-name definitions so
  # each test starts from a clean slate.
  # -------------------------------------------------------------------
  # rubocop:disable Lint/ConstantDefinitionInBlock
  DM_TABLE  = 'test_global_tpl_hist_dm_recs'
  AL_NAME   = 'Test Global Tpl Hist Al'
  EI_NAME   = 'test_global_tpl_hist_eids'
  EI_ATTR   = 'test_global_tpl_hist_id'
  # rubocop:enable Lint/ConstantDefinitionInBlock

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    @prev_disable_vdef = Settings::DisableVDef
    # Allow automatic table creation for new definitions.
    change_setting('AllowDynamicMigrations', true)
    # Ensure definition versioning is active so historical versions are recorded.
    change_setting('DisableVDef', false)

    # Create EI table once (it cannot be created inside a transaction that rolls back).
    TableGenerators.external_identifiers_table(EI_NAME, true, EI_ATTR, skip_if_exists: true)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before(:each) do
    @admin = create_admin.first
    @user  = create_user.first
    @master = create_master(@user)

    # Disable any stale definitions left from a previous run of this spec.
    # Stale Ruby constants from previous transactional fixture rollbacks are
    # also removed here so define_models regenerates a fresh class.
    remove_stale_dm_class(DM_TABLE)
    DynamicModel.active.where(table_name: DM_TABLE).each { |dm| dm.disable!(@admin) }

    # Reset EI stale class.
    remove_stale_ei_class(EI_NAME)
    ExternalIdentifier.active.where(name: EI_NAME).each { |ei| ei.disable!(@admin) }
  end

  # -----------------------------------------------------------------------
  # Helpers
  def dm_options_with_secondary_option_type(option_type_names: %w[default secondary], default_option_type_name: nil)
    configurations = +<<~YAML
      _configurations:
        option_type_attr_name: test2
    YAML
    if default_option_type_name
      configurations << <<~YAML

        _configurations_extras:
          default_option_type_name: #{default_option_type_name}
      YAML
    end

    option_type_configs = option_type_names.map do |option_type_name|
      <<~YAML
        #{option_type_name}:
          button_label: #{option_type_name.titleize} Add
          fields:
            - test1
            - test2
      YAML
    end.join

    "#{configurations}#{option_type_configs}"
  end

  def expect_skeleton_base_v0_promotions(text, base_name, option_type_names, promoted_option_type)
    promoted_name = "#{base_name}_#{promoted_option_type}"
    expected_promotions = [
      "set_v0(_fpa.state.template_config.#{base_name}, " \
      "_fpa.state.template_config.#{promoted_name}.v0);",
      "set_v0(_fpa.show_if.forms.#{base_name}, " \
      "_fpa.show_if.forms['#{promoted_name}'].v0);"
    ]
    base_promotions = text.lines.map(&:strip).grep(
      /\Aset_v0\(_fpa\.(?:state\.template_config|show_if\.forms)\.#{Regexp.escape(base_name)},/
    )

    expect(base_promotions).to contain_exactly(*expected_promotions)
    option_type_names.each do |option_type_name|
      option_name = "#{base_name}_#{option_type_name}"
      expect(text).to include(
        "set_v0(_fpa.state.template_config.#{option_name}, " \
        "_fpa.state.template_config.#{option_name}.v"
      )
      expect(text).to include(
        "set_v0(_fpa.show_if.forms['#{option_name}'], " \
        "_fpa.show_if.forms['#{option_name}'].v"
      )
    end
  end

  # -----------------------------------------------------------------------

  def remove_stale_dm_class(table_name)
    class_name = table_name.singularize.ns_camelize
    [DynamicModel, Object].each do |ns|
      ns.send(:remove_const, class_name) if ns.const_defined?(class_name, false)
    rescue NameError
      nil
    end
  end

  def remove_stale_ei_class(name)
    class_name = name.singularize.ns_camelize
    [ExternalIdentifier, Object].each do |ns|
      ns.send(:remove_const, class_name) if ns.const_defined?(class_name, false)
    rescue NameError
      nil
    end
  end

  # Create a DM definition with default (versioned) options.
  def create_dm(options: nil)
    unless Admin::MigrationGenerator.table_exists?(DM_TABLE)
      TableGenerators.dynamic_models_table(DM_TABLE, :create_do, 'test1', 'test2')
    end
    attributes = {
      current_admin: @admin,
      name: DM_TABLE.tr('_', ' '),
      table_name: DM_TABLE,
      schema_name: 'dynamic_test',
      category: :test
    }
    attributes[:options] = options if options
    dm = DynamicModel.create!(**attributes)
    dm.current_admin = @admin
    dm.update_tracker_events
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :"dynamic_model__#{DM_TABLE}", app_type: @user.app_type
    dm
  end

  # Bump a DM's definition version, creating a new history row.
  # AllowDynamicMigrations is briefly disabled during the save to avoid a
  # competing table-comment migration lock (the history trigger still fires).
  def bump_dm_version(dm_def, label_suffix, fields: %w[test1 test2])
    sleep 2
    change_setting('AllowDynamicMigrations', false)
    dm = DynamicModel.active.find(dm_def.id)
    dm.current_admin = @admin
    field_lines = fields.map { |field_name| "    - #{field_name}" }.join("\n")
    dm.options = "default:\n  label: Test DM v#{label_suffix}\n  fields:\n#{field_lines}\n"
    dm.save!
    change_setting('AllowDynamicMigrations', true)
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    dm
  end

  # Create an EI definition.
  def create_ei
    ExternalIdentifier.create!(
      current_admin: @admin,
      name: EI_NAME,
      label: 'Test Global EI',
      external_id_attribute: EI_ATTR,
      min_id: 1,
      max_id: 99_999_999,
      schema_name: 'dynamic_test',
      category: :test
    ).tap do |ei|
      ei.current_admin = @admin
      ei.update_tracker_events
      ExternalIdentifier.define_models
      Application.refresh_dynamic_defs
      setup_access EI_NAME.to_sym, user: @user
    end
  end

  # Bump an EI definition version.
  def bump_ei_version(ei_def, label_suffix)
    sleep 2
    # Disable migrations briefly to avoid a lock timeout against the outer test
    # transaction (the history trigger still fires and records the version).
    change_setting('AllowDynamicMigrations', false)
    ei = ExternalIdentifier.active.find(ei_def.id)
    ei.current_admin = @admin
    ei.label = "Test Global EI v#{label_suffix}"
    ei.save!
    change_setting('AllowDynamicMigrations', true)
    ExternalIdentifier.define_models
    Application.refresh_dynamic_defs
    ei
  end

  # Log in as the test user via Warden/Devise sign_in helper.
  def login_user
    sign_out :user
    @user.confirmed_at ||= Time.now
    @user.current_admin ||= @admin
    @user.save
    get '/users/sign_in'
    expect(response.status).to eq 200
    sign_in @user
  end

  # Request the global page template and return its text, forcing a fresh render
  # by clearing the precompiled Handlebars cache first (so stale disk files do
  # not mask a change in the emitted config blocks).
  def page_template_text
    HandlebarsPrecompiler.cleanup_compiled_output

    # Clear all_versions memoization so changed definitions are re-read from DB.
    DynamicModel.clear_all_versions_memo
    ActivityLog.clear_all_versions_memo
    ExternalIdentifier.clear_all_versions_memo

    # Reset the active_model_configurations cache so newly created or updated
    # definitions (and their UAC associations) are included in the rendered output.
    DynamicModel.reset_active_model_configurations!
    ActivityLog.reset_active_model_configurations!
    ExternalIdentifier.reset_active_model_configurations!

    get '/pages/test/template'
    expect(response).to have_http_status(:ok)
    response.body
  end

  def requested_handlebars_bundle(text)
    bundle_url = text[/_fpa\.retrieve_requested_handlebars_templates\('([^']+)'/, 1]
    return '' unless bundle_url

    File.read(Rails.root.join('public', bundle_url.delete_prefix('/')))
  end

  # Count how many HISTORICAL (versioned) config blocks the template emits for
  # definitions whose config-block id contains the given name_fragment. Historical
  # blocks have a numeric def_version appended to their `id` attribute:
  #   id="fpa_state_config--<resource_name>--v<number>"
  # The current version is excluded from this count; older history rows are not.
  #
  # name_fragment should be a substring of the resource name as it appears in the
  # id (e.g. 'dynamic_model__test_global_tpl_hist_dm_recs' or a unique prefix).
  def historical_config_block_count(name_fragment, current_version, text)
    versions = text.scan(/fpa_state_config--#{Regexp.escape(name_fragment)}[^"]*--v(\d+)/).flatten
    versions.count { |version| version.to_i != current_version }
  end

  def current_config_block_count(name_fragment, current_version, text, form_state: false)
    form_suffix = form_state ? '(?:--form)?' : ''
    text.scan(/id="fpa_state_config--#{Regexp.escape(name_fragment)}[^"]*--v#{current_version}#{form_suffix}"/).size
  end

  # -----------------------------------------------------------------------
  # Examples
  # -----------------------------------------------------------------------

  describe 'dynamic model global template' do
    # Create a DM definition and bump its version N_BUMPS times so that
    # N_BUMPS historical entries exist in `all_versions`.
    # rubocop:disable Lint/ConstantDefinitionInBlock
    N_DM_BUMPS = 3
    # rubocop:enable Lint/ConstantDefinitionInBlock

    it 'emits NO historical version config blocks for a versioned DM definition' do
      dm = create_dm
      N_DM_BUMPS.times { |i| dm = bump_dm_version(dm, i + 1) }

      dm.reload
      history_count = dm.all_versions.size
      expect(history_count).to be >= N_DM_BUMPS,
                               "expected at least #{N_DM_BUMPS} history rows, got #{history_count}"

      login_user
      text = page_template_text

      # The javascript_tag id for a DM config block uses name_with_option_type:
      # fpa_state_config--dynamic_model__<table_name.singularize>_<option_type>--v<def_version>
      # Use the singular resource name as a prefix so we match any option type suffix.
      dm_resource_prefix = "dynamic_model__#{DM_TABLE.singularize}"

      # Sanity check: the CURRENT version must be present, confirming the DM IS included in active_model_configurations and
      # the global template is actually rendering it.
      expect(current_config_block_count(dm_resource_prefix, dm.current_def_version, text)).to be > 0,
                      "expected a current-version config block for #{dm_resource_prefix} to be " \
                      'present in the global page template but it was not. ' \
                      'The test DM may not be associated with the active app type.'

      actual = historical_config_block_count(dm_resource_prefix, dm.current_def_version, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{dm_resource_prefix} " \
                        "(any option type) in the global page template, but found #{actual}. " \
                        'The all_versions loop must be removed from ' \
                        'app/views/dynamic_models/_search_results_template.html.erb.'
    end

    it 'keeps live Handlebars templates registered when the state config has a version' do
      dm = create_dm
      DynamicModel.reset_active_model_configurations!
      expect(DynamicModel.active_model_configurations.pluck(:table_name)).to include(DM_TABLE)
      login_user

      text = page_template_text

      expect(current_config_block_count("dynamic_model__#{DM_TABLE.singularize}", dm.current_def_version, text))
        .to be > 0
      expect(requested_handlebars_bundle(text)).to include(DM_TABLE.tr('_', '-'))
    end

    it 'writes the current state to v0 and uses v0 for list templates' do
      dm = create_dm
      DynamicModel.reset_active_model_configurations!
      login_user

      text = page_template_text
      state_name = "dynamic_model__#{DM_TABLE.singularize}_default"
      state_reference = "_fpa.state.template_config.#{state_name}"
      show_if_reference = "_fpa.show_if.forms['#{state_name}']"
      bundle = requested_handlebars_bundle(text)

      expect(text).to include(
        "set_v0(#{state_reference}, #{state_reference}.v#{dm.current_def_version});"
      )
      expect(text).to include(
        "set_v0(#{show_if_reference}, #{show_if_reference}.v#{dm.current_def_version});"
      )
      expect(text).not_to match(
        /_fpa\.state\.template_config\.[^\n]*#{Regexp.escape(DM_TABLE.singularize)}[^\n]*\.v0 = [^\n]*\|\|/
      ), 'live DynamicModel aliases must replace their v0 slot when a newer config is loaded'
      expect(bundle).to include(DM_TABLE.tr('_', '-'))
      expect(bundle).to match(/"list_template_config".{0,600}"v0"/)
    end

    it 'promotes skeleton base aliases from default when default is first' do
      option_type_names = %w[default secondary]
      dm = create_dm(options: dm_options_with_secondary_option_type(option_type_names: option_type_names))
      DynamicModel.reset_active_model_configurations!
      login_user

      text = page_template_text
      base_name = "dynamic_model__#{DM_TABLE.singularize}"
      expect_skeleton_base_v0_promotions(text, base_name, option_type_names, 'default')
      expect(dm.option_configs_names).to eq(%i[default secondary])
    end

    it 'promotes skeleton base aliases from default when secondary is first' do
      option_type_names = %w[secondary default]
      dm = create_dm(options: dm_options_with_secondary_option_type(option_type_names: option_type_names))
      DynamicModel.reset_active_model_configurations!
      login_user

      text = page_template_text
      base_name = "dynamic_model__#{DM_TABLE.singularize}"

      expect_skeleton_base_v0_promotions(text, base_name, option_type_names, 'default')
      expect(dm.option_configs_names).to eq(%i[secondary default])
    end

    it 'promotes skeleton base aliases from the generated default when YAML omits default' do
      option_type_names = %w[alpha beta]
      dm = create_dm(options: dm_options_with_secondary_option_type(option_type_names: option_type_names))
      dm.option_configs
      DynamicModel.reset_active_model_configurations!
      login_user

      text = page_template_text
      base_name = "dynamic_model__#{DM_TABLE.singularize}"

      expect_skeleton_base_v0_promotions(text, base_name, option_type_names, 'default')
      expect(dm.option_configs_names.first(option_type_names.length)).to eq(option_type_names.map(&:to_sym))
    end

    it 'promotes skeleton base aliases from the configured default option type' do
      option_type_names = %w[default secondary]
      dm = create_dm(
        options: dm_options_with_secondary_option_type(
          option_type_names: option_type_names,
          default_option_type_name: 'secondary'
        )
      )
      DynamicModel.reset_active_model_configurations!
      login_user

      text = page_template_text
      base_name = "dynamic_model__#{DM_TABLE.singularize}"

      expect_skeleton_base_v0_promotions(text, base_name, option_type_names, 'secondary')
      expect(dm.option_configs_names).to eq(%i[default secondary])
    end

    it 'emits current template state inline in the dynamic-model form response' do
      dm = create_dm
      DynamicModel.reset_active_model_configurations!
      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
      login_user

      path = "/masters/#{@master.id}/dynamic_model/#{DM_TABLE}/new"
      expect(Rails.application.routes.recognize_path(path, method: :get)[:controller]).to eq(
        "dynamic_model/#{DM_TABLE}"
      )
      expect(@user.has_access_to?(:create, :table, dm.resource_name)).to be_truthy
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "fpa_state_config--dynamic_model__#{DM_TABLE.singularize}_default--v#{dm.current_def_version}--form"
      )
      form_state_name = "dynamic_model__#{DM_TABLE.singularize}_default"
      expect(response.body).to include(
        "_fpa.state.template_config.#{form_state_name}.v#{dm.current_def_version}  = {"
      )
      expect(response.body).to include(
        "set_v0(_fpa.state.template_config.#{form_state_name}, " \
        "_fpa.state.template_config.#{form_state_name}.v#{dm.current_def_version});"
      )
      expect(response.body).not_to include('preserve_existing_v0')
    end

    it 'promotes only option-type-specific aliases from a secondary-option new form' do
      dm = create_dm(options: dm_options_with_secondary_option_type)
      DynamicModel.reset_active_model_configurations!
      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
      login_user

      path = "/masters/#{@master.id}/dynamic_model/#{DM_TABLE}/new"
      param_set_name = "dynamic_model_#{DM_TABLE.singularize}"
      get path, params: { param_set_name => { test2: 'secondary' } }

      expect(response).to have_http_status(:ok)
      base_name = "dynamic_model__#{DM_TABLE.singularize}"
      secondary_name = "#{base_name}_secondary"
      expect(response.body).to include(
        "fpa_state_config--#{secondary_name}--v#{dm.current_def_version}--form"
      )
      expect(response.body).to include(
        "set_v0(_fpa.state.template_config.#{secondary_name}, " \
        "_fpa.state.template_config.#{secondary_name}.v#{dm.current_def_version});"
      )

      option_type_promotions = [
        "set_v0(_fpa.state.caption_before.#{secondary_name},",
        "set_v0(_fpa.state.labels_#{secondary_name},",
        "set_v0(_fpa.state.template_config.#{secondary_name},",
        "set_v0(_fpa.show_if.forms['#{secondary_name}'],"
      ]
      option_type_promotions.each { |promotion| expect(response.body).to include(promotion) }
      promoted_base_aliases = response.body.lines.grep(/set_v0\(/).reject do |line|
        option_type_promotions.any? { |promotion| line.include?(promotion) }
      end
      expect(promoted_base_aliases).to be_empty
    end

    it 'keeps historical edit-form state in its version slot while live records use the current slot' do
      initial_options = "default:\n  label: Test DM v1\n  fields:\n    - test1\n    - test2\n"
      dm = create_dm(options: initial_options)
      old_record = @master.dynamic_model__test_global_tpl_hist_dm_recs.create!(
        current_user: @user,
        test1: 'historical value'
      )
      old_token = old_record.vdef_version

      dm = bump_dm_version(dm, 'v2', fields: ['test1'])
      current_token = "v#{dm.current_def_version}"
      state_name = "dynamic_model__#{DM_TABLE.singularize}_default"
      edit_path = lambda do |record|
        "/masters/#{@master.id}/dynamic_model/#{DM_TABLE}/#{record.id}/edit"
      end
      DynamicModel.reset_active_model_configurations!
      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
      expect(Rails.application.routes.recognize_path(edit_path.call(old_record), method: :get)[:controller])
        .to eq("dynamic_model/#{DM_TABLE}")
      live_record = @master.dynamic_model__test_global_tpl_hist_dm_recs.create!(
        current_user: @user,
        test1: 'live value'
      )
      setup_access :"dynamic_model__#{DM_TABLE}", access: :update, user: @user, app_type: @user.app_type
      login_user

      get edit_path.call(old_record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("fpa_state_config--#{state_name}--#{old_token}--form")
      expect(response.body).to include("def_version: #{old_token.delete_prefix('v')}")
      expect(response.body).to include("item_list: 'test1,test2'")
      expect(response.body).not_to include("fpa_state_config--#{state_name}--#{current_token}--form")
      expect(response.body).not_to include('set_v0(')

      get edit_path.call(live_record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("fpa_state_config--#{state_name}--#{current_token}--form")
      expect(response.body).to include('def_version: null')
      expect(response.body).to include("item_list: 'test1'")
      expect(response.body).to include(
        "_fpa.state.template_config.#{state_name}.v#{current_token.delete_prefix('v')}  = {"
      )
      # A live record's edit form promotes the current token to v0, unless a newer v0 is installed
      expect(response.body).to include(
        "set_v0(_fpa.state.template_config.#{state_name}, " \
        "_fpa.state.template_config.#{state_name}.#{current_token});"
      )
      expect(response.body).to include(
        "installed_v0_token(_fpa.state.template_config.#{state_name}) <= #{current_token.delete_prefix('v')}"
      )
    end

    it 'promotes only option-type-specific aliases from a secondary-option edit form' do
      dm = create_dm(options: dm_options_with_secondary_option_type)
      DynamicModel.reset_active_model_configurations!
      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
      record = @master.dynamic_model__test_global_tpl_hist_dm_recs.create!(
        current_user: @user,
        test1: 'secondary record',
        test2: 'secondary'
      )
      setup_access :"dynamic_model__#{DM_TABLE}", access: :update, user: @user, app_type: @user.app_type
      login_user

      get "/masters/#{@master.id}/dynamic_model/#{DM_TABLE}/#{record.id}/edit"

      expect(response).to have_http_status(:ok)
      secondary_name = "dynamic_model__#{DM_TABLE.singularize}_secondary"
      option_type_promotions = [
        "set_v0(_fpa.state.caption_before.#{secondary_name},",
        "set_v0(_fpa.state.labels_#{secondary_name},",
        "set_v0(_fpa.state.template_config.#{secondary_name},",
        "set_v0(_fpa.show_if.forms['#{secondary_name}'],"
      ]
      option_type_promotions.each { |promotion| expect(response.body).to include(promotion) }
      promoted_base_aliases = response.body.lines.grep(/set_v0\(/).reject do |line|
        option_type_promotions.any? { |promotion| line.include?(promotion) }
      end
      expect(promoted_base_aliases).to be_empty
      expect(dm.current_def_version).to be_present
    end

    it 'promotes the base aliases from an edit form of the default option type' do
      dm = create_dm(options: dm_options_with_secondary_option_type)
      DynamicModel.reset_active_model_configurations!
      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
      record = @master.dynamic_model__test_global_tpl_hist_dm_recs.create!(
        current_user: @user,
        test1: 'default record',
        test2: 'default'
      )
      setup_access :"dynamic_model__#{DM_TABLE}", access: :update, user: @user, app_type: @user.app_type
      login_user

      get "/masters/#{@master.id}/dynamic_model/#{DM_TABLE}/#{record.id}/edit"

      expect(response).to have_http_status(:ok)
      base_name = "dynamic_model__#{DM_TABLE.singularize}"
      expect(response.body).to include(
        "set_v0(_fpa.state.template_config.#{base_name}, _fpa.state.template_config.#{base_name}_default.v0);"
      )
      expect(dm.current_def_version).to be_present
    end

    # A use_current_version: true DM always resolves records to the current
    # definition. Historical version configs must never be emitted for it:
    #   - They are not needed (records never reference an older version).
    #   - They could reference config-library anchors removed in a later library
    #     update, breaking the entire page render (issue #1238 original cause).
    # Previously this was guarded by `unless m.definition_uses_current_version_option?`.
    # With the loop removed entirely the guard is no longer needed, but we test
    # explicitly to catch any regression that re-introduces historical emission
    # for use_current_version definitions.
    it 'emits NO historical version config blocks for a use_current_version: true DM definition' do
      ucv_options = "default:\n  label: UCVTest\n  fields:\n    - test1\n    - test2\n" \
                    "_configurations:\n  use_current_version: true\n"

      unless Admin::MigrationGenerator.table_exists?(DM_TABLE)
        TableGenerators.dynamic_models_table(DM_TABLE, :create_do, 'test1', 'test2')
      end
      remove_stale_dm_class(DM_TABLE)
      DynamicModel.active.where(table_name: DM_TABLE).each { |dm| dm.disable!(@admin) }

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: DM_TABLE.tr('_', ' '),
        table_name: DM_TABLE,
        schema_name: 'dynamic_test',
        category: :test,
        options: ucv_options
      )
      dm.current_admin = @admin
      dm.update_tracker_events
      DynamicModel.define_models
      Application.refresh_dynamic_defs
      setup_access :"dynamic_model__#{DM_TABLE}", user: @user

      N_DM_BUMPS.times do |i|
        sleep 2
        change_setting('AllowDynamicMigrations', false)
        dm = DynamicModel.active.find(dm.id)
        dm.current_admin = @admin
        dm.options = ucv_options.sub('UCVTest', "UCVTest v#{i + 1}")
        dm.save!
        change_setting('AllowDynamicMigrations', true)
        DynamicModel.define_models
        Application.refresh_dynamic_defs
      end

      dm.reload
      history_count = dm.all_versions.size
      expect(history_count).to be >= N_DM_BUMPS,
                               "expected at least #{N_DM_BUMPS} history rows, got #{history_count}"

      login_user
      text = page_template_text

      dm_resource_prefix = "dynamic_model__#{DM_TABLE.singularize}"

      # Current version must be present.
      expect(current_config_block_count(dm_resource_prefix, dm.current_def_version, text)).to be > 0,
                      "expected a current-version config block for #{dm_resource_prefix} (use_current_version) " \
                      'to be present in the global page template.'

      actual = historical_config_block_count(dm_resource_prefix, dm.current_def_version, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{dm_resource_prefix} " \
                        "(use_current_version: true) in the global page template, but found #{actual}."
    end
  end

  describe 'activity log global template' do
    # rubocop:disable Lint/ConstantDefinitionInBlock
    N_AL_BUMPS = 3
    # rubocop:enable Lint/ConstantDefinitionInBlock

    it 'promotes each mapped option alias in skeleton and state-only forms' do
      SetupHelper.setup_al_gen_tests AL_NAME, 'test_global_hist', 'player_contact'
      al = ActivityLog.active.find_by!(name: AL_NAME)
      option_type_names = %w[alpha beta]
      al.extra_log_types = <<~YAML
        alpha:
          label: Alpha
          fields:
            - select_call_direction
            - select_who
        beta:
          label: Beta
          fields:
            - select_call_direction
            - select_who
      YAML
      al.current_admin = @admin
      al.save!
      ActivityLog.define_models
      Application.refresh_dynamic_defs

      setup_access :activity_log__player_contact_test_global_hists, user: @user
      al.option_configs.each do |option_config|
        setup_access option_config.resource_name, resource_type: :activity_log_type, user: @user
      end

      login_user
      skeleton = page_template_text

      option_type_names.each do |option_type_name|
        option_config = al.option_type_config_for(option_type_name)
        state_name = "#{al.full_item_type_name}_#{option_type_name}".underscore
        promotion = "set_v0(_fpa.state.template_config.#{option_config.resource_name}, " \
                    "_fpa.state.template_config.#{state_name}.v0);"
        expect(skeleton).to include(promotion)

        get "/masters/#{@master.id}/#{al.base_route_segments}/new", params: { extra_type: option_type_name }

        expect(response).to have_http_status(:ok)
        form_script_id = "fpa_state_config--#{state_name}--v#{al.current_def_version}--form"
        form_script = response.body[/<script[^>]*id="#{Regexp.escape(form_script_id)}"[^>]*>.*?<\/script>/m]
        expect(form_script).to be_present
        expect(form_script).to include(promotion)
      end
    end

    it 'emits NO historical version config blocks for a versioned AL definition' do
      SetupHelper.setup_al_gen_tests AL_NAME, 'test_global_hist', 'player_contact'
      al = ActivityLog.active.find_by(name: AL_NAME)
      raise "Activity Log #{AL_NAME} not set up" if al.nil?

      setup_access :activity_log__player_contact_test_global_hists, user: @user

      # Bump the AL definition N_AL_BUMPS times to produce history rows.
      N_AL_BUMPS.times do |i|
        sleep 2
        al = ActivityLog.active.find(al.id)
        al.current_admin = @admin
        al.extra_log_types = <<~YAML
          primary:
            label: Global hist AL v#{i + 1}
            fields:
              - select_call_direction
              - select_who
        YAML
        al.save!
        ActivityLog.define_models
        Application.refresh_dynamic_defs
      end

      al.reload
      history_count = al.all_versions.size
      expect(history_count).to be >= N_AL_BUMPS,
                               "expected at least #{N_AL_BUMPS} history rows, got #{history_count}"
      active_definition = ActivityLog.active_model_configurations.find_by(id: al.id)
      expect(Dynamic::TemplateVersionTokens.resource_token(active_definition)).to eq(al.current_def_version)

      login_user
      text = page_template_text

      # The javascript_tag id for an AL config block uses the full resource name
      # with option type suffix. Match any option type suffix of this AL:
      # fpa_state_config--activity_log__player_contact_test_global_hist[__<type>]--v<n>
      al_base_name = 'activity_log__player_contact_test_global_hist'
      actual_config_blocks = text.scan(/id="fpa_state_config--#{Regexp.escape(al_base_name)}[^"]*"/)

      # Sanity check: the CURRENT version config block must be present.
      expect(current_config_block_count(al_base_name, al.current_def_version, text)).to be > 0,
                      "expected a current-version config block for #{al_base_name} (any extra_log_type) " \
              "to be present in the global page template but it was not. Found: #{actual_config_blocks.join(', ')}"
      expect(text).to match(
        /<script[^>]*id="fpa_state_config--#{Regexp.escape(al_base_name)}_primary--v#{al.current_def_version}"[^>]*>.*?def_version: null/m
      )

      actual = historical_config_block_count(al_base_name, al.current_def_version, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{al_base_name} " \
                        "(any extra_log_type) in the global page template, but found #{actual}. " \
                        'The all_versions loop must be removed from ' \
                        'app/views/activity_logs/_search_results_template.html.erb.'
    end
  end

  describe 'external identifier global template' do
    # rubocop:disable Lint/ConstantDefinitionInBlock
    N_EI_BUMPS = 3
    # rubocop:enable Lint/ConstantDefinitionInBlock

    it 'emits NO historical version config blocks for a versioned EI definition' do
      ei = create_ei
      N_EI_BUMPS.times { |i| ei = bump_ei_version(ei, i + 1) }

      ei.reload
      history_count = ei.all_versions.size
      expect(history_count).to be >= N_EI_BUMPS,
                               "expected at least #{N_EI_BUMPS} history rows, got #{history_count}"

      login_user
      text = page_template_text

      # The javascript_tag id for an EI config block uses name_with_option_type:
      # fpa_state_config--<ei_name.singularize>_<option_type>--v<def_version>
      # Use the singular name as prefix so we match any option type suffix.
      ei_resource_prefix = EI_NAME.singularize

      # Sanity check: the CURRENT version config block must be present with its history ID.
      expect(current_config_block_count(ei_resource_prefix, ei.current_def_version, text, form_state: true)).to be > 0,
                      "expected a current-version config block for #{ei_resource_prefix} (any option type) " \
                      'to be present in the global page template but it was not.'

      actual = historical_config_block_count(ei_resource_prefix, ei.current_def_version, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{ei_resource_prefix} " \
                        "(any option type) in the global page template, but found #{actual}. " \
                        'The all_versions loop must be removed from ' \
                        'app/views/external_identifiers/_search_results_template.html.erb.'
    end
  end
end
