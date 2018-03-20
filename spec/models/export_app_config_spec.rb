require 'rails_helper'

RSpec.describe "Export an app configuration", type: :model do

  include ModelSupport

  before :all do
    seed_database
    ::ActivityLog.define_models
    create_admin
    create_user

    apps = AppType.active.where("name = 'test1' or label = 'Test App 12' or name = 'new_name'")
    apps.each do |a|
      a.disabled = true
      a.current_admin = @admin
      a.save!
    end

    @app_type = AppType.create!(name: 'test1', label:'Test App 12', current_admin: @admin)

    # Allow all users access to the app
    UserAccessControl.create! app_type: @app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin

    # Set the user to use the app
    @user.app_type = @app_type
    @user.save!


    uac = nil
    # Make some items creatable
    [:player_infos, :player_contacts, :scantrons].each do |rn|
      uac = UserAccessControl.active.where(app_type: @app_type, resource_type: :table, resource_name: rn).first
      uac.access = :create
      uac.current_admin = @admin
      uac.save!
    end

    # Set a user specific control on sage_assignments
    uac = UserAccessControl.active.where(app_type: @app_type, resource_type: :table, resource_name: :sage_assignments).first
    uac.access = :read
    uac.user = @user
    uac.current_admin = @admin
    uac.save!


    # Set some app configurations
    unless @app_type.app_configurations.active.where(name: 'create master with').first
      AppConfiguration.create!(app_type: @app_type, name: 'create master with', value: 'player_info', current_admin: @admin)
    end
    unless @app_type.app_configurations.active.where(name: 'hide pro info', user: @user).first
      AppConfiguration.create!(app_type: @app_type, name: 'hide pro info', value: 'true', user: @user, current_admin: @admin)
    end

    # Set access to an activity log
    @activity_log = ActivityLog.active.first
    uac = UserAccessControl.active.where(app_type: @app_type, resource_type: :table, resource_name: @activity_log.full_item_type_name.pluralize).first
    if uac
      uac.access = :create
      uac.current_admin = @admin
      uac.save!
    else
      UserAccessControl.create! app_type: @app_type, access: :create, resource_type: :table, resource_name: @activity_log.full_item_type_name.pluralize, current_admin: @admin
    end




    @app_type.user_access_controls.reload
    @app_type.app_configurations.reload


  end

  it "exports a set of JSON" do

    res = @app_type.export_config

    expect(res).to be_a String

    res = JSON.parse(res)

    expect(res).to be_a Hash

    app = res['app_type']
    expect(app['name']).to eq @app_type.name
    expect(app['label']).to eq @app_type.label

    acs = app['app_configurations']
    expect(acs).to be_a Array
    config = acs.select {|a| a['name'] == 'hide pro info'}.first
    expect(config['user_email']).to eq @user.email
    expect(config['value']).to eq 'true'

    uac = app['user_access_controls']
    expect(uac).to be_a Array
    config = uac.select {|a| a['resource_name'] == 'player_infos'}.first
    expect(config['resource_type']).to eq 'table'
    expect(config['access']).to eq 'create'
    expect(config['user_email']).to be_nil

    config = uac.select {|a| a['resource_name'] == 'sage_assignments'}.first
    expect(config['access']).to eq 'read'
    expect(config['user_email']).to eq @user.email

    uac = app['associated_activity_logs']
    expect(uac).to be_a Array
    config = uac.select {|a| a['name'] == @activity_log.name}.first
    expect(config['item_type']).to eq @activity_log.item_type

    uac = app['associated_external_identifiers']
    expect(uac).to be_a Array
    config = uac.select {|a| a['name'] == 'scantrons'}.first
    expect(config['external_id_attribute']).to eq 'scantron_id'

    uac = app['associated_general_selections']
    expect(uac).to be_a Array
    config = uac.select {|a| a['item_type'] == 'player_infos_source'}
    expect(config).to be_a Array
    expect(config.map {|a| a['value']}).to include 'nflpa'



  end

  it "imports a JSON configuration" do

    config = @app_type.export_config


    al_orig_name = @activity_log.name
    @activity_log.name = 'Changed!'
    @activity_log.current_admin = @admin
    @activity_log.save!

    res, results = AppType.import_config(config, @admin, name: 'new_name')

    expect(results).to be_a Hash

    expect(res).to be_a AppType

    expect(res.name).to eq 'new_name'
    expect(res.label).to eq 'Test App 12'

    acs = AppConfiguration.where app_type: res
    expect(acs.length).to eq 2

    ac = AppConfiguration.where(app_type: res, name: 'create master with').first
    expect(ac.value).to eq 'player_info'

    ac = AppConfiguration.where(app_type: res, name: 'hide pro info').first
    expect(ac.value).to eq 'true'
    expect(ac.user.id).to eq @user.id

    expect(@user.has_access_to? :create, :table, :player_infos).to be_truthy

    expect(@user.has_access_to? :read, :table, :sage_assignments).to be_truthy

    @activity_log.reload
    expect(@activity_log.name).to eq al_orig_name



  end

  it "imports a test JSON config file" do
    config = File.read Rails.root.join('docs/config_tests/bhs_app_type_test_config.json')

    res, results = AppType.import_config(config, @admin)

    expect(res).to be_a AppType

    expect(res.name).to eq 'bhs'
    expect(res.label).to eq 'Brain Health Study'

    expect(@user.has_access_to? :create, :table, :player_infos).to be_truthy

    # The external identifier access can't be enabled, since the underlying table doesn't exist
    expect(ExternalIdentifier.where(name: 'bhs_assignments').first).to be_a ExternalIdentifier
    a = UserAccessControl.where app_type: @app_type, resource_type: :table, resource_name: :bhs_assignments
    expect(a.first).to be_nil

    # Activity log definition can not be enabled, since its table does not exist
    expect(ActivityLog.where(item_type: 'bhs_assignment').first).to be_a ActivityLog
    a = UserAccessControl.where app_type: @app_type, resource_type: :table, resource_name: :activity_log__bhs_assignments
    expect(a.first).to be_nil

    # expect(@user.has_access_to? :create, :table, :activity_log__bhs_assignments).to be_truthy
    # expect(@user.has_access_to? :create, :table, :bhs_assignments).to be_truthy


  end

end
