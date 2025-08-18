require 'rails_helper'

AlNameGenTestCr = 'Gen Test ELT Save'

RSpec.describe SaveTriggers::CreateMaster, type: :model do
  include ModelSupport
  include ActivityLogSupport

  def last_msid
    last_msid = (Master.order(msid: :desc).first.msid || 123) + 1
  end

  def add_embedded_item
    pn = random_phone_number
    pc_hash = {
      rec_type: :phone,
      rank: 10,
      data: pn
    }
    @al.create_embedded_item(pc_hash)
  end

  describe 'activity logs with player contact referenced' do
    before :example do
      SetupHelper.setup_al_player_contact_phones
      SetupHelper.setup_al_gen_tests AlNameGenTestCr, 'elt_save_test', 'player_contact'
      create_user
      @master = create_master
      @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
      @al = create_item master: @master
      add_reference_def_to(@al, [player_contacts: { from: 'this', add: 'one_to_this' }])
      expect(@al.master_id).to eq @master.id
      setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
    end

    it 'creates a master record after saving the current one' do
      config = {
        with: { msid: last_msid }
      }
      @trigger = SaveTriggers::CreateMaster.new(config, @al)
      @trigger.perform

      new_master = @al.save_trigger_results['created_master']
      expect(@master.id).not_to eq new_master.id
      expect(Master.last).to eq new_master
    end

    it 'creates a master record and moves the current item and embedded item to the new master' do
      add_embedded_item
      config = {
        with: { msid: last_msid },
        move_this: true
      }
      @trigger = SaveTriggers::CreateMaster.new(config, @al)
      @trigger.perform

      new_master = @al.save_trigger_results['created_master']
      expect(@master.id).not_to eq new_master.id
      expect(Master.last).to eq new_master

      expect(@al.master_id).to eq new_master.id
      expect(@al.embedded_item.master_id).to eq new_master.id
    end
  end

  describe 'activity logs with player contact referenced' do
    before :example do
      SetupHelper.setup_al_player_contact_phones
      SetupHelper.setup_al_gen_tests AlNameGenTestCr, 'elt_save_test', 'player_contact'
      create_user
      @master = create_master
      @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
      @al = create_item master: @master
      add_reference_def_to(@al, [users: { from: 'this', add: 'one_to_this' }])
      expect(@al.master_id).to eq @master.id
      setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
    end
    it 'creates a master record and moves the current item and embedded item to the new master' do
      # Add a reference to the current user. The user has no master association, so works for this example
      ModelReference.create_with(@al, @user)

      config = {
        with: { msid: last_msid },
        move_this: true
      }
      @trigger = SaveTriggers::CreateMaster.new(config, @al)
      @trigger.perform

      new_master = @al.save_trigger_results['created_master']
      expect(@master.id).not_to eq new_master.id
      expect(Master.last).to eq new_master

      expect(@al.master_id).to eq new_master.id
    end
  end
end
