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
# Records at the CURRENT definition version are unaffected (their config is still
# emitted globally with `def_version = nil`).
#
# These specs assert the DETERMINISTIC signal: the global page template emits
# config blocks ONLY for current definition versions (id attribute ending in `--v`
# with NO digit). No historical version block (id ending in `--v<number>`) should
# be present for any definition whose table name matches the test fixtures. This
# count is completely independent of wall-clock timing and remains robust under
# any server load.
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
    unless Admin::MigrationGenerator.table_exists?(EI_NAME)
      TableGenerators.external_identifiers_table(EI_NAME, true, EI_ATTR)
    end
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
  def create_dm
    unless Admin::MigrationGenerator.table_exists?(DM_TABLE)
      TableGenerators.dynamic_models_table(DM_TABLE, :create_do, 'test1', 'test2')
    end
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: DM_TABLE.tr('_', ' '),
      table_name: DM_TABLE,
      schema_name: 'dynamic_test',
      category: :test
    )
    dm.current_admin = @admin
    dm.update_tracker_events
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :"dynamic_model__#{DM_TABLE}", user: @user
    dm
  end

  # Bump a DM's definition version, creating a new history row.
  # AllowDynamicMigrations is briefly disabled during the save to avoid a
  # competing table-comment migration lock (the history trigger still fires).
  def bump_dm_version(dm_def, label_suffix)
    sleep 2
    change_setting('AllowDynamicMigrations', false)
    dm = DynamicModel.active.find(dm_def.id)
    dm.current_admin = @admin
    dm.options = "default:\n  label: Test DM v#{label_suffix}\n  fields:\n    - test1\n    - test2\n"
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
    HandlebarsPrecompiler.cleanup_public_dir

    # Clear all_versions memoization so changed definitions are re-read from DB.
    DynamicModel.all_versions_memo      = {}
    ActivityLog.all_versions_memo       = {}
    ExternalIdentifier.all_versions_memo = {}

    # Reset the active_model_configurations cache so newly created or updated
    # definitions (and their UAC associations) are included in the rendered output.
    DynamicModel.reset_active_model_configurations!
    ActivityLog.reset_active_model_configurations!
    ExternalIdentifier.reset_active_model_configurations!

    get '/pages/test/template'
    expect(response).to have_http_status(:ok)
    response.body
  end

  # Count how many HISTORICAL (versioned) config blocks the template emits for
  # definitions whose config-block id contains the given name_fragment. Historical
  # blocks have a numeric def_version appended to their `id` attribute:
  #   id="fpa_state_config--<resource_name>--v<number>"
  # The current-version block uses a nil def_version, rendered as `--v` (no digit)
  # and is NOT counted by this helper.
  #
  # name_fragment should be a substring of the resource name as it appears in the
  # id (e.g. 'dynamic_model__test_global_tpl_hist_dm_recs' or a unique prefix).
  def historical_config_block_count(name_fragment, text)
    # Match the id attribute pattern with a numeric version suffix.
    text.scan(/fpa_state_config--#{Regexp.escape(name_fragment)}[^"]*--v\d+/).size
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

      # Sanity check: the CURRENT version (def_version=nil, rendered as '--v' with no digit)
      # must be present, confirming the DM IS included in active_model_configurations and
      # the global template is actually rendering it.
      expect(text).to include("fpa_state_config--#{dm_resource_prefix}"),
                      "expected a current-version config block for #{dm_resource_prefix} to be " \
                      'present in the global page template but it was not. ' \
                      'The test DM may not be associated with the active app type.'

      actual = historical_config_block_count(dm_resource_prefix, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{dm_resource_prefix} " \
                        "(any option type) in the global page template, but found #{actual}. " \
                        'The all_versions loop must be removed from ' \
                        'app/views/dynamic_models/_search_results_template.html.erb.'
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
      expect(text).to include("fpa_state_config--#{dm_resource_prefix}"),
                      "expected a current-version config block for #{dm_resource_prefix} (use_current_version) " \
                      'to be present in the global page template.'

      actual = historical_config_block_count(dm_resource_prefix, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{dm_resource_prefix} " \
                        "(use_current_version: true) in the global page template, but found #{actual}."
    end
  end

  describe 'activity log global template' do
    # rubocop:disable Lint/ConstantDefinitionInBlock
    N_AL_BUMPS = 3
    # rubocop:enable Lint/ConstantDefinitionInBlock

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

      login_user
      text = page_template_text

      # The javascript_tag id for an AL config block uses the full resource name
      # with option type suffix. Match any option type suffix of this AL:
      # fpa_state_config--activity_log__player_contact_test_global_hist[__<type>]--v<n>
      al_base_name = 'activity_log__player_contact_test_global_hist'

      # Sanity check: the CURRENT version config block must be present.
      expect(text).to include("fpa_state_config--#{al_base_name}"),
                      "expected a current-version config block for #{al_base_name} (any extra_log_type) " \
                      'to be present in the global page template but it was not.'

      actual = historical_config_block_count(al_base_name, text)
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

      # Sanity check: the CURRENT version config block must be present.
      expect(text).to include("fpa_state_config--#{ei_resource_prefix}"),
                      "expected a current-version config block for #{ei_resource_prefix} (any option type) " \
                      'to be present in the global page template but it was not.'

      actual = historical_config_block_count(ei_resource_prefix, text)
      expect(actual).to eq(0),
                        "expected 0 historical version config blocks for #{ei_resource_prefix} " \
                        "(any option type) in the global page template, but found #{actual}. " \
                        'The all_versions loop must be removed from ' \
                        'app/views/external_identifiers/_search_results_template.html.erb.'
    end
  end
end
