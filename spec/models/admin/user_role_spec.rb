# frozen_string_literal: true

require 'rails_helper'

# Model tests for Admin::UserRole, covering role assignment, querying,
# copying roles between users, and clearing all roles for a user
# in a specific app type (issue #671).
RSpec.describe Admin::UserRole, type: :model do
  include ModelSupport
  include PlayerInfoSupport

  RandTestRoleName = "test_role_1_#{rand 10_000_000}"
  TestRoleName2 = "test_role_2_#{rand 10_000_000}"
  App2TestRoleName2 = "app2_test_role_2_#{rand 10_000_000}"

  it 'prevents others from querying UserRole.where directly' do
    create_admin
    create_user

    expect do
      Admin::UserRole.where role_name: RandTestRoleName
    end.to raise_error FphsException

    expect(@user.app_type_id).not_to be nil
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
    r2 = create_user_role TestRoleName2, user: user0, app_type: app_type_2
    rapp2 = create_user_role App2TestRoleName2, user: user0, app_type: app_type_0

    # Copy the roles for the named app type
    res = Admin::UserRole.copy_user_roles user0, user1, app_type_2, @admin

    expect(res.length).to eq 2
    expect(Admin::UserRole.where(app_type: app_type_2, user: user1).role_names.sort).to eq [RandTestRoleName, TestRoleName2]
    expect(Admin::UserRole.where(app_type: app_type_0, user: user1).role_names).to eq []

    # Copy the roles for the other app type
    res = Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin
    expect(res.length).to eq 1

    expect(Admin::UserRole.where(app_type: app_type_2, user: user1).role_names.sort).to eq [RandTestRoleName, TestRoleName2].sort
    expect(Admin::UserRole.where(app_type: app_type_0, user: user1).role_names).to eq [App2TestRoleName2]

    # Can't copy roles if the target user has roles in the specified app
    expect do
      Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin
    end.to raise_error FphsException

    # Can't copy roles if the target user has roles in the specified app
    expect do
      Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin
    end.to raise_error FphsException

    # Can copy roles if the target user has roles in the specified app and we say to force it
    expect do
      Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin, force_not_empty: true
    end.not_to raise_error
  end

  it 're-enables disabled roles when copying with reenable_disabled option' do
    create_admin
    app_type_0 = create_app_type name: 'apptype0', label: 'apptype0'
    user0, = create_user
    user1, = create_user

    # Create roles in source user
    r1 = create_user_role 'source_role_1', user: user0, app_type: app_type_0
    r2 = create_user_role 'source_role_2', user: user0, app_type: app_type_0
    r3 = create_user_role 'source_role_3', user: user0, app_type: app_type_0

    # Create matching roles in target user, but disable some of them
    t1 = create_user_role 'source_role_1', user: user1, app_type: app_type_0
    t2 = create_user_role 'source_role_2', user: user1, app_type: app_type_0
    t2.update!(disabled: true, current_admin: @admin)
    t3 = create_user_role 'source_role_3', user: user1, app_type: app_type_0
    t3.update!(disabled: true, current_admin: @admin)

    # Copy without reenable_disabled - should return empty array (all roles already exist)
    res = Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin, force_not_empty: true
    expect(res.length).to eq 0

    # Verify disabled roles are still disabled
    t2.reload
    t3.reload
    expect(t2.disabled?).to be true
    expect(t3.disabled?).to be true

    # Copy with reenable_disabled - should re-enable the disabled roles
    res = Admin::UserRole.copy_user_roles user0, user1, app_type_0, @admin, force_not_empty: true, reenable_disabled: true
    expect(res.length).to eq 2 # Two roles were re-enabled

    # Verify disabled roles are now enabled
    t2.reload
    t3.reload
    expect(t2.disabled?).to be false
    expect(t3.disabled?).to be false
    expect(t1.disabled?).to be false # Was never disabled

    # Verify all roles are now active
    active_roles = Admin::UserRole.active.where(app_type: app_type_0, user: user1).role_names.sort
    expect(active_roles).to eq ['source_role_1', 'source_role_2', 'source_role_3']
  end

  it 'clears all roles for a user in a specific app type - issue #671' do
    create_admin
    app_type_a = create_app_type name: 'clear_test_app_a', label: 'Clear Test App A'
    app_type_b = create_app_type name: 'clear_test_app_b', label: 'Clear Test App B'
    user_to_clear, = create_user

    # Create roles in app_type_a
    create_user_role 'role_alpha', user: user_to_clear, app_type: app_type_a
    create_user_role 'role_beta', user: user_to_clear, app_type: app_type_a
    create_user_role 'role_gamma', user: user_to_clear, app_type: app_type_a

    # Create roles in app_type_b (should NOT be affected)
    create_user_role 'role_delta', user: user_to_clear, app_type: app_type_b

    # Verify active roles exist before clearing
    active_a = Admin::UserRole.active.where(user: user_to_clear, app_type: app_type_a)
    expect(active_a.count).to eq 3

    active_b = Admin::UserRole.active.where(user: user_to_clear, app_type: app_type_b)
    expect(active_b.count).to eq 1

    # Clear all roles for app_type_a
    result = Admin::UserRole.clear_user_roles(user_to_clear, app_type_a, @admin)

    # Should return the roles that were disabled
    expect(result.length).to eq 3
    expect(result.map(&:role_name).sort).to eq %w[role_alpha role_beta role_gamma]

    # All roles in app_type_a should now be disabled
    active_a_after = Admin::UserRole.active.where(user: user_to_clear, app_type: app_type_a)
    expect(active_a_after.count).to eq 0

    # Roles in app_type_b should be untouched
    active_b_after = Admin::UserRole.active.where(user: user_to_clear, app_type: app_type_b)
    expect(active_b_after.count).to eq 1
  end

  context 'clear_user_roles guard clauses - issue #671' do
    it 'raises an error when app_type is blank' do
      create_admin
      user_to_clear, = create_user

      expect do
        Admin::UserRole.clear_user_roles(user_to_clear, nil, @admin)
      end.to raise_error(FphsException, /app_type must be specified/)
    end

    it 'raises an error when user is blank' do
      create_admin
      app_type_a = create_app_type name: 'clear_no_user_app', label: 'Clear No User App'

      expect do
        Admin::UserRole.clear_user_roles(nil, app_type_a, @admin)
      end.to raise_error(FphsException, /user must be specified/)
    end

    it 'returns empty array when user has no active roles to clear' do
      create_admin
      app_type_empty = create_app_type name: 'clear_empty_app', label: 'Clear Empty App'
      user_no_roles, = create_user

      result = Admin::UserRole.clear_user_roles(user_no_roles, app_type_empty, @admin)
      expect(result).to eq []
    end
  end
end
