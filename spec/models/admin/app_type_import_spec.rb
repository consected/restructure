# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import an app configuration', type: :model do
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

  it 'imports config libraries that reference other config libraries' do
    # Create config library A (base library)
    lib_a_options = <<~YAML
      _definitions:
        base_field: &base_field
          label: Base Field
          field_type: text
    YAML

    # Create config library B that references library A
    lib_b_options = <<~YAML
      # @library test_refs lib_a
      _definitions:
        extended_field: &extended_field
          <<: *base_field
          label: Extended Field
    YAML

    # Build a test config that includes both libraries
    test_config = {
      app_type: {
        name: 'imported_lib_refs',
        label: 'Test Lib Refs',
        associated_config_libraries: [
          {
            name: 'lib_b',
            category: 'test_refs',
            format: 'yaml',
            options: lib_b_options,
            updated_at: (Time.now - 1.hour).iso8601
          },
          {
            name: 'lib_a',
            category: 'test_refs',
            format: 'yaml',
            options: lib_a_options,
            updated_at: Time.now.iso8601
          }
        ]
      }
    }.to_json

    # Import the configuration
    res, results = Admin::AppTypeImport.import_config(
      test_config,
      @admin
    )

    expect(results).to be_a Hash
    expect(res).to be_a Admin::AppType
    expect(res.name).to eq 'imported_lib_refs'

    # Verify both config libraries were imported successfully
    imported_lib_a = Admin::ConfigLibrary.active.find_by(name: 'lib_a', category: 'test_refs')
    expect(imported_lib_a).to be_present
    expect(imported_lib_a.options).to include('base_field')

    imported_lib_b = Admin::ConfigLibrary.active.find_by(name: 'lib_b', category: 'test_refs')
    expect(imported_lib_b).to be_present
    expect(imported_lib_b.options).to include('# @library test_refs lib_a')
    expect(imported_lib_b.options).to include('extended_field')

    # Verify the referenced library can be loaded without error
    expect do
      Admin::ConfigLibrary.content_named('test_refs', 'lib_a', format: 'yaml')
    end.not_to raise_error

    # Cleanup
    res.update(disabled: true, current_admin: @admin)
    imported_lib_a.update(disabled: true, current_admin: @admin)
    imported_lib_b.update(disabled: true, current_admin: @admin)
  end

  it 'handles import with skip_fail when config libraries reference missing libraries on first pass' do
    # Create config library B that references library Z (which will be imported after B due to ordering)
    lib_b_options = <<~YAML
      # @library test_skip lib_z
      _definitions:
        extended_field: &extended_field
          <<: *base_field
          label: Extended Field
    YAML

    # Create config library Z (base library) with later timestamp
    lib_z_options = <<~YAML
      _definitions:
        base_field: &base_field
          label: Base Field
          field_type: text
    YAML

    # Build a test config that includes both libraries
    # lib_b is listed first (due to older timestamp) but references lib_z
    test_config = {
      app_type: {
        name: 'imported_skip_fail_libs',
        label: 'Test Skip Fail Libs',
        associated_config_libraries: [
          {
            name: 'lib_b',
            category: 'test_skip',
            format: 'yaml',
            options: lib_b_options,
            updated_at: (Time.now - 1.hour).iso8601
          },
          {
            name: 'lib_z',
            category: 'test_skip',
            format: 'yaml',
            options: lib_z_options,
            updated_at: Time.now.iso8601
          }
        ]
      }
    }.to_json

    # Import the configuration - should succeed even though lib_b references lib_z
    # which may not exist on first pass
    res, results = Admin::AppTypeImport.import_config(
      test_config,
      @admin,
      skip_fail: false
    )

    expect(results).to be_a Hash
    expect(res).to be_a Admin::AppType
    expect(res.name).to eq 'imported_skip_fail_libs'

    # Verify both config libraries were imported
    imported_lib_b = Admin::ConfigLibrary.active.find_by(name: 'lib_b', category: 'test_skip')
    expect(imported_lib_b).to be_present
    expect(imported_lib_b.options).to include('# @library test_skip lib_z')

    imported_lib_z = Admin::ConfigLibrary.active.find_by(name: 'lib_z', category: 'test_skip')
    expect(imported_lib_z).to be_present
    expect(imported_lib_z.options).to include('base_field')

    # Cleanup
    res.update(disabled: true, current_admin: @admin)
    imported_lib_b.update(disabled: true, current_admin: @admin)
    imported_lib_z.update(disabled: true, current_admin: @admin)
  end
end
