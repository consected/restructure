# frozen_string_literal: true

# Request specs for issue #1238 (follow-up hardening) — the master page template
# endpoint (/pages/:id/template) must load reliably, and must honour the rule
# that a dynamic model set to use the current definition version ALWAYS resolves
# its config libraries at the current version too.
#
# Two contrasting behaviours of config-library + definition versioning are
# verified here (see OptionConfigs::ExtraOptions.prepare_options_text):
#
#   * use_current_version: true
#       - The definition always resolves against the CURRENT config library.
#       - Historical definition versions are therefore never referenced and must
#         not be emitted into the page template. Emitting them would re-parse the
#         old YAML against the current (changed) library — if the old version
#         referenced a library anchor that the current library no longer defines,
#         that parse raises and previously broke the whole page render.
#
#   * versioned (default; version-at-record-creation)
#       - Historical definition versions resolve their libraries at the version's
#         own point in time, so an anchor removed from the current library still
#         resolves for old versions. These versions are emitted (issue #1238) so
#         records created under them can still find their template config.
#
# Scenario reproduced for use_current_version:
#   1. Config library defines anchor &label_v1.
#   2. A use_current_version dynamic model references *label_v1.
#   3. The config library is updated DIRECTLY in the database (bypassing the
#      model's valid_options validation, as earlier app versions allowed),
#      renaming the anchor to &label_v2. The history triggers still record the
#      change as a new library version.
#   4. The dynamic model's current version is updated to reference *label_v2
#      (valid against the current library). Its OLD version still references the
#      now-undefined *label_v1.
#   5. Loading the page template must succeed: the current version resolves
#      against the current library, and the broken historical version is skipped.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'Pages template config library version resolution', type: :request do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
    @prev_disable_vdef = Settings::DisableVDef
    # Definition versioning must be active for historical versions to exist.
    change_setting('DisableVDef', false)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before(:each) do
    @admin, = create_admin
    @user, = create_user
    @master = create_master(@user)

    @lib_category = "tpl_res_cat_#{rand(1_000_000_000)}"
    @lib_name = "tpl_res_lib_#{rand(1_000_000_000)}"
  end

  # Create the config library defining the v1 anchor.
  def create_library_v1
    Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: @lib_name,
      category: @lib_category,
      format: 'yaml',
      options: <<~YAML
        _defaults_lib:
          label_v1: &label_v1 Label from library v1
      YAML
    )
  end

  # Rename the anchor in the config library while BYPASSING the model's
  # valid_options validation (which would otherwise reject renaming an anchor
  # still referenced by a dynamic model). Versioning is still handled by the
  # config_library_history database trigger, so a new history row is recorded for
  # this change. This reproduces the real-world situation where an earlier version
  # of the app allowed a config library anchor to be renamed without validating it
  # against the definitions referencing it.
  def rename_library_anchor_in_db(lib)
    sleep 2
    new_options = "_defaults_lib:\n  label_v2: &label_v2 Label from library v2\n"
    lib = Admin::ConfigLibrary.find(lib.id)
    # update_columns bypasses valid_options (which would reject renaming an anchor
    # still referenced by a dynamic model) and the after_commit refresh callbacks,
    # while still firing the config_library_history DB trigger. updated_at is set
    # explicitly from the Ruby clock (Postgres now() would return the surrounding
    # test transaction's start time, predating the library's creation and breaking
    # the chronological history ordering).
    lib.update_columns(options: new_options, updated_at: Time.now)
    # Clear the memoized version list so point-in-time lookups see the new history.
    Admin::ConfigLibrary.all_versions_memo = {}
    lib
  end

  def remove_stale_class(table_name)
    class_name = table_name.singularize.ns_camelize
    [DynamicModel, Object].each do |ns|
      ns.send(:remove_const, class_name) if ns.const_defined?(class_name, false)
    rescue NameError
      nil
    end
  end

  def ensure_table(table_name)
    return if Admin::MigrationGenerator.table_exists?(table_name)

    TableGenerators.dynamic_models_table(table_name, :create_do, 'test1', 'test2')
  end

  # Build the dynamic model options text referencing the given library anchor,
  # optionally configured to use the current definition version.
  def dm_options(anchor:, use_current_version:)
    ucv = use_current_version ? "_configurations:\n  use_current_version: true\n" : ''
    "# @library #{@lib_category} #{@lib_name}\n#{ucv}default:\n  label: *#{anchor}\n  fields:\n    - test1\n    - test2\n"
  end

  # Create a dynamic model that references the given library anchor.
  def create_dm(table_name, anchor:, use_current_version:)
    ensure_table(table_name)
    DynamicModel.active.where(table_name:).each { |dm| dm.disable!(@admin) }
    remove_stale_class(table_name)

    dm = DynamicModel.create!(
      current_admin: @admin,
      name: table_name.tr('_', ' '),
      table_name:,
      schema_name: 'dynamic_test',
      category: :test,
      options: dm_options(anchor:, use_current_version:)
    )
    dm.current_admin = @admin
    dm.update_tracker_events
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access "dynamic_model__#{table_name}".to_sym, user: @user
    dm
  end

  # Update the dynamic model's current version to reference a different anchor
  # and/or version mode, leaving the previous version in history.
  def update_dm_anchor(dm, anchor:, use_current_version:)
    sleep 2
    change_setting('AllowDynamicMigrations', false)
    dm = DynamicModel.active.find(dm.id)
    dm.current_admin = @admin
    dm.options = dm_options(anchor:, use_current_version:)
    dm.save!
    change_setting('AllowDynamicMigrations', true)
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    dm
  end

  # Create a record under the given dynamic model's current definition.
  def create_record(table_name)
    @master.current_user = @user
    @master.send("dynamic_model__#{table_name}").create!(current_user: @user, test1: 'a value')
  end

  # Re-find a previously created record through the (possibly redefined) current
  # implementation class, so its version resolution reflects the latest definition.
  def reload_record(table_name, id)
    rec = DynamicModel.active.find_by(table_name:).implementation_class.find(id)
    rec.current_user = @user
    rec
  end

  # The most recent non-current historical version of a definition, if any.
  def older_version(dm)
    current = dm.all_versions.first&.def_version
    dm.all_versions.find { |v| v.def_version && v.def_version != current }
  end

  def login_user
    sign_out :user
    @user.confirmed_at ||= Time.now
    @user.current_admin ||= @admin
    @user.save
    get '/users/sign_in'
    expect(response.status).to eq 200
    sign_in @user
  end

  # Request the master page template, returning the combined effective template
  # text (response body plus the contents of every referenced precompiled
  # "multi" file). The precompiled output is content-addressed and persists on
  # disk between runs, so the public dir is cleared first to force a fresh render.
  # A broken historical version that slips through would surface here as a
  # rendered "Error loading search results template item" string.
  #
  # Render-time log output is captured into @render_log so tests can assert that a
  # broken historical version was never even processed (its parse failure is
  # otherwise swallowed by option_configs and only logged, so it would not appear
  # in the response body).
  def page_template_text
    HandlebarsPrecompiler.cleanup_public_dir

    log_io = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(log_io)
    begin
      get '/pages/test/template'
    ensure
      Rails.logger = previous_logger
    end
    @render_log = log_io.string
    expect(response).to have_http_status(:ok)

    text = +response.body
    response.body.scan(%r{/handlebars-test/multi/([\w.\-]+\.js)}).flatten.uniq.each do |fn|
      path = HandlebarsPrecompiler::MULTI_PUBLIC_DIR.join(fn)
      text << "\n" << File.read(path) if File.exist?(path)
    end
    text
  end

  before(:each) do
    login_user
  end

  describe 'a use_current_version dynamic model' do
    it 'resolves every record against the current library and loads the page despite a broken old version' do
      table_name = 'tpl_res_ucv_recs'
      lib = create_library_v1

      # Record created while the definition (use_current_version) references the v1 anchor.
      dm = create_dm(table_name, anchor: 'label_v1', use_current_version: true)
      record = create_record(table_name)

      # Rename the anchor directly in the DB (bypassing validation). Only the v2
      # anchor now exists in the current library.
      rename_library_anchor_in_db(lib)

      # Current version references the valid v2 anchor; the previous version still
      # references the now-undefined v1 anchor.
      update_dm_anchor(dm, anchor: 'label_v2', use_current_version: true)
      dm = DynamicModel.active.find(dm.id)

      # The OLD version of a use_current_version definition resolves the CURRENT
      # library (version_at = nil), so its now-undefined *label_v1 reference makes
      # it unparseable. This is exactly why the page template must skip it.
      old = older_version(dm)
      expect(old).to be_present
      expect { old.option_configs(raise_bad_configs: true) }
        .to raise_error(StandardError),
            'expected the broken old use_current_version version to be unparseable against the current library'

      # The record — created under the old (v1) definition — now resolves to the
      # CURRENT definition and CURRENT library, proving use_current_version always
      # uses the current version.
      record = reload_record(table_name, record.id)
      expect(record.def_version).to be_nil
      expect(OptionConfigs::ExtraOptions.prepare_options_text(record.versioned_definition))
        .to include('Label from library v2')

      # The page template loads and does not surface the broken old version.
      text = page_template_text
      expect(text).not_to include('Error loading search results template item for dynamic model')
      # The broken historical version must never be processed during render: for a
      # use_current_version definition every record resolves to the current version,
      # so the old version (which references the removed *label_v1 anchor) is skipped
      # entirely rather than parsed and logged as a failure.
      expect(@render_log).not_to include('An alias referenced an unknown anchor: label_v1')
    end
  end

  describe 'a versioned (non use_current_version) dynamic model' do
    it 'resolves an older record against the library at its point in time' do
      table_name = 'tpl_res_ver_recs'
      lib = create_library_v1

      dm = create_dm(table_name, anchor: 'label_v1', use_current_version: false)
      # Record created under the original (v1) definition and v1 library.
      old_record = create_record(table_name)

      # Bump the definition (still referencing the v1 anchor while v1 is defined).
      update_dm_anchor(dm, anchor: 'label_v1', use_current_version: false)

      # Rename the library anchor directly in the DB; the previous library version
      # (with the v1 anchor) is retained by the history trigger.
      rename_library_anchor_in_db(lib)
      update_dm_anchor(dm, anchor: 'label_v2', use_current_version: false)

      # The older record resolves to its historical definition version, which
      # resolves the library at that version's point in time (v1).
      old_record = reload_record(table_name, old_record.id)
      expect(old_record.def_version).to be_present
      expect(OptionConfigs::ExtraOptions.prepare_options_text(old_record.versioned_definition))
        .to include('Label from library v1')

      # A new record resolves the current definition and current library (v2).
      new_record = reload_record(table_name, create_record(table_name).id)
      expect(new_record.def_version).to be_nil
      expect(OptionConfigs::ExtraOptions.prepare_options_text(new_record.versioned_definition))
        .to include('Label from library v2')

      # The page template loads cleanly.
      text = page_template_text
      expect(text).not_to include('Error loading search results template item for dynamic model')
    end
  end

  describe 'a dynamic model switched from versioned to use_current_version' do
    it 'resolves a record created while versioned against the current library once switched' do
      table_name = 'tpl_res_switch_recs'
      lib = create_library_v1

      # Initially VERSIONED, referencing the v1 anchor.
      dm = create_dm(table_name, anchor: 'label_v1', use_current_version: false)
      # Record created while the definition was versioned and the library was v1.
      record = create_record(table_name)

      # Bump the versioned definition (still v1) to add a genuine older version to
      # the history.
      update_dm_anchor(dm, anchor: 'label_v1', use_current_version: false)

      # Rename the library anchor directly in the DB.
      rename_library_anchor_in_db(lib)

      # Switch the definition to use_current_version, referencing the v2 anchor.
      update_dm_anchor(dm, anchor: 'label_v2', use_current_version: true)
      dm = DynamicModel.active.find(dm.id)
      expect(dm.definition_uses_current_version_option?).to be true

      # The record was created while the definition was versioned (and would, under
      # versioned resolution, resolve the v1 library). Because the current
      # definition now uses use_current_version, the record resolves to the CURRENT
      # definition and CURRENT library (v2) instead.
      record = reload_record(table_name, record.id)
      expect(record.def_version).to be_nil
      expect(OptionConfigs::ExtraOptions.prepare_options_text(record.versioned_definition))
        .to include('Label from library v2')

      # The page template loads cleanly: historical versions are skipped for a
      # use_current_version definition.
      text = page_template_text
      expect(text).not_to include('Error loading search results template item for dynamic model')
    end
  end
end
