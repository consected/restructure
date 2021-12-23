require 'rails_helper'

AlNameGenTest2 = 'Gen Test ELT 2'

RSpec.describe SaveTriggers::ChangeUserRoles, type: :model do
  include ModelSupport
  include ActivityLogSupport

  before :example do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests AlNameGenTest2, 'elt2_test', 'player_contact'
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
end
