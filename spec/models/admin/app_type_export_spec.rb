# frozen_string_literal: true

# Tests for Admin::AppType export functionality.
# Verifies that export_config produces correct JSON including app configurations,
# user access controls, activity logs, external identifiers, general selections,
# and item flag names. Ensures exported item flag names are scoped to tables
# associated with the app type via user access controls.

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
    if i
      i.force_regenerate = true
      i.update! disabled: false, min_id: 0, external_id_edit_pattern: nil, current_admin: @admin
    end
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

  it 'exports only item flag names for tables associated with the app type' do
    # Create an item flag for a table that IS in the app type (player_infos has :create access)
    associated_flag = Classification::ItemFlagName.create!(
      name: "Associated Flag #{rand(1_000_000)}",
      item_type: 'player_info',
      current_admin: @admin
    )

    # Create an item flag for a table that is NOT in the app type
    unassociated_flag = Classification::ItemFlagName.create!(
      name: "Unassociated Flag #{rand(1_000_000)}",
      item_type: 'address',
      current_admin: @admin
    )

    res = JSON.parse(@app_type.export_config)
    app = res['app_type']
    exported_flags = app['associated_item_flag_names']

    expect(exported_flags).to be_a Array

    exported_names = exported_flags.map { |f| f['name'] }
    expect(exported_names).to include(associated_flag.name)
    expect(exported_names).not_to include(unassociated_flag.name)
  end
end
