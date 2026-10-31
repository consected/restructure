# frozen_string_literal: true

# Purpose: Verify app-configuration names are accepted and their values can be resolved.
require 'rails_helper'

RSpec.describe Admin::AppConfiguration, type: :model do
  include ModelSupport

  describe 'message notification matching configurations' do
    before :example do
      create_admin
      @user, = create_user
      @app_type = @user.app_type
    end

    it 'accepts and resolves the resource, country-code, and trunk-number settings' do
      resources = { email: 'dynamic_model__femfl_contact_emails', phone: 'dynamic_model__femfl_contact_phones' }.to_yaml
      add_app_config(@app_type, 'message notification contact resources', resources)
      add_app_config(@app_type, 'default phone country code', '44')
      add_app_config(@app_type, 'default phone trunk number', '0')

      expect(described_class.configurations).to include(
        'message notification contact resources',
        'default phone country code',
        'default phone trunk number'
      )
      expect(described_class.hash_for(:message_notification_contact_resources, @user)).to eq(
        email: 'dynamic_model__femfl_contact_emails', phone: 'dynamic_model__femfl_contact_phones'
      )
      expect(described_class.value_for(:default_phone_country_code, @user)).to eq '44'
      expect(described_class.value_for(:default_phone_trunk_number, @user)).to eq '0'
    end

    it 'resolves notification matching settings in user, role, then app precedence' do
      role_name = 'notification tracker config role'
      create_user_role(role_name, user: @user, app_type: @app_type)
      values = {
        'message notification contact resources' => [
          { email: 'app_emails', phone: 'app_phones' }.to_yaml,
          { email: 'role_emails', phone: 'role_phones' }.to_yaml,
          { email: 'user_emails', phone: 'user_phones' }.to_yaml
        ],
        'default phone country code' => %w[1 44 61],
        'default phone trunk number' => %w[1 0 8]
      }

      values.each do |name, (app_value, role_value, user_value)|
        described_class.add_default_config(@app_type, name, app_value, @admin)
        described_class.create!(
          current_admin: @admin,
          app_type: @app_type,
          role_name:,
          name:,
          value: role_value
        )
        described_class.add_user_config(@user, @app_type, name, user_value, @admin)

        resolved = described_class.where(name:).scope_user_and_role(@user, @app_type.id).first
        expect(resolved.value).to eq user_value

        described_class.where(name:, user: @user).each do |configuration|
          configuration.update!(disabled: true, current_admin: @admin)
        end
        resolved = described_class.where(name:).scope_user_and_role(@user, @app_type.id).first
        expect(resolved.value).to eq role_value

        described_class.where(name:, role_name:).each do |configuration|
          configuration.update!(disabled: true, current_admin: @admin)
        end
        resolved = described_class.where(name:).scope_user_and_role(@user, @app_type.id).first
        expect(resolved.value).to eq app_value
      end
    end

    it 'uses the server phone defaults when a notification has no user or app type' do
      notification = Messaging::MessageNotification.new(user: nil, app_type: nil)
      matcher = Messaging::MessageNotificationTracker.new(notification)

      configuration = matcher.send(:matching_configuration)

      expect(configuration[:country_code]).to eq Settings::DefaultPhoneCountryCode
      expect(configuration[:trunk_number]).to eq Settings::DefaultPhoneTrunkNumber
    end
  end

  it 'prevents invalid configuration names' do
    user1, = create_user
    expect do
      add_app_config user1.app_type, 'config1', 'valblank'
    end.to raise_error FphsException
  end

  it 'Adds an item to a configuration with non-blank app type' do
    create_admin
    create_user
    app_type = @user.app_type

    Admin::AppConfiguration.remove_user_config @user, app_type, 'notes field caption', @admin
    Admin::AppConfiguration.remove_default_config app_type, 'notes field caption', @admin

    res = Admin::AppConfiguration.value_for :notes_field_config, @user
    expect(res).to be nil

    res = Admin::AppConfiguration.find_default_app_config(app_type, 'notes field caption')
    expect(res).to be nil

    res = Admin::AppConfiguration.value_for :notes_field_config
    expect(res).to be nil

    expect do
      Admin::AppConfiguration.add_default_config app_type, 'some test config', 'a value', @admin
    end.to raise_error FphsException

    res = Admin::AppConfiguration.add_default_config app_type, 'notes field caption', 'a value', @admin
    expect(res).to be_a Admin::AppConfiguration

    res = Admin::AppConfiguration.value_for :notes_field_caption, @user
    expect(res).to eq 'a value'

    # Default should work with both nil and blank role name
    res = Admin::AppConfiguration.find_default_app_config(app_type, 'notes field caption')
    expect(res).not_to be nil

    res.update!(role_name: '', current_admin: @admin)

    res = Admin::AppConfiguration.find_default_app_config(app_type, 'notes field caption')
    expect(res).not_to be nil

    # Check a user config

    res = Admin::AppConfiguration.add_user_config @user, app_type, 'notes field caption', 'user value', @admin
    expect(res).to be_a Admin::AppConfiguration

    res = Admin::AppConfiguration.value_for :notes_field_caption, @user
    expect(res).to eq 'user value'
  end

  it 'allows assignment of a role_name configuration' do
    user1, = create_user
    user2, = create_user
    user3, = create_user

    expect(user1.app_type_id == user2.app_type_id && user2.app_type_id == user3.app_type_id).to be true
    ac = Admin::AppConfiguration.find_default_app_config(user1.app_type, 'menu research label')
    ac&.disable!(@admin)

    user_role1 = create_user_role 'role 1', user: user1
    user_role2 = create_user_role 'role 2', user: user1
    user_role3 = create_user_role 'role 1', user: user2

    add_app_config user1.app_type, 'menu research label', 'valblank'
    add_app_config user1.app_type, 'menu research label', 'val1', role_name: 'role 1'
    add_app_config user1.app_type, 'menu research label', 'valuser2', user: user2

    add_app_config user1.app_type, 'notes field caption', 'val2', role_name: 'role 1'
    add_app_config user1.app_type, 'notes field caption', 'valuser1', user: user1

    res = Admin::AppConfiguration.value_for 'menu research label', user1
    expect(res).to eq 'val1'

    res = Admin::AppConfiguration.value_for 'menu research label', user2
    expect(res).to eq 'valuser2'

    res = Admin::AppConfiguration.value_for 'menu research label', user3
    expect(res).to eq 'valblank'

    res = Admin::AppConfiguration.value_for 'notes field caption', user1
    expect(res).to eq 'valuser1'

    res = Admin::AppConfiguration.value_for 'notes field caption', user2
    expect(res).to eq 'val2'

    res = Admin::AppConfiguration.value_for 'notes field caption', user3
    expect(res).to be_blank
  end
end
