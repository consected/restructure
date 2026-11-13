# frozen_string_literal: true

# MasterTemplates::SkeletonSignature specs (issue #1481, refactor R4).
#
# The signature fingerprints everything baked into the cached master template skeleton
# (and used as the prewarm warm-marker version). A fresh instance is built for each
# reading, since a signature is memoized per instance.
#
# Inputs that MUST move the signature:
# - active definition identity (add, rename, disable, enable), category, dynamic model position
# - activity log item_type / rec_type
# - activity log values rendered into the skeleton: main_log_name, blank_log_name, hide_item_list_panel,
#   action_when_attribute, the tab_caption configuration, and for each option type the button label
#   (button_label or label of non primary / blank log types), e_sign presence, alt_width_classes and
#   hide_unless_creatable. These change the signature once for activity logs compared with earlier builds.
# - option type structure: option type names, references, embed, reference_* caption_before
# - the default option type alt_width_classes (dynamic models and external identifiers only)
# - master page layout panels, app configurations (page-layout / app-config history token)
# - role and user access control timestamps, including global (app_type nil) rows
#
# Inputs that must NOT move the signature (they are delivered lazily as template_config):
# - config-only option edits (label, non-reference caption_before, show_if, field_options), including
#   the label, header_caption and caption_before of activity log primary and blank log types
# - the process-local Resources::Models registry
#
# #cache_key adds the user scope (user or admin, paired user and app type) to the signature.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe MasterTemplates::SkeletonSignature, type: :model do
  include ModelSupport
  include DynamicModelSupport

  let(:table_name) { 'skeleton_signature_recs' }

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  before do
    @admin, = create_admin
    @user, = create_user
    allow(Application).to receive(:server_cache_version).and_return('stable-skeleton-test-version')
  end

  after do
    @dm.reload.disable!(@admin) if @dm&.persisted? && !@dm.reload.disabled?
    @layout.reload.disable!(@admin) if @layout&.persisted? && !@layout.reload.disabled?
  end

  def skeleton_signature
    Application.refresh_dynamic_defs
    described_class.new.signature(app_type_id: @user.app_type_id)
  end

  def skeleton_cache_key(user_or_admin = @user, paired_user = @user)
    described_class.new.cache_key(user_or_admin:, paired_user:)
  end

  def create_dynamic_model(options)
    unless Admin::MigrationGenerator.table_exists?(table_name)
      TableGenerators.dynamic_models_table(table_name, :create_do, 'test1', 'test2')
    end
    DynamicModel.active.where(table_name:).reload.each { |old| old.disable!(@admin) }
    class_name = table_name.singularize.ns_camelize
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: "Skeleton signature #{SecureRandom.hex(4)}",
      table_name:,
      schema_name: 'dynamic_test',
      category: :test,
      options:
    )
    @dm.current_admin = @admin
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :"dynamic_model__#{table_name}", user: @user
    DynamicModel.reset_active_model_configurations!
    @dm
  end

  def save_options_without_migration(definition, options)
    change_setting('AllowDynamicMigrations', false)
    definition.reload
    definition.current_admin = @admin
    definition.options = options
    definition.save!
  ensure
    change_setting('AllowDynamicMigrations', true)
  end

  def basic_options(caption)
    <<~YAML
      _configurations:
        use_current_version: true

      default:
        fields: [test1, test2]
        caption_before:
          test1: #{caption}
    YAML
  end

  describe '#signature' do
    it 'changes with page-layout and app-configuration content' do
      initial_signature = skeleton_signature
      layout = @layout = Admin::PageLayout.create!(
        current_admin: @admin,
        app_type_id: @user.app_type_id,
        layout_name: 'master',
        panel_name: "skeleton-signature-#{SecureRandom.hex(4)}",
        panel_label: 'Initial panel',
        panel_position: 301,
        options: "contains:\n  resources:\n    - player_contacts\n"
      )
      layout_signature = skeleton_signature
      expect(layout_signature).not_to eq(initial_signature)

      layout.update!(panel_label: 'Changed panel', current_admin: @admin)
      expect(skeleton_signature).not_to eq(layout_signature)

      configuration = Admin::AppConfiguration.create!(
        current_admin: @admin,
        app_type_id: @user.app_type_id,
        user_id: @user.id,
        name: 'notes field format',
        value: 'initial'
      )
      configuration_signature = skeleton_signature
      expect(configuration_signature).not_to eq(layout_signature)

      configuration.update!(value: 'changed', current_admin: @admin)
      expect(skeleton_signature).not_to eq(configuration_signature)
    end

    it 'includes global role and access-control updates' do
      initial_signature = skeleton_signature
      allow_any_instance_of(Admin::UserAccessControl).to receive(:clear_rails_cache_on_save?).and_return(false)
      allow_any_instance_of(Admin::UserRole).to receive(:clear_rails_cache_on_save?).and_return(false)

      latest_access = Admin::UserAccessControl.where(app_type_id: [@user.app_type_id, nil]).maximum(:updated_at)
      Admin::UserAccessControl.create!(
        app_type: nil,
        resource_type: :general,
        resource_name: :app_type,
        access: :read,
        user: @user,
        current_admin: @admin,
        created_at: latest_access + 3.seconds,
        updated_at: latest_access + 3.seconds
      )
      access_signature = skeleton_signature
      expect(access_signature).not_to eq(initial_signature)

      updated_at = Admin::UserRole.where(app_type_id: [@user.app_type_id, nil]).maximum(:updated_at) + 3.seconds
      Admin::UserRole.create!(
        current_admin: @admin,
        app_type: nil,
        role_name: "skeleton-global-role-#{SecureRandom.hex(3)}",
        user: @user,
        created_at: updated_at,
        updated_at:
      )
      expect(skeleton_signature).not_to eq(access_signature)
    end

    it 'does not depend on the process-local model registry' do
      initial_signature = skeleton_signature
      original_resources = Resources::Models.resources.dup
      Resources::Models.resources[:process_local_only] = Resources::Models::Item.new.merge(
        type: :dynamic_model,
        class_name: 'ProcessLocalOnly',
        resource_name: :process_local_only
      )

      expect(skeleton_signature).to eq(initial_signature)
    ensure
      Resources::Models.resources.replace(original_resources) if original_resources
    end

    it 'tracks active definition identity changes without including option edits' do
      signature_before_add = skeleton_signature
      definition = create_dynamic_model(basic_options('SignatureOne'))
      signature_after_add = skeleton_signature
      expect(signature_after_add).not_to eq(signature_before_add)

      change_setting('AllowDynamicMigrations', false)
      begin
        definition.current_admin = @admin
        definition.options = basic_options('SignatureTwo')
        definition.save!
        expect(skeleton_signature).to eq(signature_after_add)

        definition.name = "Renamed template #{SecureRandom.hex(3)}"
        definition.save!
      ensure
        change_setting('AllowDynamicMigrations', true)
      end
      signature_after_rename = skeleton_signature
      expect(signature_after_rename).not_to eq(signature_after_add)

      definition.disable!(@admin)
      signature_after_disable = skeleton_signature
      expect(signature_after_disable).not_to eq(signature_after_rename)

      definition.reload.enable!(@admin)
      expect(skeleton_signature).not_to eq(signature_after_disable)
    end

    it 'ignores config-only option edits' do
      definition = create_dynamic_model(basic_options('StructureOne'))
      original_signature = skeleton_signature
      original_key = skeleton_cache_key

      save_options_without_migration(definition, <<~YAML)
        _configurations:
          use_current_version: true

        default:
          fields: [test1]
          label: Changed label
          caption_before:
            test1: StructureTwo
          show_if: {}
          field_options:
            test1:
              disabled: true
      YAML

      expect(skeleton_signature).to eq(original_signature)
      expect(skeleton_cache_key).to eq(original_key)
    end

    it 'tracks option type, reference and embed structure' do
      definition = create_dynamic_model(basic_options('StructureOne'))
      original_signature = skeleton_signature

      save_options_without_migration(definition, <<~YAML)
        _configurations:
          use_current_version: true

        default:
          fields: [test1, test2]
          caption_before:
            test1: StructureTwo
        secondary:
          fields: [test2]
      YAML
      option_type_signature = skeleton_signature
      expect(option_type_signature).not_to eq(original_signature)

      save_options_without_migration(definition, <<~YAML)
        _configurations:
          use_current_version: true

        default:
          fields: [test1, test2]
          references:
            player_contacts:
              from: this
              add: one_to_this
        secondary:
          fields: [test2]
      YAML
      references_signature = skeleton_signature
      expect(references_signature).not_to eq(option_type_signature)

      save_options_without_migration(definition, <<~YAML)
        _configurations:
          use_current_version: true

        default:
          fields: [test1, test2]
          embed: player_contact
          references:
            player_contacts:
              from: this
              add: one_to_this
        secondary:
          fields: [test2]
      YAML
      expect(skeleton_signature).not_to eq(references_signature)
    end

    it 'tracks dynamic model position, alt_width_classes and reference captions baked into the skeleton' do
      options_with = lambda do |view_options: '', reference_caption: 'RefOne', label: 'Label'|
        <<~YAML
          _configurations:
            use_current_version: true

          default:
            fields: [test1, test2]
            label: #{label}
            #{view_options}
            caption_before:
              test1: TemplateConfigOnly #{label}
              reference_player_contacts: #{reference_caption}
            references:
              player_contacts:
                from: this
                add: one_to_this
        YAML
      end
      definition = create_dynamic_model(options_with.call)
      original_signature = skeleton_signature
      original_key = skeleton_cache_key

      # A purely lazily delivered edit (label and non-reference caption) must not move the skeleton
      save_options_without_migration(definition, options_with.call(label: 'Changed label'))
      expect(skeleton_signature).to eq(original_signature)
      expect(skeleton_cache_key).to eq(original_key)

      definition.reload.update_columns(position: definition.position.to_i + 7)
      position_signature = skeleton_signature
      expect(position_signature).not_to eq(original_signature)
      expect(skeleton_cache_key).not_to eq(original_key)

      alt_width_options = "view_options:\n    alt_width_classes: col-md-8"
      save_options_without_migration(
        definition, options_with.call(label: 'Changed label', view_options: alt_width_options)
      )
      alt_width_signature = skeleton_signature
      expect(alt_width_signature).not_to eq(position_signature)

      save_options_without_migration(
        definition,
        options_with.call(label: 'Changed label', reference_caption: 'RefTwo', view_options: alt_width_options)
      )
      expect(skeleton_signature).not_to eq(alt_width_signature)
    end

    it 'tracks dynamic-definition category changes' do
      definition = create_dynamic_model(basic_options('CategoryOne'))
      original_signature = skeleton_signature

      definition.update_columns(category: 'structural-category-change')

      expect(skeleton_signature).not_to eq(original_signature)
    end

    it 'tracks activity-log item and record types' do
      activity_log = ActivityLog.active.first!
      original_rec_type = activity_log.rec_type
      original_signature = skeleton_signature

      activity_log.update_columns(rec_type: "structural-#{SecureRandom.hex(4)}")

      expect(skeleton_signature).not_to eq(original_signature)
    ensure
      activity_log&.update_columns(rec_type: original_rec_type) if original_rec_type
    end

    it 'tracks the activity log definition values baked into the skeleton' do
      activity_log = ActivityLog.active.first!
      original_values = activity_log.attributes.slice(
        'main_log_name', 'blank_log_name', 'hide_item_list_panel', 'action_when_attribute'
      )
      original_signature = skeleton_signature

      signatures = [original_signature]
      {
        main_log_name: "Main #{SecureRandom.hex(3)}",
        blank_log_name: "Blank #{SecureRandom.hex(3)}",
        hide_item_list_panel: !original_values['hide_item_list_panel'],
        action_when_attribute: 'updated_at'
      }.each do |column, value|
        activity_log.update_columns(column => value)
        signatures << skeleton_signature
      end

      expect(signatures.uniq.length).to eq(signatures.length)
    ensure
      activity_log&.update_columns(original_values) if original_values
    end

    it 'memoizes the signature per instance and app type' do
      instance = described_class.new
      first = instance.signature(app_type_id: @user.app_type_id)
      allow(Application).to receive(:server_cache_version).and_return('changed-after-memoization')

      expect(instance.signature(app_type_id: @user.app_type_id)).to eq(first)
      expect(described_class.new.signature(app_type_id: @user.app_type_id)).not_to eq(first)
    end
  end

  describe '#definition_structure' do
    def structure_for(definition, view_options, name: nil, configurations: nil, **option_attributes)
      name ||= definition.default_option_type_name.to_s.underscore.to_sym
      option_config = double(
        name:, references: nil, embed: nil, caption_before: {}, view_options:, label: nil, button_label: nil,
        e_sign: nil, **option_attributes
      )
      allow(definition.class).to receive(:definition_cache).and_return({})
      allow(definition).to receive(:option_configs).and_return([option_config])
      allow(definition).to receive(:configurations).and_return(configurations) if configurations
      described_class.new.definition_structure(definition)
    end

    it 'includes the default option type alt_width_classes for external identifiers only' do
      external_identifier = ExternalIdentifier.active.first!
      activity_log = ActivityLog.active.first!

      expect(structure_for(external_identifier, { alt_width_classes: 'col-md-9' }).last)
        .to eq(['alt_width_classes', 'col-md-9'])
      expect(structure_for(activity_log, { alt_width_classes: 'col-md-9' }).last)
        .to eq(['alt_width_classes', nil])
    end

    describe 'for activity logs' do
      let(:activity_log) { ActivityLog.active.first! }
      let!(:base_structure) { structure_for(activity_log, {}, name: :secondary) }

      it 'tracks the option type settings baked into the activity log skeleton' do
        changed_structures = {
          alt_width_classes: structure_for(activity_log, { alt_width_classes: 'col-md-9' }, name: :secondary),
          hide_unless_creatable: structure_for(activity_log, { hide_unless_creatable: true }, name: :secondary),
          e_sign: structure_for(activity_log, {}, name: :secondary, e_sign: { document_reference: {} }),
          button_label: structure_for(activity_log, {}, name: :secondary, button_label: 'Do it'),
          label_used_for_the_button: structure_for(activity_log, {}, name: :secondary, label: 'Labelled')
        }

        changed_structures.each do |setting, structure|
          expect(structure).not_to eq(base_structure), "expected #{setting} to change the structure"
        end
        expect(changed_structures.values.uniq.length).to eq(changed_structures.length)
      end

      it 'tracks the primary and blank log hide_unless_creatable button setting' do
        %i[primary blank_log].each do |name|
          expect(structure_for(activity_log, { hide_unless_creatable: true }, name:))
            .not_to eq(structure_for(activity_log, {}, name:))
        end
      end

      it 'tracks the tab caption rendered into the skeleton' do
        captioned = structure_for(activity_log, {}, name: :secondary, configurations: { tab_caption: 'Caption one' })

        expect(captioned).not_to eq(base_structure)
        expect(structure_for(activity_log, {}, name: :secondary, configurations: { tab_caption: 'Caption two' }))
          .not_to eq(captioned)
      end

      it 'ignores values delivered lazily as template_config' do
        lazy_values = structure_for(
          activity_log, { header_caption: 'Lazy', extra_class: 'lazy' }, name: :secondary,
                                                                           caption_before: { test1: 'Lazy caption' }
        )
        expect(lazy_values).to eq(base_structure)

        primary_label = structure_for(activity_log, {}, name: :primary, label: 'Primary label')
        expect(primary_label).to eq(structure_for(activity_log, {}, name: :primary))
      end
    end

    it 'reuses a definition structure digest until its live template token changes' do
      definition = create_dynamic_model(basic_options('StructureCache'))
      instance = described_class.new
      token = definition.current_def_version
      allow(definition).to receive(:option_configs).and_call_original
      allow(definition).to receive(:template_version_token) { token }

      first_structure = instance.definition_structure(definition)
      expect(instance.definition_structure(definition)).to eq(first_structure)
      expect(definition).to have_received(:option_configs).once

      token += 1
      expect(instance.definition_structure(definition)).to eq(first_structure)
      expect(definition).to have_received(:template_version_token).exactly(3).times
      expect(definition).to have_received(:option_configs).twice
    end
  end

  describe '#cache_key' do
    it 'scopes the signature by user, admin and paired user' do
      user_key = skeleton_cache_key(@user, @user)

      expect(user_key).to match(/\A[a-f0-9]{64}\z/)
      expect(skeleton_cache_key(@admin, @user)).not_to eq(user_key)
      expect(skeleton_cache_key(nil, nil)).to match(/\A[a-f0-9]{64}\z/)
    end
  end
end
