# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export an app configuration', type: :model do
  include MasterSupport
  include ModelSupport

  before :each do
    Seeds.setup

    create_admin
    create_user
    SetupHelper.setup_al_player_contact_phones

    apps = Admin::AppType.active.where("name = 'test1' or label = 'Test App 12' or name = 'new_name'")
    apps.each do |a|
      a.disabled = true
      a.current_admin = @admin
      a.save!
    end

    @app_type = Admin::AppType.active.where(name: 'test1').first
    @app_type ||= Admin::AppType.create!(name: 'test1', label: 'Test App 12', current_admin: @admin)

    # Allow all users access to the app
    Admin::UserAccessControl.create! app_type: @app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin

    # Set the user to use the app
    @user.app_type = @app_type
    @user.save!

    uac = nil
    # Make some items creatable
    %i[player_infos player_contacts scantrons].each do |rn|
      uac = Admin::UserAccessControl.active.where(app_type: @app_type, resource_type: :table, resource_name: rn).first
      uac ||= Admin::UserAccessControl.new(app_type: @app_type, resource_type: :table, resource_name: rn)
      uac.access = :create
      uac.current_admin = @admin
      uac.save!
    end

    # Set a user specific control on sage_assignments
    uac = Admin::UserAccessControl.active.where(app_type: @app_type, resource_type: :table, resource_name: :sage_assignments).first
    uac ||= Admin::UserAccessControl.new(app_type: @app_type, resource_type: :table, resource_name: :sage_assignments)
    uac.access = :read
    uac.user = @user
    uac.current_admin = @admin
    uac.save!

    # Set some app configurations
    add_app_config @app_type, 'create master with', 'player_info'
    add_app_config @app_type, 'hide pro info', 'true', user: @user
    add_app_config @app_type, 'menu research label', 'val1', role_name: 'role 1'

    # Set access to an activity log
    @activity_log = ActivityLog.active.first
    uac = Admin::UserAccessControl.active.where(app_type: @app_type, resource_type: :table, resource_name: @activity_log.full_item_type_name.pluralize).first
    if uac
      uac.access = :create
      uac.current_admin = @admin
      uac.save!
    else
      Admin::UserAccessControl.create! app_type: @app_type, access: :create, resource_type: :table, resource_name: @activity_log.full_item_type_name.pluralize, current_admin: @admin
    end

    @app_type.user_access_controls.reload
    @app_type.app_configurations.reload
  end

  def import_test_app
    @app_name = app_name = "bhs_model_#{$STARTED_AT}"

    @admin, = create_admin unless @admin
    # Setup the triggers, functions, etc

    eis = ExternalIdentifier.active.where(name: 'bhs_assignments').order(id: :desc)
    eis.where('id <> ?', eis.first&.id).update_all(disabled: true) if eis.count != 1

    i = ExternalIdentifier.active.where(name: 'bhs_assignments').order(id: :desc).first
    i&.update! disabled: false, min_id: 0, external_id_edit_pattern: nil, current_admin: @admin
    Master.reset_external_id_matching_fields!

    als = ActivityLog.active.where(name: 'BHS Tracker')
    als.where('id <> ?', als.first&.id).update_all(disabled: true) if als.count != 1

    config_dir = Rails.root.join('spec', 'fixtures', 'app_configs', 'config_files')
    config_fn = 'bhs_app_type_test_config.json'
    SetupHelper.setup_app_from_import app_name, config_dir, config_fn

    new_app_type = Admin::AppType.where(name: app_name).active.first
    Admin::UserAccessControl.active.where(app_type_id: new_app_type.id, resource_type: %i[external_id_assignments limited_access]).update_all(disabled: true)

    new_app_type
  end

  it 'exports a set of JSON' do
    res = @app_type.export_config

    expect(res).to be_a String

    res = JSON.parse(res)

    expect(res).to be_a Hash

    app = res['app_type']
    expect(app['name']).to eq @app_type.name
    expect(app['label']).to eq @app_type.label

    acs = app['app_configurations']
    expect(acs).to be_a Array
    config = acs.select { |a| a['name'] == 'hide pro info' }.first
    expect(config['user_email']).to eq @user.email
    expect(config['value']).to eq 'true'

    uac = app['valid_user_access_controls']
    expect(uac).to be_a Array
    config = uac.select { |a| a['resource_name'] == 'player_infos' }.first
    expect(config['resource_type']).to eq 'table'
    expect(config['access']).to eq 'create'
    expect(config['user_email']).to be_nil

    config = uac.select { |a| a['resource_name'] == 'sage_assignments' }.first
    expect(config['access']).to eq 'read'
    expect(config['user_email']).to eq @user.email

    uac = app['valid_associated_activity_logs']
    expect(uac).to be_a Array
    config = uac.select { |a| a['name'] == @activity_log.name }.first
    expect(config['item_type']).to eq @activity_log.item_type

    uac = app['associated_external_identifiers']
    expect(uac).to be_a Array
    config = uac.select { |a| a['name'] == 'scantrons' }.first
    expect(config['external_id_attribute']).to eq 'scantron_id'

    uac = app['associated_general_selections']
    expect(uac).to be_a Array
    config = uac.select { |a| a['item_type'] == 'player_infos_source' }
    expect(config).to be_a Array
    expect(config.map { |a| a['value'] }).to include 'nflpa'
  end

  it 'imports a JSON configuration' do
    config = @app_type.export_config

    @activity_log = ActivityLog.active.first

    al_orig_name = @activity_log.name
    @activity_log.name = "Changed #{rand}!"
    @activity_log.current_admin = @admin
    @activity_log.disabled = false
    @activity_log.save!

    res, results = Admin::AppTypeImport.import_config(config, @admin, name: 'new_name')

    expect(results).to be_a Hash

    expect(res).to be_a Admin::AppType

    expect(res.name).to eq 'new_name'
    expect(res.label).to eq 'Test App 12'

    acs = Admin::AppConfiguration.where app_type: res
    expect(acs.length).to eq 3

    ac = Admin::AppConfiguration.where(app_type: res, name: 'create master with').first
    expect(ac.value).to eq 'player_info'

    ac = Admin::AppConfiguration.where(app_type: res, name: 'hide pro info').first
    expect(ac.value).to eq 'true'
    expect(ac.user.id).to eq @user.id

    ac = Admin::AppConfiguration.where(app_type: res, name: 'menu research label').first
    expect(ac.value).to eq 'val1'
    expect(ac.user).to be nil
    expect(ac.role_name).to eq 'role 1'

    expect(@user.has_access_to?(:create, :table, :player_infos)).to be_truthy

    expect(@user.has_access_to?(:read, :table, :sage_assignments)).to be_truthy

    @activity_log.reload
    # expect(@activity_log.name).to eq al_orig_name
  end

  it 'imports a test JSON config file' do
    Seeds.setup

    res = import_test_app

    expect(res).to be_a Admin::AppType

    expect(res.name).to eq @app_name
    expect(res.label).to eq 'Brain Health Study'

    enable_user_app_access res.name, @user
    setup_access :player_infos

    @user.app_type = res
    @user.save!
    app_type = res
    expect(User.find(@user.id).app_type_id).to eq app_type.id
    expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: app_type.id))
    expect(@user.has_access_to?(:read, :table, :player_infos)).to be_truthy

    expect(ExternalIdentifier.where(name: 'bhs_assignments').first).to be_a ExternalIdentifier
    a = Admin::UserAccessControl.where app_type: app_type, resource_type: :table, resource_name: :bhs_assignments
    # The external identifier access can't be enabled if the underlying table doesn't exist.
    # The bhs table is created in other tests though
    expect(a.first).to be_a Admin::UserAccessControl
    al = ActivityLog.where(item_type: 'bhs_assignment').first
    expect(al).to be_a ActivityLog
    al.update(current_admin: @admin, disabled: false)
    a = Admin::UserAccessControl.where app_type: app_type, resource_type: :table, resource_name: :activity_log__bhs_assignments
    # The Activity log definition can not be enabled if its table does not exist
    # It is created in other tests though
    expect(a.first).to be_a Admin::UserAccessControl

    # expect(@user.has_access_to? :create, :table, :activity_log__bhs_assignments).to be_truthy
    # expect(@user.has_access_to? :create, :table, :bhs_assignments).to be_truthy
  end
end
