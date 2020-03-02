require 'rails_helper'
require './db/table_generators/external_identifiers_table.rb'

RSpec.describe Admin::UserAccessControl, type: :model do

  include ModelSupport
  include PlayerInfoSupport

  OtherRoleName = 'other_test_role'
  TestRoleName = 'test_role'


  it "should not create default access controls for a new user" do

    (1..3).each do

      create_user nil, '', no_app_type_setup: true

      res = Admin::UserAccessControl.where(user_id: @user.id)
      expect(res.length).to eq 0
    end
  end

  it "should prevent a user from having multiple entries for the same named resource type" do

    app_type_id = Admin::AppType.active.first.id
    (1..3).each do
      create_user
      Admin::UserAccessControl.create user: @user, resource_type: :table, resource_name: 'player_infos', current_admin: @admin, app_type_id: app_type_id

      expect{
        Admin::UserAccessControl.create! user: @user, resource_type: :table, resource_name: 'player_infos', current_admin: @admin, app_type_id: app_type_id
      }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it "should not create default access controls for a new app type" do

    create_admin
    (1..3).each do |i|
      a = create_app_type name: "app#{i}", label: "app#{i}"

      res = Admin::UserAccessControl.where(app_type_id: a.id)
      expect(res.length).to eq 0
    end
  end


  it "allows testing of a user's access to a resource" do

    create_user

    let_user_create_player_infos


    res = @user.has_access_to? :read, :table, 'player_infos'
    expect(res).to be_falsey

    res = @user.has_access_to? :update, :table, 'player_infos'
    expect(res).to be_falsey

    res = @user.has_access_to? :create, :table, 'player_infos'
    expect(res).to be_truthy

    res = @user.has_access_to? [:read, :update, :create], :table, 'player_infos'
    expect(res).to be_truthy


    res = @user.has_access_to? :access, :table, 'player_infos'
    expect(res).to be_truthy

    res = @user.has_access_to? :edit, :table, 'player_infos'
    expect(res).to be_truthy

    expect {
      res = @user.has_access_to? :fake, :table, 'player_infos'

    }.to raise_error FphsException

  end

  it "allows a user access to a table" do

    create_user
    let_user_create_player_infos

    create_item

    # by default, a user is granted access to all tables
    res = @user.has_access_to? :access, :table, :player_infos
    expect(res).to be_truthy

    res = PlayerInfo.allows_user_access_to? @user, :access
    expect(res).to be_truthy

    id = @player_info.id

    res = @master.player_infos.where id: id

    expect(res.first).not_to be nil
    expect(res.first.id).to eq id

    # First, check at an individual master level
    @master.current_user = @user
    jres = @master.to_json

    res = JSON.parse jres
    expect(res['player_infos']).not_to be nil
    expect(res['player_infos'].first['id']).to eq id

    # Now try a query
    ids = []
    player_ids = []
    (0..9).each do
      create_master
      create_item
      ids << @master.id
      player_ids << @player_info.id
    end

    jres = Master.where(id: ids).to_json(current_user: @user)
    res = JSON.parse jres

    expect(res.length).to eq 10
    res.each do |item|
      expect(item['player_infos']).not_to be nil
      expect(item['player_infos'].first['id']).to be_in player_ids
    end

  end

  it "prevents a user from accessing to a table" do

    create_admin
    create_user
    let_user_create_player_infos

    create_item

    # by default, a user is granted access to all tables

    original_acl =res = @user.has_access_to? :access, :table, :player_infos
    res.access = nil
    res.current_admin = @admin
    res.save!

    res = @user.has_access_to? :access, :table, :player_infos
    expect(res).to be_falsey

    res = PlayerInfo.allows_user_access_to? @user, :access
    expect(res).to be_falsey


    @player_info.id

    # First, check at an individual master level
    @master.current_user = @user
    jres = @master.to_json

    res = JSON.parse jres
    expect(res['player_infos']).to be nil


    # Now try a query
    res = original_acl
    res.current_admin = @admin
    res.access = :create
    res.save!


    ids = []
    (0..9).each do
      create_master
      create_item
      ids << @master.id
    end

    res.access = nil
    res.save!


    jres = Master.where(id: ids).to_json(current_user: @user)
    res = JSON.parse jres

    expect(res.length).to eq 10
    res.each do |item|
      expect(item['player_infos']).to be nil
    end

  end

  # check a special case
  it "prevents a user from accessing to latest tracker history association" do

    create_admin
    create_user
    let_user_create_player_infos

    create_item

    Admin::UserAccessControl.create! current_admin: @admin, app_type: @user.app_type, user: @user, access: :read, resource_type: :table, resource_name: :latest_tracker_history
    Admin::UserAccessControl.create! current_admin: @admin, app_type: @user.app_type, user: @user, access: :read, resource_type: :table, resource_name: :tracker_histories
    Admin::UserAccessControl.create! current_admin: @admin, app_type: @user.app_type, user: @user, access: :create, resource_type: :table, resource_name: :trackers

    res = @user.has_access_to? :access, :table, :tracker_histories
    expect(res).to be_truthy

    @master.current_user = @user
    jres = @master.to_json
    res = JSON.parse jres

    expect(res['latest_tracker_history']).not_to be nil

    res = @user.has_access_to? :access, :table, :tracker_histories
    res.access = nil
    res.current_admin = @admin
    res.save!

    res = @user.has_access_to? :access, :table, :tracker_histories
    expect(res).to be_falsey

    @master.current_user = @user
    jres = @master.to_json
    res = JSON.parse jres
    expect(res['latest_tracker_history']).to be nil

  end

  it "prevents a user updating a model instance" do

    create_admin
    create_user
    let_user_create_player_infos

    create_item

    @master.current_user = @user

    @player_info.update!(first_name: 'oldaaabbbccc')

    res = @user.has_access_to? :access, :table, :player_infos
    res.access = :read
    res.current_admin = @admin
    res.save!

    expect {
      @player_info.update!(first_name: 'aaabbbccc')
    }.to raise_error FphsException

  end

  it "prevents a user creating a model instance" do

    create_admin
    create_user
    let_user_create_player_infos

    create_item

    @master.current_user = @user
    res = @user.has_access_to? :access, :table, :player_infos
    res.access = :read
    res.current_admin = @admin
    res.save!

    expect {
      create_item no_access_change: true
    }.to raise_error FphsException

  end


  it "allows a user's access to override the default" do

    create_admin
    create_user
    let_user_create_player_infos

    create_item

    @master.current_user = @user

    @player_info.update!(first_name: 'oldaaabbbccc')

    res = @user.has_access_to? :access, :table, :player_infos
    res.access = :read
    res.current_admin = @admin
    res.save!

    expect {
      @player_info.update!(first_name: 'aaabbbccc')
    }.to raise_error FphsException

    # uac = Admin::UserAccessControl.create! app_type_id: @user.app_type_id, user_id: @user.id,  access: :update, resource_type: :table, resource_name: :player_infos, current_admin: @admin
    res.access = :update
    res.current_admin = @admin
    res.save!

    res = @user.has_access_to? :update, :table, :player_infos
    # expect(res.id).to eq uac.id

    expect(@player_info.update(first_name: 'aaabbbccc')).to be_truthy

    res.access = nil
    res.current_admin = @admin
    res.save!

    res = @user.has_access_to? :access, :table, :player_infos
    expect(res).to be nil


    j = @player_info.to_json

    expect(j).to eq '{}'

  end

  it "limits a user to master records with a limited_access specified and an associated model or external identifier in place" do

    # Create an external identifier implementation
    create_admin
    user1, _ = create_user opt: {no_app_type_setup: true}
    create_user
    r = 'test7'
    @implementation_table_name = "test_external_uac_identifiers"
    @implementation_attr_name = "uac_identifier_id"
    unless ActiveRecord::Base.connection.table_exists? @implementation_table_name
      TableGenerators.external_identifiers_table(@implementation_table_name, true, @implementation_attr_name)
    end

    # We don't know if user1 can access the same app as @user.
    # Set things up so she can
    res = user1.has_access_to? :read, :general, :app_type, alt_app_type_id: @user.app_type_id
    unless res
      Admin::UserAccessControl.create! user: user1, app_type: @user.app_type, access: :read, resource_type: :general, resource_name: :app_type,  current_admin: @admin
    end
    user1.app_type_id = @user.app_type_id
    user1.save!
    res = user1.has_access_to? :read, :general, :app_type
    expect(res).to be_truthy

    vals = {
      name: @implementation_table_name,
      label: "test id",
      external_id_attribute: @implementation_attr_name,
      min_id: 1,
      max_id: 99999999,
      disabled: false,
      current_admin: @admin
    }

    e = ExternalIdentifier.create! vals
    e.update_tracker_events


    c = e.implementation_class

    let_user_create_player_infos

    # Create some master records
    ids = []
    player_ids = []
    (0..9).each do
      create_master
      create_item
      ids << @master.id
      player_ids << @player_info.id
    end

    # We will deprecate the use of :external_id_assignments in favor of :limited_access
    # Check they both have the same result
    [:limited_access, :external_id_assignments].each do |rt|

      #puts "Trying resource_type: #{rt}"

      # Check that users can access these records
      jres = Master.where(id: ids).limited_access_scope(@user).to_json(current_user: @user)
      res = JSON.parse jres
      expect(res.length).to eq 10


      # Initialize the acceess control to external id assignments, but don't enforce a restriction
      ac = Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: nil, resource_type: rt, resource_name: @implementation_table_name, current_admin: @admin
      expect(Admin::UserAccessControl.limited_access_restrictions(@user)).to be nil
      res = @user.has_access_to? :limited, rt, @implementation_table_name
      expect(res).to be_falsey

      # Force users in the app type to only have access to externally identified records
      ac.update! access: :limited

      # Validate the control was set
      res = @user.has_access_to? :limited, rt, @implementation_table_name
      expect(res).to be_truthy
      expect(Admin::UserAccessControl.limited_access_restrictions(@user).first).to eq ac


      # Now we should get none of the master records returned
      jres = Master.where(id: ids).limited_access_scope(@user).to_json(current_user: @user)
      res = JSON.parse jres
      expect(res.length).to eq 0

      # Adding an external identifier for a master record allows access

      # But we need a second user, with privileges to do this, as the current users can't create the external identifier
      # because he can't see the master. This is of course correct, otherwise the current user could add an
      # external identifier himself to gain access
      # This demonstrates again that the default value can be overridden for a specific user
      ac2 = Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: nil, resource_type: rt, resource_name: @implementation_table_name, current_admin: @admin, user: user1
      ac3 = Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :create, resource_type: :table, resource_name: @implementation_table_name, current_admin: @admin, user: user1
      res = user1.has_access_to? :limited, rt, @implementation_table_name
      expect(res).to be_falsey
      expect(Admin::UserAccessControl.limited_access_restrictions(user1)).to be nil

      extids = []
      ids.each do |i|

        m = Master.find(i)
        m.current_user = @user
        expect(m.to_json).to eq "{}"

        m2 = Master.find(i)
        m2.current_user = user1
        j = JSON.parse(m2.to_json)
        expect(j['id']).to eq m2.id

        extids << c.create!( @implementation_attr_name => rand(1..99999999), master: m2)

        m = Master.find(i)
        m.current_user = @user
        j = JSON.parse(m.to_json)
        expect(j['id']).to eq m.id

      end

      # Cleanup for next round
      extids.each do |ex|
        # Force a master change
        exrec = ex.class.where(id: ex.id)
        exrec.update_all(master_id: -1)
      end

      ac.update! access: nil, disabled: true
      ac2.update! disabled: true
      ac3.update! disabled: true
    end

  end

  it "manages standard user authorizations to use features, such as create master record" do
    create_admin
    create_user


    res = @user.has_access_to? :access, :general, :create_master
    expect(res).to be_falsey

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :create_master, current_admin: @admin, user: @user

    res = @user.has_access_to? :access, :general, :create_master
    expect(res).to be_truthy

    expect(@user.can? :create_master).to be_truthy

  end

  it "allows a role instead of a user override" do

    create_admin
    app0 = create_app_type name: 'test_0', label: 'Test 0'
    @user1, _ = create_user
    @user2, _ = create_user
    @user3, _ = create_user
    @user4, _ = create_user
    let_user_create_player_infos
    create_item

    # Create a role in another app to ensure that there is no leakage
    create_user_role OtherRoleName, app_type: app0, user: @user4
    create_user_role OtherRoleName, user: @user1
    user_role1 = create_user_role TestRoleName, user: @user1
    create_user_role TestRoleName, user: @user2
    # Admin::UserRole.create! current_admin: @admin, app_type: app0, role_name: OtherRoleName, user: @user4
    # Admin::UserRole.create! current_admin: @admin, app_type: @user.app_type, role_name: TestRoleName, user: @user1
    # Admin::UserRole.create! current_admin: @admin, app_type: @user.app_type, role_name: TestRoleName, user: @user2
    # Admin::UserRole.create! current_admin: @admin, app_type: @user.app_type, role_name: OtherRoleName, user: @user1

    res = Admin::UserAccessControl.where(app_type: @user1.app_type, resource_type: :table, resource_name: :player_infos)
    res.update_all disabled: true


    res = @user1.has_access_to? :access, :table, :player_infos
    expect(res).to be_falsey

    res = @user2.has_access_to? :access, :table, :player_infos
    expect(res).to be_falsey

    # Create a role based access control
    uac_other_role = Admin::UserAccessControl.create! app_type_id: @user1.app_type_id, access: :create, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                            role_name: OtherRoleName

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user4.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey


    # The next role will enable @user2 and will be overriden by other_test_role for @user1 (based on alphanumeric sorting)

    # Create a role based access control
    uac_test_role = Admin::UserAccessControl.create! app_type_id: @user1.app_type_id, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                            role_name: TestRoleName

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    # User 2 can read but not create
    res = @user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    # A user specific setting will override everything
    @user = @user2
    let_user_create_player_infos

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy


    # User 3 has no access
    res = @user3.has_access_to? :access, :table, :player_infos
    expect(res).to be_falsey

    # A user specific setting will override everything
    @user = @user3
    let_user_create_player_infos

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    uac_other_role.update! disabled: true, current_admin: @admin

    uac_test_role.update! current_admin: @admin, access: :create

    uac_user = Admin::UserAccessControl.where(app_type: @user.app_type, resource_type: :table, resource_name: :player_infos, user_id: @user1.id).first
    uac_user&.update! current_admin: @admin, disabled: true

    uac_user = Admin::UserAccessControl.where(app_type: @user.app_type, resource_type: :table, resource_name: :player_infos, user_id: @user2.id).first
    uac_user.update! current_admin: @admin, disabled: true

    uac_user = Admin::UserAccessControl.where(app_type: @user.app_type, resource_type: :table, resource_name: :player_infos, user_id: @user3.id).first
    uac_user.update! current_admin: @admin, disabled: true

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    # Remove the role uac, so nobody can access
    uac_test_role.update! disabled: true, current_admin: @admin

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    # Create a basic - all access - uac
    all_access = Admin::UserAccessControl.create! app_type_id: @user1.app_type_id, access: :read, resource_type: :table, resource_name: :player_infos, current_admin: @admin
    res = @user1.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user2.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    # Now override with a role
    uac_test_role.update!(current_admin: @admin, disabled: false, access: :create)

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    # Ensure disabled user roles are ignored
    user_role1.update!(current_admin: @admin, disabled: true)

    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    res = @user2.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey

    # Reset the role to be enabled
    user_role1.update!(current_admin: @admin, disabled: false)


    # Restrict with a user
    Admin::UserAccessControl.create! current_admin: @admin, app_type: @user.app_type, user: @user2, access: nil, resource_type: :table, resource_name: :player_infos
    res = @user1.has_access_to? :create, :table, :player_infos
    expect(res).to be_truthy

    res = @user2.has_access_to? :access, :table, :player_infos
    expect(res).to be_falsey

    res = @user3.has_access_to? :read, :table, :player_infos
    expect(res).to be_truthy

    res = @user3.has_access_to? :create, :table, :player_infos
    expect(res).to be_falsey


  end

  # Check that a duplicate role can't be created
  it "prevents duplicate role entries being defined" do
    create_admin
    create_user

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :create, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                            role_name: TestRoleName

    expect {
      Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: nil, resource_type: :table, resource_name: :player_infos, current_admin: @admin,
                                              role_name: TestRoleName
    }.to raise_error ActiveRecord::RecordInvalid

  end

end
