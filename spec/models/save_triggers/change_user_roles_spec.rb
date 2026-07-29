require 'rails_helper'

AlNameGenTestCur = 'Gen Test ELT Save'

RSpec.describe SaveTriggers::ChangeUserRoles, type: :model do
  include ModelSupport
  include ActivityLogSupport

  before :example do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests AlNameGenTestCur, 'elt_save_test', 'player_contact'
    create_user
    @master = create_master
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_item master: @master
    expect(@al.master_id).to eq @master.id
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
  end

  it 'changes the roles of the current user' do
    config = {
      add_role_names: ['viewer-has-agreement'],
      remove_role_names: ['viewer-no-agreement']
    }

    res = @user.user_roles.pluck(:role_name)
    expect(res).to be_empty

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement'])

    config = {
      add_role_names: ['viewer-has-agreement2'],
      remove_role_names: ['viewer-no-agreement']
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement', 'viewer-has-agreement2'])

    config = {
      remove_role_names: ['viewer-has-agreement']
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement2'])
  end

  it 'changes the roles of the current user in another app' do
    @orig_app_type = @user.app_type
    @alt_app_type = Admin::AppType.active_app_types(force: true).last
    expect(@alt_app_type.id).not_to eq @user.app_type_id

    Admin::UserAccessControl.create app_type: @alt_app_type, role_name: 'user', resource_type: 'general', resource_name: 'app_type', access: 'read', current_admin: @admin

    config = {
      add_role_names: [
        { role_name: 'viewer-has-agreement', app_type: @user.app_type.name },
        { role_name: 'user', app_type: @alt_app_type.name }
      ],
      remove_role_names: ['viewer-no-agreement']
    }

    res = @user.user_roles.pluck(:role_name)
    expect(res).to be_empty
    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement'])

    @user.app_type = @alt_app_type
    @user.save!

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['user'])

    @user.app_type = @orig_app_type
    @user.save!

    config = {
      add_role_names: ['viewer-has-agreement2'],
      remove_role_names: [
        { role_name: 'viewer-no-agreement', app_type: @user.app_type.name }
      ]
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name).sort).to eq(['viewer-has-agreement', 'viewer-has-agreement2'].sort)

    config = {
      remove_role_names: ['viewer-has-agreement']
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement2'])
  end

  it 'changes the roles of the current user in another app specified by app_type id' do
    @orig_app_type = @user.app_type
    @alt_app_type = Admin::AppType.active_app_types(force: true).last
    expect(@alt_app_type.id).not_to eq @user.app_type_id

    Admin::UserAccessControl.create app_type: @alt_app_type, role_name: 'user', resource_type: 'general', resource_name: 'app_type', access: 'read', current_admin: @admin

    config = {
      add_role_names: [
        { role_name: 'viewer-has-agreement', app_type: @user.app_type.id },
        { role_name: 'user', app_type: @alt_app_type.id }
      ],
      remove_role_names: ['viewer-no-agreement']
    }

    res = @user.user_roles.pluck(:role_name)
    expect(res).to be_empty
    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement'])

    @user.app_type = @alt_app_type
    @user.save!

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['user'])

    @user.app_type = @orig_app_type
    @user.save!
  end

  it 'changes the roles of the current user in another app specified by a conditional Hash app_type reference - issue #1318' do
    # notes is reused here purely as a string field a conditional Hash reference
    # ({this: {field: return_value}}) can read back; it is not semantically related to protocols.
    # This proves app_type is resolved via FieldDefaults.calculate_default before use,
    # so a Hash config (in addition to a literal id/name) now works.
    @orig_app_type = @user.app_type
    @alt_app_type = Admin::AppType.active_app_types(force: true).last
    expect(@alt_app_type.id).not_to eq @user.app_type_id

    Admin::UserAccessControl.create app_type: @alt_app_type, role_name: 'user', resource_type: 'general', resource_name: 'app_type', access: 'read', current_admin: @admin

    @al.update!(notes: @alt_app_type.name)

    config = {
      add_role_names: [
        { role_name: 'user', app_type: { this: { notes: 'return_value' } } }
      ]
    }

    res = @user.user_roles.pluck(:role_name)
    expect(res).to be_empty
    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(@user.user_roles.active.reload.pluck(:role_name)).to be_empty

    @user.app_type = @alt_app_type
    @user.save!

    expect(@user.user_roles.active.reload.pluck(:role_name)).to eq(['user'])

    @user.app_type = @orig_app_type
    @user.save!
  end

  it 'does not resolve a config app_type outside the app types loaded on this server (OnlyLoadAppTypes) - issue #1318' do
    @alt_app_type = Admin::AppType.active_app_types(force: true).last
    expect(@alt_app_type.id).not_to eq @user.app_type_id

    # Restrict the server to only load @user's app type, excluding @alt_app_type.
    stub_const('Settings::OnlyLoadAppTypes', [@user.app_type_id])
    Admin::AppType.reset_active_app_types!

    config = {
      add_role_names: [
        { role_name: 'user', app_type: @alt_app_type.id }
      ]
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    # @alt_app_type exists and is active, but is excluded from this server's
    # OnlyLoadAppTypes scope, so it must not be resolvable.
    expect { @trigger.perform }.to raise_error(ActiveRecord::RecordNotFound)
  ensure
    Admin::AppType.reset_active_app_types!
  end

  it 'changes the roles of the specified user' do
    @orig_app_type = @user.app_type
    @alt_app_type = Admin::AppType.active_app_types(force: true).last
    expect(@alt_app_type.id).not_to eq @user.app_type_id

    Admin::UserAccessControl.create app_type: @alt_app_type, role_name: 'user', resource_type: 'general', resource_name: 'app_type', access: 'read', current_admin: @admin

    # Ensure we are using a user that is not the current_user
    other_user = @user
    create_user

    config = {
      add_role_names: [
        {
          role_name: 'viewer-has-agreement',
          app_type: other_user.app_type.name,
          for_user: other_user.email
        },
        {
          role_name: 'user',
          app_type: @alt_app_type.name,
          for_user: {
            all: {
              @al.class.resource_name => {
                id: @al.id,
                user_id: 'return_value'
              }
            }

          }

        }
      ],
      remove_role_names: ['viewer-no-agreement']
    }

    res = other_user.user_roles.pluck(:role_name)
    expect(res).to be_empty
    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(other_user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement'])

    other_user.app_type = @alt_app_type
    other_user.save!

    expect(other_user.user_roles.active.reload.pluck(:role_name)).to eq(['user'])

    other_user.app_type = @orig_app_type
    other_user.save!

    config = {
      add_role_names: ['viewer-has-agreement2'],
      remove_role_names: [
        { role_name: 'viewer-no-agreement', app_type: other_user.app_type.name }
      ]
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(other_user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement', 'viewer-has-agreement2'])

    config = {
      remove_role_names: ['viewer-has-agreement']
    }

    @trigger = SaveTriggers::ChangeUserRoles.new(config, @al)
    @trigger.perform

    expect(other_user.user_roles.active.reload.pluck(:role_name)).to eq(['viewer-has-agreement2'])
  end
end
