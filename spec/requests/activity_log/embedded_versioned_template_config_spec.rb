# frozen_string_literal: true

# Request specs for issue #1238 — activity log embedded dynamic models fail to
# render in show (read-only) mode when the embedded dynamic model uses
# "definition versioning: version at record creation".
#
# User-facing symptom: after saving an activity log embedded form, the
# read-only (show) form does not appear, and the browser console logs:
#   fpa_state_item: could not find template_config dynamic_model__... v123
# Editing the activity correctly shows the edit form, but on save/cancel the
# read-only form is missing.
#
# Root cause exercised here: the activity log `template_config` endpoint builds
# the Handlebars template-config <script> blocks for the embedded dynamic model
# (see app/views/common_templates/_search_results_template.html.erb). For a
# dynamic model, that partial aliases the per-version template object under the
# model's alternative resource names (the plural `resource_name`, the pluralized
# name, and the short name). It aliased only the BASE object, not the specific
# `.v<def_version>` key. When the base object already exists from the initial
# page load (the current version), an older version's template — loaded on demand
# via this endpoint — was never linked onto the plural resource name. The browser
# data item looks up `template_config.<resource_name>.v<version>`, finds nothing,
# and logs `could not find template_config dynamic_model__... v123`, so the
# read-only (show) form never renders. Unversioned models always use the current
# version, which is already loaded, so they were unaffected.
#
# These tests assert that the activity log template_config response aliases the
# embedded dynamic model's per-version template onto its plural resource name,
# for both a versioned and an unversioned embedded dynamic model, including when
# the embedded record was created under an older definition version.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'ActivityLog embedded dynamic model template_config', type: :request do
  include MasterSupport
  include ModelSupport
  include ActivityLogSupport
  include PlayerContactSupport
  include DynamicModelSupport

  AlNameEmbedTplCfg = 'Embed Template Config 1238'

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
    @prev_disable_vdef = Settings::DisableVDef
    # Ensure definition versioning is active so the versioned dynamic model
    # genuinely relies on the on-demand template_config endpoint.
    change_setting('DisableVDef', false)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before(:each) do
    @admin = create_admin.first
    @user = create_user.first
    @master = create_master(@user)

    @al_table = 'activity_log_player_contact_test_embeds'
    @al_fk = "#{@al_table.singularize}_id"

    setup_embed_target_models
    setup_activity_log_with_embed

    setup_access :player_contacts, user: @user
    @player_contact = @master.player_contacts.create!(
      current_user: @user, data: '(516)262-1291', rec_type: 'phone', rank: 10
    )
  end

  # Build the two embed-target dynamic models, both with the FK column required
  # for a direct embed:
  #   - test_embed_versioned_recs    — uses definition-at-record-creation
  #                                    versioning (default; no use_current_version)
  #   - test_embed_unversioned_recs  — uses current version via
  #                                    _configurations.use_current_version: true
  def setup_embed_target_models
    %w[test_embed_versioned_recs test_embed_unversioned_recs].each do |tn|
      unless Admin::MigrationGenerator.table_exists? tn
        TableGenerators.dynamic_models_table(tn, :create_do, 'test1', 'test2', @al_fk)
      end
    end

    DynamicModel.active
                .where(table_name: %w[test_embed_versioned_recs test_embed_unversioned_recs])
                .each { |dm| dm.disable!(@admin) }

    # Remove any stale Ruby implementation class constants from a previous test's run.
    # With use_transactional_fixtures the DB rolls back between tests but in-memory Ruby
    # constants persist. If the old class is still defined, prevent_regenerate_model will
    # return it and skip regeneration for the new DM record, leaving the new DM's
    # definition_id disconnected from the class (issue manifests as def_version = nil).
    %w[test_embed_versioned_recs test_embed_unversioned_recs].each do |tn|
      class_name = tn.singularize.ns_camelize
      [DynamicModel, Object].each do |ns|
        ns.send(:remove_const, class_name) if ns.const_defined?(class_name, false)
      rescue NameError
        nil
      end
    end

    DynamicModel.create!(current_admin: @admin, name: 'test embed versioned recs',
                         table_name: 'test_embed_versioned_recs',
                         schema_name: 'dynamic_test', category: :test)
                .update_tracker_events

    unversioned_opts = <<~YAML
      _configurations:
        use_current_version: true

      default:
        label: Unversioned embed
    YAML
    DynamicModel.create!(current_admin: @admin, name: 'test embed unversioned recs',
                         table_name: 'test_embed_unversioned_recs',
                         schema_name: 'dynamic_test', category: :test,
                         options: unversioned_opts)
                .update_tracker_events

    let_user_create :dynamic_model__test_embed_versioned_recs
    let_user_create :dynamic_model__test_embed_unversioned_recs
  end

  # Configure ActivityLog::PlayerContactTestEmbed with two extra_log_types, each
  # directly embedding one of the dynamic models above.
  def setup_activity_log_with_embed
    SetupHelper.setup_al_gen_tests AlNameEmbedTplCfg, 'test_embed', 'player_contact'

    al = ActivityLog.active.where(name: AlNameEmbedTplCfg).first
    raise "Activity Log #{AlNameEmbedTplCfg} not set up" if al.nil?

    al.extra_log_types = <<~END_DEF
      test_activity_versioned:
        label: Versioned activity
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__test_embed_versioned_recs

      test_activity_unversioned:
        label: Unversioned activity
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__test_embed_unversioned_recs
    END_DEF

    al.current_admin = @admin
    al.save!

    @activity_log = al
    @implementation_class = al.implementation_class

    setup_access :activity_log__player_contact_test_embeds, user: @user
    al.option_configs.each do |c|
      setup_access c.resource_name, resource_type: :activity_log_type, user: @user
    end
  end

  # Create an activity log record for the given extra_log_type and populate its
  # directly embedded dynamic model with values, mirroring the user saving the
  # embedded form.
  def create_activity_with_embed(extra_log_type)
    al = @player_contact.activity_log__player_contact_test_embeds.build(
      select_call_direction: 'to player',
      select_who: 'user',
      extra_log_type:
    )
    al.master = @master
    al.current_user = @user
    al.save!

    embed = al.create_embedded_item({ test1: 'embedded one', test2: 'embedded two' })
    expect(embed).not_to be_nil
    expect(embed.id).not_to be_nil

    al.reload
    al
  end

  def login_user(user = nil)
    user ||= @user
    sign_out :user
    user.confirmed_at ||= Time.now
    user.current_admin ||= @admin
    user.save
    get '/users/sign_in'
    expect(response.status).to eq 200
    sign_in user
  end

  def template_config_path(al)
    "/masters/#{@master.id}/#{@implementation_class.definition.base_route_segments}/#{al.id}/template_config"
  end

  before(:each) do
    login_user
  end

  # The plural resource_name is the key the browser data item uses to look up its
  # template_config (e.g. `template_config.dynamic_model__test_embed_versioned_recs`).
  # The per-version template MUST be aliased onto that name keyed by the record's
  # def_version, otherwise show mode fails for that version (issue #1238).
  def embedded_def_version(al)
    al = @implementation_class.find(al.id)
    al.current_user = @user
    al.embedded_item&.def_version
  end

  describe 'versioned embedded dynamic model' do
    it 'includes the embedded model template config in the template_config response' do
      al = create_activity_with_embed('test_activity_versioned')

      get template_config_path(al)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('template_config.dynamic_model__test_embed_versioned_recs')
    end

    context 'when the embedded record was created under an older definition version' do
      it 'aliases the record\'s older version of the embedded template onto the plural resource name' do
        al = create_activity_with_embed('test_activity_versioned')

        # Create newer definition versions of the embedded dynamic model until the
        # record above resolves to a concrete, older (non-current) definition
        # version. This is the scenario that triggers issue #1238: the record's
        # template must be fetched on demand for that older version. Dynamic
        # migrations are disabled during each bump to avoid a table-comment
        # migration competing for a lock with the just-created record; version
        # history is recorded independently of migrations.
        record_version = nil
        5.times do
          sleep 2
          dm = DynamicModel.active.find_by(table_name: 'test_embed_versioned_recs')
          change_setting('AllowDynamicMigrations', false)
          dm.current_admin = @admin
          dm.options = "default:\n  label: Versioned embed v#{SecureRandom.hex(2)}\n"
          dm.save!
          change_setting('AllowDynamicMigrations', true)
          DynamicModel.define_models
          Application.refresh_dynamic_defs

          record_version = embedded_def_version(al)
          break if record_version.present?
        end

        expect(record_version)
          .to be_present, 'expected the embedded record to resolve to a concrete older definition version'

        get template_config_path(al)
        expect(response).to have_http_status(:ok)

        # The per-version template for the record's older version must be aliased
        # onto the plural resource_name the browser data item looks up. Without the
        # fix only the base object is aliased, so this version key is missing and
        # the show-mode form fails to render (issue #1238).
        expect(response.body)
          .to match(/template_config\.dynamic_model__test_embed_versioned_recs\.v#{record_version}\s*=/),
              "expected plural resource alias for version v#{record_version} to be present"
      end
    end
  end

  describe 'unversioned embedded dynamic model' do
    it 'includes the embedded model template config in the template_config response' do
      al = create_activity_with_embed('test_activity_unversioned')

      get template_config_path(al)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('template_config.dynamic_model__test_embed_unversioned_recs')
    end
  end
end
