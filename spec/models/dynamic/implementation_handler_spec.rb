# frozen_string_literal: true

require 'rails_helper'

# Verify implementation handler presets and typed conditional access rules.
RSpec.describe Dynamic::ImplementationHandler, type: :model do
  describe '#calc_can' do
    it 'evaluates a typed editable_if configuration' do
      editable_if = OptionConfigs::ExtraOptionConfigs::EditableIf.new(never: true)
      option_type_config = double(editable_if:)
      old_object = Struct.new(:id, :master).new
      handler = Object.new.extend(described_class)
      master = Object.new

      handler.define_singleton_method(:option_type_config) { option_type_config }
      handler.define_singleton_method(:master) { master }
      handler.define_singleton_method(:changes) { {} }
      handler.define_singleton_method(:id) { 123 }
      handler.define_singleton_method(:dup) { old_object }
      expect(option_type_config).to receive(:calc_if).with(:editable_if, old_object).and_return(false)

      expect(handler.send(:calc_can, :edit)).to be false
    end

    it 'does not evaluate a blank typed editable_if configuration' do
      editable_if = OptionConfigs::ExtraOptionConfigs::EditableIf.new
      option_type_config = double(editable_if:)
      handler = Object.new.extend(described_class)

      handler.define_singleton_method(:option_type_config) { option_type_config }
      expect(option_type_config).not_to receive(:calc_if)

      expect(handler.send(:calc_can, :edit)).to be_nil
    end

    it 'does not evaluate a malformed scalar editable_if configuration' do
      option_type_config = double(editable_if: 'never')
      handler = Object.new.extend(described_class)

      handler.define_singleton_method(:option_type_config) { option_type_config }
      expect(option_type_config).not_to receive(:calc_if)

      expect(handler.send(:calc_can, :edit)).to be_nil
    end
  end
end

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Implementation handler', type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :example do
    # SetupHelper.setup_al_player_contact_phones
    # ::ActivityLog.define_models
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
  end

  it 'presets fields in a new item' do
    @player_contact.master.current_user = @user
    master = @player_contact.master
    expect(master.current_user).to eq @user

    ActivityLog::PlayerContactPhone.definition.option_type_config_for(:primary).preset_fields = {
      with_result: {
        from: {
          player_contacts: {
            return: 'return_result'
          }
        },
        attributes: {
          select_who: 'rec_type'
        }
      },
      with: {
        select_call_direction: 'from staff'
      }
    }

    al = @player_contact.activity_log__player_contact_phones.create!({})
    expect(al.master_user).to eq @user
    expect(master.activity_log__player_contact_phones).not_to be nil
    expect(al.select_who).to eq @player_contact.rec_type
    expect(al.select_call_direction).to eq 'from staff'
  end

  after :example do
    ActivityLog::PlayerContactPhone.definition.option_type_config_for(:primary).preset_fields = {}
  end
end
