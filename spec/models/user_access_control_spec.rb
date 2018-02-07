require 'rails_helper'

RSpec.describe UserAccessControl, type: :model do

  include ModelSupport
  include PlayerInfoSupport

  it "should create default access controls for a new user" do

    (1..3).each do
      create_user

      res = UserAccessControl.where(user_id: @user.id)
      expect(res.length).to eq UserAccessControl.resource_names.length
      expect(res.map(&:resource_name).uniq).to eq UserAccessControl.resource_names
    end
  end

  it "should prevent a user from having multiple entries for the same named resource type" do

    (1..3).each do
      create_user
      # Since creation of a user created all the resource entries, the following should fail
      expect{
        UserAccessControl.create! user: @user, resource_type: :table, resource_name: 'player_infos', current_admin: @admin
      }.to raise_error ActiveRecord::RecordInvalid
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
    puts jres
    res = JSON.parse jres
    expect(res['player_infos']).not_to be nil
    expect(res['player_infos'].first['id']).to eq id


  end

  it "prevents a user from accessing to a table" do

    create_admin
    create_user
    create_item

    # by default, a user is granted access to all tables

    res = @user.has_access_to? :access, :table, :player_infos
    res.access = nil
    res.current_admin = @admin
    res.save!

    res = @user.has_access_to? :access, :table, :player_infos
    expect(res).to be_falsey

    res = PlayerInfo.allows_user_access_to? @user, :access
    expect(res).to be_falsey


    id = @player_info.id

    # First, check at an individual master level
    @master.current_user = @user
    jres = @master.to_json
    puts jres
    res = JSON.parse jres
    expect(res['player_infos']).to be nil



  end

end
