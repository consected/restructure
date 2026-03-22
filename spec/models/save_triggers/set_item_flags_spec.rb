require 'rails_helper'

AlNameGenTestCr = 'Gen Test ELT Save'

RSpec.describe SaveTriggers::SetItemFlags, type: :model do
  include ModelSupport
  include ActivityLogSupport

  before :example do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests AlNameGenTestCr, 'elt_save_test', 'player_contact'
    create_user
    @master = create_master
    setup_access PlayerInfo.resource_name, resource_type: :table, access: :create, user: @user
    @player_info = @master.player_infos.create! first_name: 'bob', last_name: 'smith', rank: 10, birth_date: '2000-02-01', source: 'nflpa'
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_item master: @master
    add_reference_def_to(@al, [player_contacts: { from: 'this', add: 'many' }])
    expect(@al.master_id).to eq @master.id
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
    Classification::Protocol.reset_record_updates_protocol!
  end

  it 'sets flags on an item using a list of ids' do
    flag_list = Classification::ItemFlagName.available_to_item(@player_info).ids[1..2]

    expect(flag_list).not_to be nil

    config = {
      first: {
        player_infos: { update: 'return_result' }
      },
      flags: flag_list,
      force_not_editable_save: true
    }
    @trigger = SaveTriggers::SetItemFlags.new(config, @al)
    @trigger.perform

    pi = @al.master.player_infos.first
    expect(pi).not_to be nil
    expect(pi.item_flags.pluck(:item_flag_name_id)).to eq flag_list
  end

  it 'sets flags on an item using a list of names' do
    flag_list = Classification::ItemFlagName.available_to_item(@player_info).pluck(:name)[1..2]

    expect(flag_list).not_to be nil

    config = {
      first: {
        player_infos: { update: 'return_result' }
      },
      flags: flag_list,
      force_not_editable_save: true
    }
    @trigger = SaveTriggers::SetItemFlags.new(config, @al)
    @trigger.perform

    pi = @al.master.player_infos.first
    expect(pi).not_to be nil
    expect(Classification::ItemFlagName.active.where(id: pi.item_flags.pluck(:item_flag_name_id)).pluck(:name)).to eq flag_list
  end

  it 'sets add new and removes existing flags for the existing set' do
    # Setup the initial list
    flag_list = Classification::ItemFlagName.available_to_item(@player_info).pluck(:name)[1..2]

    expect(flag_list).not_to be nil

    config = {
      first: {
        player_infos: { update: 'return_result' }
      },
      flags: flag_list,
      force_not_editable_save: true
    }
    @trigger = SaveTriggers::SetItemFlags.new(config, @al)
    @trigger.perform

    pi = @al.master.player_infos.first
    expect(pi).not_to be nil
    expect(Classification::ItemFlagName.active.where(id: pi.item_flags.pluck(:item_flag_name_id)).pluck(:name)).to eq flag_list

    # Now add a flag
    flag_list = Classification::ItemFlagName.available_to_item(@player_info).pluck(:name)[0..2]

    expect(flag_list).not_to be nil

    config = {
      first: {
        player_infos: { update: 'return_result' }
      },
      add_flags: [flag_list[0]],
      remove_flags: [flag_list[1]],
      force_not_editable_save: true
    }
    @trigger = SaveTriggers::SetItemFlags.new(config, @al)
    @trigger.perform

    exp_flag_list = [flag_list[0], flag_list[2]]

    pi = @al.master.player_infos.first
    expect(pi).not_to be nil
    expect(Classification::ItemFlagName.active.where(id: pi.item_flags.pluck(:item_flag_name_id)).pluck(:name)).to eq exp_flag_list
  end
end
