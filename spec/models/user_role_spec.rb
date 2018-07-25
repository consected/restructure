require 'rails_helper'

RSpec.describe Admin::UserRole, type: :model do

  include ModelSupport
  include PlayerInfoSupport

  TestRoleName = 'test_role_1'

  it "always ensures an app type is applied to the user roles selection" do
    create_admin
    app_type_2 = create_app_type name: 'apptype2', label: 'apptype2'
    user0, _ = create_user

    # Validates that a named user in a user access control works
    let_user_create_player_infos
    let_user_create_player_infos in_app_type: app_type_2
    create_item
    user0.app_type = app_type_2
    create_item

    user1, _ = create_user
    user2, _ = create_user

    r1 = create_user_role TestRoleName, user: user1
    r2 = create_user_role TestRoleName, user: user2, app_type: app_type_2

    res = user1.has_access_to? :read, :table, :player_infos
    expect(res).to be_falsey # since the user does not have a useful role
    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_falsey # since the user does not have a useful role


    uac_test_role = Admin::UserAccessControl.create! app_type: user1.app_type, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                      role_name: TestRoleName

    uac_test_role2 = Admin::UserAccessControl.create! app_type: app_type_2, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                      role_name: TestRoleName

    res = user1.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy # since the user's current app type has the role

    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_falsey # since the user's current app type does not have the role

    user2.app_type = app_type_2
    user2.save!
    user2.reload

    res = user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy # since the user's current app type has the role

  end

  it "gets the right role names for the current app type" do
    create_admin
    app_type_2 = create_app_type name: 'apptype2', label: 'apptype2'
    user0, _ = create_user
    user1, _ = create_user
    user2, _ = create_user

    app_type_1 = user1.app_type

    r1 = create_user_role TestRoleName, user: user1
    r2 = create_user_role TestRoleName, user: user2, app_type: app_type_2

    uac_test_role = Admin::UserAccessControl.create! app_type: app_type_1, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                      role_name: TestRoleName

    uac_test_role2 = Admin::UserAccessControl.create! app_type: app_type_2, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                      role_name: TestRoleName


    expect(user1.user_roles.role_names).to eq [TestRoleName]
    expect(user2.user_roles.role_names).to eq []

    user1.update! app_type: app_type_2
    user2.update! app_type: app_type_2
    user1.reload
    user2.reload

    expect(user1.user_roles.role_names).to eq []
    expect(user2.user_roles.role_names).to eq [TestRoleName]

    # Check the list of User IDs in a role are correctly returned for the app (as used in email notifications)
    res = Admin::UserRole.active_user_ids role_name: TestRoleName, app_type: app_type_1
    expect(res).to eq [user1.id]

    res = Admin::UserRole.active_user_ids role_name: TestRoleName, app_type: app_type_2
    expect(res).to eq [user2.id]

    # Now add user1 to the Test Role
    r3 = create_user_role TestRoleName, user: user1, app_type: app_type_2

    res = Admin::UserRole.active_user_ids role_name: TestRoleName, app_type: app_type_1
    expect(res).to eq [user1.id]

    res = Admin::UserRole.active_user_ids role_name: TestRoleName, app_type: app_type_2
    expect(res).to eq [user2.id, user1.id]

    # The user should now see the role for both app types
    expect(user1.app_type_id).to eq app_type_2.id
    expect(user1.user_roles.role_names).to eq [TestRoleName]

    user1.update! app_type: app_type_1
    user1.reload

    expect(user1.user_roles.role_names).to eq [TestRoleName]

  end

end
