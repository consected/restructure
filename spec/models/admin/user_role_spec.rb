# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UserRole, type: :model do
  include ModelSupport
  include PlayerInfoSupport

  RandTestRoleName = "test_role_1_#{rand 10_000_000}"
  RandTestRoleName2 = "test_role_2_#{rand 10_000_000}"
  App2RandTestRoleName2 = "app2_test_role_2_#{rand 10_000_000}"

  it 'prevents others from querying UserRole.where directly' do
    create_admin
    create_user

    expect do
      Admin::UserRole.where role_name: RandTestRoleName
    end.to raise_error FphsException

    res = Admin::UserRole.where role_name: RandTestRoleName, app_type: @user.app_type
    expect(res).to be_a ActiveRecord::Relation
  end

  it 'always ensures an app type is applied to the user roles selection' do
    create_admin
    app_type_1 = @user&.app_type || Admin::AppType.active.first
    app_type_2 = create_app_type name: 'apptype2', label: 'apptype2'
    user0, = create_user

    # Validates that a named user in a user access control works
    let_user_create_player_infos
    let_user_create_player_infos in_app_type: app_type_2
    create_item
    user0.app_type = app_type_2
    create_item

    @user.app_type = app_type_1
    user1, = create_user
    user2, = create_user

    expect(app_type_2.id).not_to eq user1.app_type.id

    r1 = create_user_role RandTestRoleName, user: user1
    r2 = create_user_role RandTestRoleName, user: user2, app_type: app_type_2

    res = user1.has_access_to? :read, :table, :player_infos
    expect(res).to be_falsey # since the user does not have a useful role
    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_falsey # since the user does not have a useful role

    uac_test_role = Admin::UserAccessControl.create! app_type: app_type_1, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                                     role_name: RandTestRoleName

    uac_test_role2 = Admin::UserAccessControl.create! app_type: app_type_2, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                                      role_name: RandTestRoleName

    res = user1.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy # since the user's current app type has the role

    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_falsey # since the user's current app type does not have the role

    user2.app_type = app_type_2
    user2.save!
    user2.reload

    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be nil # since the user doesn't have access to the app

    enable_user_app_access app_type_2.name, user2
    user2.app_type = app_type_2
    user2.save!
    user2.reload

    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy # since the user's current app type has the role
  end

  it 'gets the right role names for the current app type' do
    create_admin
    app_type_2 = create_app_type name: 'apptype2', label: 'apptype2'
    user0, = create_user
    user1, = create_user
    user2, = create_user

    app_type_1 = user1.app_type

    expect(app_type_2.id).not_to eq user1.app_type.id

    r1 = create_user_role RandTestRoleName, user: user1
    r2 = create_user_role RandTestRoleName, user: user2, app_type: app_type_2

    uac_test_role = Admin::UserAccessControl.create! app_type: app_type_1, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                                     role_name: RandTestRoleName

    uac_test_role2 = Admin::UserAccessControl.create! app_type: app_type_2, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                                      role_name: RandTestRoleName

    expect(user1.user_roles.role_names).to eq [RandTestRoleName]
    expect(user2.user_roles.role_names).to eq []

    enable_user_app_access app_type_2.name, user1
    enable_user_app_access app_type_2.name, user2

    user1.update! app_type: app_type_2
    user2.update! app_type: app_type_2
    user1.reload
    user2.reload

    expect(user1.user_roles.role_names).to eq []
    expect(user2.user_roles.role_names).to eq [RandTestRoleName]

    # Check the list of User IDs in a role are correctly returned for the app (as used in email notifications)
    res = Admin::UserRole.active_user_ids role_name: RandTestRoleName, app_type: app_type_1
    expect(res.sort).to eq [User.template_user.id, user1.id].sort

    res = Admin::UserRole.active_user_ids role_name: RandTestRoleName, app_type: app_type_2
    expect(res.sort).to eq [User.template_user.id, user2.id].sort

    res = user1.user_roles.active.where(app_type: user1.app_type).pluck(:role_name)
    res1 = user1.user_roles.active.pluck(:role_name)
    expect(res).to eq res1

    # Now add user1 to the Test Role
    r3 = create_user_role RandTestRoleName, user: user1, app_type: app_type_2

    res = Admin::UserRole.active_user_ids role_name: RandTestRoleName, app_type: app_type_1
    expect(res.sort).to eq [User.template_user.id, user1.id].sort

    res = Admin::UserRole.active_user_ids role_name: RandTestRoleName, app_type: app_type_2
    expect(res.sort).to eq [User.template_user.id, user2.id, user1.id].sort

    # The user should now see the role for both app types
    expect(user1.app_type_id).to eq app_type_2.id
    expect(user1.user_roles.role_names).to eq [RandTestRoleName]

    user1.update! app_type: app_type_1
    user1.reload

    expect(user1.user_roles.role_names).to eq [RandTestRoleName]
  end

  it 'duplicates all the roles from one user to another' do
    create_admin
    app_type_2 = create_app_type name: 'apptype2', label: 'apptype2'
    user0, = create_user
    app_type_0 = user0.app_type

    # Validates that a named user in a user access control works
    let_user_create_player_infos
    let_user_create_player_infos in_app_type: app_type_2
    create_item
    user0.app_type = app_type_2
    expect(user0.app_type).to be_a Admin::AppType
    create_item

    expect(user0.user_roles.length).to eq 0

    user1, = create_user

    r1 = create_user_role RandTestRoleName, user: user0, app_type: app_type_2
    r2 = create_user_role RandTestRoleName2, user: user0, app_type: app_type_2
    rapp2 = create_user_role App2RandTestRoleName2, user: user0, app_type: app_type_0

    # Copy the roles for the named app type
    res = Admin::UserRole.copy_user_roles user0, user1, app_type_2, @admin

    expect(res.length).to eq 2
    expect(Admin::UserRole.where(app_type: app_type_2, user: user1).role_names.sort).to eq [RandTestRoleName, RandTestRoleName2]
    expect(Admin::UserRole.where(app_type: app_type_0, user: user1).role_names).to eq []

    # Copy the roles for the other app type
    res = Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin
    expect(res.length).to eq 1

    expect(Admin::UserRole.where(app_type: app_type_2, user: user1).role_names.sort).to eq [RandTestRoleName, RandTestRoleName2].sort
    expect(Admin::UserRole.where(app_type: app_type_0, user: user1).role_names).to eq [App2RandTestRoleName2]

    # Can't copy roles if the target user has roles in the specified app
    expect do
      Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin
    end.to raise_error FphsException
  end
end
