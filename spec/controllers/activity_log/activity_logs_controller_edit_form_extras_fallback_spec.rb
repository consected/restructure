# frozen_string_literal: true

require 'rails_helper'

# RED phase tests for issue #1445 (problem 1 - Symbol/String mismatch in
# ActivityLog::ActivityLogsController#edit_form_extras fallback branches).
#
# `@implementation_class.view_attribute_list` / `view_blank_log_attribute_list`
# return Arrays of Symbols, but the two `||=` fallback branches in
# `edit_form_extras` (used whenever `@option_type_config` is nil - e.g. an
# `extra_log_type`/`extra_type` param naming a type that is not in
# `option_configs_names`) subtract String arrays
# (`@implementation_class.fields_to_sync.map(&:to_s)` and
# `['tracker_history_id']`) from them. Because of the type mismatch, both
# subtractions are silent no-ops, so:
#   - `tracker_history_id` (a synthetic field that is never a real DB column)
#     remains in `item_list` on both fallback branches
#   - fields shared with the parent item type (`fields_to_sync`) remain in
#     `item_list` on the `@item`-present fallback branch, even though they are
#     correctly stripped on the `@option_type_config` branch and from
#     `permitted_params`
#
# These specs call `edit_form_extras` directly via `send` (unit level),
# pinning down the root cause described in the issue, independent of the
# downstream `FphsException` raised by the edit form view.
RSpec.describe ActivityLog::ActivityLogsController, type: :controller do
  include ActivityLogSupport
  include ModelSupport
  include MasterSupport

  before(:each) do
    SetupHelper.setup_al_player_contact_phones
    definition = ActivityLog::PlayerContactPhone.definition.reload
    definition.configurations = nil
    definition.option_configs(force: true)
    ActivityLog.definition_cache[ActivityLog::PlayerContactPhone.definition_id] = definition

    create_admin
    create_user
    create_master @user

    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type

    @player_contact = @master.player_contacts.create!(
      current_user: @user,
      data: '(516)262-1291',
      source: 'nfl',
      rank: 10,
      rec_type: 'phone'
    )
  end

  let(:implementation_class) { ActivityLog::PlayerContactPhone }

  # Confirmed by the issue: for ActivityLog::PlayerContactPhone,
  # fields_to_sync == ["data"], since "data" is defined in the Phone Log's
  # field_list and also exists as a PlayerContact attribute.
  it 'has a fields_to_sync overlap with the parent item type, matching the issue investigation' do
    expect(implementation_class.fields_to_sync).to eq(['data'])
  end

  describe '#edit_form_extras when @option_type_config is nil and @item is present (edit-style fallback)' do
    controller ActivityLog::PlayerContactPhonesController do
      nil # anonymous subclass required by the `controller` example group DSL; no overrides needed
    end

    before do
      allow(controller).to receive_messages(current_user: @user, current_admin_sample: false)
      controller.instance_variable_set(:@implementation_class, implementation_class)
      controller.instance_variable_set(:@option_type_config, nil)
      controller.instance_variable_set(:@item, @player_contact)
    end

    it 'does not contain the synthetic :tracker_history_id field, which is never a real column' do
      extras = controller.send(:edit_form_extras)

      # normalise to strings so this fails whether the bug leaves Symbols or a fix leaves the value as a String
      expect(extras[:item_list].map(&:to_s)).not_to include('tracker_history_id')
    end

    it 'does not contain the parent-synced "data" field, matching the @option_type_config branch behaviour' do
      extras = controller.send(:edit_form_extras)

      expect(extras[:item_list].map(&:to_s)).not_to include('data')
    end

    it 'returns item_list as an Array of Strings, matching the @option_type_config branch contract' do
      extras = controller.send(:edit_form_extras)

      expect(extras[:item_list]).to all(be_a(String))
    end

    it 'includes a configured no_sync_fields value in the activity form for issue #1451' do
      implementation_class.definition.configurations = OptionConfigs::ExtraOptionConfigs::Configurations.new(
        no_sync_fields: 'data'
      )
      allow(implementation_class).to receive(:view_attribute_list).and_return(%i[data notes])

      extras = controller.send(:edit_form_extras)

      expect(extras[:item_list]).to include('data')
    end
  end

  describe '#edit_form_extras when @option_type_config is nil and @item is blank (new/blank_log-style fallback)' do
    controller ActivityLog::PlayerContactPhonesController do
      nil # anonymous subclass required by the `controller` example group DSL; no overrides needed
    end

    before do
      allow(controller).to receive_messages(current_user: @user, current_admin_sample: false)
      controller.instance_variable_set(:@implementation_class, implementation_class)
      controller.instance_variable_set(:@option_type_config, nil)
      controller.instance_variable_set(:@item, nil)
    end

    it 'does not contain the synthetic :tracker_history_id field, which is never a real column' do
      extras = controller.send(:edit_form_extras)

      expect(extras[:item_list].map(&:to_s)).not_to include('tracker_history_id')
    end

    it 'does not contain a parent-synced field, even when the blank log field list explicitly includes it' do
      # ActivityLog::PlayerContactPhone's real blank_log_field_list doesn't happen to overlap with
      # fields_to_sync (["data"]), so stub it here to pin the subtraction in this branch too.
      allow(implementation_class).to receive(:view_blank_log_attribute_list).and_return(%i[data notes])

      extras = controller.send(:edit_form_extras)

      expect(extras[:item_list].map(&:to_s)).not_to include('data')
      expect(extras[:item_list].map(&:to_s)).to include('notes')
    end

    it 'returns item_list as an Array of Strings, matching the @option_type_config branch contract' do
      extras = controller.send(:edit_form_extras)

      expect(extras[:item_list]).to all(be_a(String))
    end
  end
end
