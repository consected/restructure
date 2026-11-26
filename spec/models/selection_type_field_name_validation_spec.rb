# frozen_string_literal: true

# Verifies condition selection prefixes are reported as non-blocking notices for
# configured field names (via all_implementation_fields) and external identifier names.
require 'rails_helper'

RSpec.describe 'Selection type field name validation', type: :model do
  include ModelSupport

  selection_prefixes = %w[all any not_all not_any].freeze

  before :each do
    create_admin
  end

  def dynamic_model_definition(field_list: '', name: 'selection_prefix_test', table_name: 'selection_prefix_test')
    definition = DynamicModel.new(
      current_admin: @admin,
      name:,
      table_name:,
      field_list:,
      category: :test,
      schema_name: 'dynamic_test'
    )
    allow(definition).to receive(:option_configs).and_return([])
    definition
  end

  def activity_log_definition(field_list: '', blank_log_field_list: '', extra_log_types: nil,
                              name: 'selection_prefix_test', table_name: 'activity_log_selection_prefix_tests')
    definition = ActivityLog.new(
      current_admin: @admin,
      name:,
      item_type: 'player_contact',
      table_name:,
      action_when_attribute: 'created_at',
      field_list:,
      blank_log_field_list:,
      extra_log_types:
    )
    allow(definition).to receive(:item_type_exists).and_return(true)
    allow(definition).to receive(:check_item_type_and_rec_type).and_return(true)
    allow(definition).to receive(:option_configs).and_return([]) unless extra_log_types
    definition
  end

  def external_identifier_definition(
    name: 'selection_prefix_test_identifiers',
    external_id_attribute: 'selection_prefix_test_ext_id',
    extra_fields: ''
  )
    definition = ExternalIdentifier.new(
      current_admin: @admin,
      name:,
      label: 'Selection Prefix Test',
      external_id_attribute:,
      extra_fields:,
      min_id: 1,
      max_id: 100
    )
    allow(definition).to receive(:option_configs).and_return([])
    definition
  end

  def admin_config_notices(definition)
    OptionConfigs::ExtraOptions.all_option_configs_notices(definition, levels: %i[errors]) || []
  end

  def admin_config_errors(definition)
    OptionConfigs::ExtraOptions.all_option_configs_errors(definition) || []
  end

  def field_name_error(field_name, prefix)
    "Field name \"#{field_name}\" starts with reserved condition selection prefix \"#{prefix}\". " \
      'It will be interpreted as a condition selection type rather than a field.'
  end

  def external_identifier_name_error(name, prefix)
    "External identifier name \"#{name}\" starts with reserved condition selection prefix \"#{prefix}\". " \
      'It will be interpreted as a condition selection type rather than a field.'
  end

  def expect_non_blocking_notice(definition, message)
    expect(definition.valid?).to be(true), definition.errors.full_messages.join(', ')
    expect(definition.errors).to be_empty
    expect(admin_config_notices(definition).pluck(:message)).to include(message)
    expect(admin_config_errors(definition).pluck(:message)).to include(message)
    expect(OptionConfigs::ExtraOptions.all_option_configs_notices(definition, levels: %i[warnings])).to be_nil
  end

  def save_disabled_definition(definition)
    definition.disabled = true
    allow(definition).to receive(:option_configs).and_return([])
    allow(definition).to receive(:handle_config_triggers)
    allow(definition).to receive(:reset_active_model_configurations!)
    allow(definition).to receive(:other_regenerate_actions)
    allow(definition).to receive(:handle_disabled)
    allow(definition).to receive(:reload_routes_after_definition_change)
    allow(definition).to receive(:setup_data_dictionary) if definition.respond_to?(:setup_data_dictionary)

    expect(definition.save).to be(true), definition.errors.full_messages.join(', ')
  end

  def save_external_identifier(definition)
    allow(definition).to receive(:check_implementation_class).and_return(true)
    allow(definition).to receive(:other_regenerate_actions).and_return(true)
    allow(definition).to receive(:generate_usage_reports)

    expect(definition).to be_valid
    expect(definition.errors).to be_empty
    expect(definition.save).to be true
  end

  describe 'dynamic model field names' do
    selection_prefixes.each do |prefix|
      it "reports #{prefix} field_list names without blocking the definition" do
        field_name = "#{prefix}_field"
        definition = dynamic_model_definition(field_list: field_name)

        expect_non_blocking_notice(definition, field_name_error(field_name, prefix))
      end
    end

    it 'deduplicates a reserved field repeated in field_list' do
      field_name = 'any_repeated_field'
      definition = dynamic_model_definition(field_list: "#{field_name} #{field_name}")

      expect(admin_config_notices(definition).pluck(:message)).to eq [field_name_error(field_name, 'any')]
    end

    it 'still reports field_list notices when options YAML cannot be parsed' do
      field_name = 'all_broken_yaml_field'
      definition = DynamicModel.new(
        current_admin: @admin,
        name: 'broken_yaml_dm',
        table_name: 'broken_yaml_dms',
        field_list: field_name,
        options: "default:\n  label: [unclosed",
        category: :test,
        schema_name: 'dynamic_test'
      )

      expect(admin_config_notices(definition).pluck(:message)).to include(field_name_error(field_name, 'all'))
    end

    it 'does not report ordinary field names that begin with selection text' do
      definition = dynamic_model_definition(field_list: 'allow_this_request anyone allergies not_allowed')

      expect(admin_config_notices(definition)).to be_empty
    end

    it 'reports exact selection names and names followed by non-letters' do
      definition = dynamic_model_definition(field_list: 'all all2 all_x')

      expect(admin_config_notices(definition).pluck(:message)).to contain_exactly(
        field_name_error('all', 'all'),
        field_name_error('all2', 'all'),
        field_name_error('all_x', 'all')
      )
    end
  end

  describe 'activity log field names' do
    selection_prefixes.each do |prefix|
      it "reports #{prefix} field_list names without blocking the definition" do
        field_name = "#{prefix}_activity_field"
        definition = activity_log_definition(field_list: field_name)

        expect_non_blocking_notice(definition, field_name_error(field_name, prefix))
      end

      it "reports #{prefix} blank_log_field_list names without blocking the definition" do
        field_name = "#{prefix}_blank_field"
        definition = activity_log_definition(field_list: 'ordinary_field', blank_log_field_list: field_name)

        expect_non_blocking_notice(definition, field_name_error(field_name, prefix))
      end

      it "reports #{prefix} extra log type fields without blocking the definition" do
        field_name = "#{prefix}_step_field"
        extra_log_types = <<~YAML
          step_1:
            label: Step 1
            fields:
              - #{field_name}
        YAML
        definition = activity_log_definition(field_list: 'ordinary_field', extra_log_types:)

        expect_non_blocking_notice(definition, field_name_error(field_name, prefix))
      end
    end

    it 'still reports field_list notices on disabled activity logs without option_configs' do
      field_name = 'all_disabled_activity_field'
      definition = activity_log_definition(field_list: field_name)
      definition.disabled = true

      expect_non_blocking_notice(definition, field_name_error(field_name, 'all'))
    end

    it 'combines reserved field notices with no_sync_fields notices' do
      field_name = 'any_combined_field'
      extra_log_types = <<~YAML
        _configurations:
          no_sync_fields:
            - nonexistent_parent_field
      YAML
      definition = activity_log_definition(field_list: field_name, extra_log_types:)
      allow(definition).to receive(:implementation_class).and_raise(NameError, 'missing implementation')

      messages = admin_config_notices(definition).pluck(:message)
      expect(messages).to include(field_name_error(field_name, 'any'))
      expect(messages).to include(a_string_including('no_sync_fields could not be validated'))
    end
  end

  describe 'external identifier names and fields' do
    selection_prefixes.each do |prefix|
      it "keeps an external identifier name starting with #{prefix} saveable and reports it" do
        name = "#{prefix}_identifiers"
        definition = external_identifier_definition(name:, external_id_attribute: 'safe_external_id')
        save_external_identifier(definition)

        expect_non_blocking_notice(definition, external_identifier_name_error(name, prefix))
      end

      it "reports #{prefix} external_id_attribute names without blocking the definition" do
        field_name = "#{prefix}_external_id"
        definition = external_identifier_definition(external_id_attribute: field_name)

        expect_non_blocking_notice(definition, field_name_error(field_name, prefix))
      end

      it "reports #{prefix} extra_fields names without blocking the definition" do
        field_name = "#{prefix}_extra_field"
        definition = external_identifier_definition(extra_fields: field_name)

        expect_non_blocking_notice(definition, field_name_error(field_name, prefix))
      end
    end

    it 'does not report ordinary external identifier names or fields that begin with selection text' do
      definition = external_identifier_definition(
        name: 'allow_this_request_records',
        external_id_attribute: 'anyone_id',
        extra_fields: 'allergies not_allowed'
      )
      save_external_identifier(definition)

      expect(admin_config_notices(definition)).to be_empty
      expect(admin_config_errors(definition)).to be_empty
    end

    it 'allows a missing external_id_attribute while checking extra_fields' do
      field_name = 'all_optional_extra_field'
      definition = external_identifier_definition(external_id_attribute: nil, extra_fields: field_name)

      expect { definition.field_list }.not_to raise_error
      message = field_name_error(field_name, 'all')
      expect(admin_config_notices(definition).pluck(:message)).to include(message)
      expect(admin_config_errors(definition).pluck(:message)).to include(message)
    end

    it 'reports notices for already-persisted definitions and allows them to be re-saved' do
      name = 'any_persisted_identifiers'
      definition = external_identifier_definition(name:, external_id_attribute: 'safe_external_id')
      save_external_identifier(definition)

      persisted_definition = definition.reload
      expect_non_blocking_notice(persisted_definition, external_identifier_name_error(name, 'any'))

      persisted_definition.label = 'Updated Selection Prefix Test'
      expect(persisted_definition.save).to be true
      expect_non_blocking_notice(persisted_definition, external_identifier_name_error(name, 'any'))
    end

    it 'continues reporting attribute notices when option configs cannot be parsed' do
      field_name = 'not_all_invalid_options_field'
      definition = external_identifier_definition(external_id_attribute: field_name)
      allow(definition).to receive(:option_configs).and_raise(ArgumentError, 'invalid option config')

      message = field_name_error(field_name, 'not_all')
      expect(admin_config_notices(definition).pluck(:message)).to include(message)
      expect(admin_config_errors(definition).pluck(:message)).to include(message)
    end
  end

  describe 'persisted definitions' do
    it 'continues reporting field notices and allows dynamic models and activity logs to be re-saved' do
      dynamic_model = dynamic_model_definition(
        field_list: 'all_persisted_field',
        name: 'all_persisted_model',
        table_name: 'all_persisted_models'
      )
      save_disabled_definition(dynamic_model)
      dynamic_model.reload
      dynamic_model.current_admin = @admin
      expect_non_blocking_notice(dynamic_model, field_name_error('all_persisted_field', 'all'))
      dynamic_model.description = 'Updated legacy dynamic model'
      expect(dynamic_model.save).to be(true)

      activity_log = activity_log_definition(
        field_list: 'not_any_persisted_field',
        name: 'all_persisted_activity_log'
      )
      save_disabled_definition(activity_log)
      activity_log.reload
      activity_log.current_admin = @admin
      expect_non_blocking_notice(activity_log, field_name_error('not_any_persisted_field', 'not_any'))
      activity_log.main_log_name = 'Updated legacy activity log'
      expect(activity_log.save).to be(true)
    end
  end

  describe 'unaffected names' do
    it 'allows and saves names containing prefix strings away from the beginning with no notices' do
      definition = external_identifier_definition(
        name: 'company_records',
        external_id_attribute: 'company_ext_id',
        extra_fields: 'many_things company_records'
      )
      save_external_identifier(definition)

      expect(admin_config_notices(definition)).to be_empty
      expect(admin_config_errors(definition)).to be_empty
    end

    it 'does not check dynamic model or activity log definition and table names' do
      dynamic_model = dynamic_model_definition(field_list: 'ordinary_field', name: 'all_things', table_name: 'all_things')
      activity_log = activity_log_definition(
        field_list: 'ordinary_field', name: 'all_things', table_name: 'all_things'
      )

      expect(admin_config_notices(dynamic_model)).to be_empty
      expect(admin_config_notices(activity_log)).to be_empty
    end
  end
end
