# frozen_string_literal: true

require 'rails_helper'

# Tests issue #1451: activity-log no_sync_fields configuration must validate
# against inferred parent overlaps and consistently control synchronization,
# permitted parameters, and save-time copying.
RSpec.describe 'Activity log no_sync_fields', type: :model do
  include ModelSupport
  include PlayerContactSupport

  before(:each) do
    ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').where.not(name: 'Phone Log')
               .update_all(disabled: true)
    SetupHelper.setup_al_player_contact_phones

    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create
    let_user_create_player_contacts
    create_item(data: '(516)262-1291', rank: 10)

    @definition = ActivityLog.active.where(name: 'Phone Log').first
    @definition.force_regenerate = true
    @definition.generate_model
    @implementation_class = @definition.implementation_class
  end

  def configure_no_sync_fields(value)
    parsed_options = YAML.safe_load(
      @definition.extra_log_types || '{}',
      permitted_classes: [],
      permitted_symbols: [],
      aliases: true
    ) || {}
    parsed_options['_configurations'] ||= {}
    parsed_options['_configurations']['no_sync_fields'] = value
    @definition.extra_log_types = String.yaml_dump(parsed_options)
    @definition.option_configs(force: true)
    ActivityLog.definition_cache[@definition.id] = @definition
    @implementation_class = @definition.implementation_class
    @implementation_class.fields_to_sync
  end

  describe 'definition configuration' do
    it 'accepts a scalar no_sync_fields value on an activity-log definition for issue #1451' do
      configure_no_sync_fields('data')

      expect(@definition.configurations[:no_sync_fields]).to eq 'data'
      expect(@definition.configurations.config_warnings).to be_empty
    end

    it 'reports a non-overlapping no_sync_fields value as a configuration error for issue #1451' do
      configure_no_sync_fields('not_a_real_parent_field')

      notices = OptionConfigs::ExtraOptions.all_option_configs_errors(@definition)
      messages = notices.map { |error| error[:message] }
      expect(messages).to include(match(/not_a_real_parent_field/))
    end

    it 'does not mutate configuration errors while calculating fields_to_sync' do
      configure_no_sync_fields('not_a_real_parent_field')

      expect(@definition.configurations.config_errors).to be_empty
      expect(@implementation_class.fields_to_sync).to include('data')
      expect(@definition.configurations.config_errors).to be_empty
    end
  end

  describe 'effective synchronization' do
    before do
      configure_no_sync_fields('data')
    end

    it 'removes an opted-out overlapping field from fields_to_sync for issue #1451' do
      expect(@implementation_class.fields_to_sync).not_to include('data')
    end

    it 'keeps another overlapping field in fields_to_sync when only data is opted out for issue #1451' do
      allow(@implementation_class).to receive(:attribute_names).and_return(%w[id data source])
      allow(@implementation_class).to receive(:parent_class).and_return(
        class_double('ParentWithSource', attribute_names: %w[id data source])
      )

      expect(@implementation_class.fields_to_sync).to eq(['source'])
    end

    it 'keeps an opted-out field in permitted_params for issue #1451' do
      expect(@implementation_class.permitted_params).to include(:data)
    end

    it 'allows disabled to be independently managed when it overlaps the parent field set for issue #1451' do
      allow(@implementation_class).to receive(:attribute_names).and_return(%w[id disabled])
      allow(@implementation_class).to receive(:parent_class).and_return(
        class_double('ExternalIdentifierParent', attribute_names: %w[id disabled])
      )
      @definition.configurations = OptionConfigs::ExtraOptionConfigs::Configurations.new(
        no_sync_fields: 'disabled'
      )

      expect(@implementation_class.fields_to_sync).to be_empty
    end

    it 'raises a clear error when parent metadata is unavailable' do
      configure_no_sync_fields('data')
      allow(@implementation_class).to receive(:parent_class).and_raise(NameError, 'missing parent')

      expect { @implementation_class.fields_to_sync }
        .to raise_error(FphsException, /Could not determine parent-synchronized fields/)

      notice = @implementation_class.no_sync_fields_configuration_notices.first
      expect(notice[:message]).to match(/could not validate configured fields:.*missing parent/)
    end

    it 'reports a configuration notice when the implementation class is unavailable' do
      configure_no_sync_fields('data')
      allow(@definition).to receive(:implementation_class).and_raise(NameError, 'missing implementation')

      notice = @definition.additional_configuration_notices(levels: [:errors]).first

      expect(notice[:message]).to match(/could not be validated:.*missing implementation/)
    end
  end

  describe 'save behavior' do
    it 'does not copy an opted-out overlapping field from the parent on save for issue #1451' do
      configure_no_sync_fields('data')
      activity_log = @player_contact.activity_log__player_contact_phones.build(
        select_call_direction: 'from player',
        select_who: 'user'
      )
      expect(activity_log.save).to be true
      expect(activity_log.reload.data).not_to eq @player_contact.reload.data

      activity_log.current_user = @user
      activity_log.update!(data: 'activity-only')
      expect(activity_log.reload.data).to eq 'activity-only'
      expect(@player_contact.reload.data).to eq '(516)262-1291'
    end
  end
end
