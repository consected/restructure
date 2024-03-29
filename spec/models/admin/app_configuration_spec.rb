require 'rails_helper'

RSpec.describe Admin::AppConfiguration, type: :model do
  include ModelSupport

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
