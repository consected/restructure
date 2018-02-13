require 'rails_helper'

RSpec.describe UserAccessControl, type: :model do

  include ModelSupport
  include PlayerInfoSupport

  it "should not create default access controls for a new user" do

    (1..3).each do
      create_user

      res = UserAccessControl.where(user_id: @user.id)
      expect(res.length).to eq 0
    end
  end

  it "should prevent a user from having multiple entries for the same named resource type" do

    app_type_id = AppType.active.first.id
    (1..3).each do
      create_user
      UserAccessControl.create user: @user, resource_type: :table, resource_name: 'player_infos', current_admin: @admin, app_type_id: app_type_id
      expect{
        UserAccessControl.create! user: @user, resource_type: :table, resource_name: 'player_infos', current_admin: @admin, app_type_id: app_type_id
      }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it "should create default access controls for a new app type" do

    create_admin
    (1..3).each do |i|
      a = AppType.create! name: "app#{i}", label: "app#{i}", current_admin: @admin

      res = UserAccessControl.where(app_type_id: a.id)
      expect(res.length).to eq UserAccessControl.resource_names_for(:table).length
    end
  end


  it "allows testing of a user's access to a resource" do

    create_user

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
    create_item

    @master.current_user = @user
    jres = @master.to_json
    res = JSON.parse jres
    puts jres
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
    create_item

    @master.current_user = @user
    res = @user.has_access_to? :access, :table, :player_infos
    res.access = :read
    res.current_admin = @admin
    res.save!

    expect {
      create_item
    }.to raise_error FphsException

  end


  it "allows a user's access to override the default" do

    create_admin
    create_user
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

    uac = UserAccessControl.create! app_type_id: @user.app_type_id, user_id: @user.id,  access: :update, resource_type: :table, resource_name: :player_infos, current_admin: @admin

    res = @user.has_access_to? :update, :table, :player_infos
    expect(res.id).to eq uac.id

    expect(@player_info.update(first_name: 'aaabbbccc')).to be_truthy

    uac.access = nil
    uac.save!

    res = @user.has_access_to? :access, :table, :player_infos
    expect(res).to be nil


    j = @player_info.to_json

    expect(j).to eq '{}'

  end
end
