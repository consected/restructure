require 'rails_helper'

AlNameGenTestCr = 'Gen Test ELT Save'

RSpec.describe SaveTriggers::CreateReference, type: :model do
  include ModelSupport
  include ActivityLogSupport

  def random_phone_number
    pn = "(617)123-1234 c#{rand 1_000_000_000}"
    pn = random_phone_number while PlayerContact.where(data: pn).count > 0
    pn
  end

  before :example do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests AlNameGenTestCr, 'elt_save_test', 'player_contact'
    create_user
    @master = create_master
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_item master: @master
    add_reference_def_to(@al, [player_contacts: { from: 'this', add: 'many' }])
    expect(@al.master_id).to eq @master.id
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
  end

  it 'creates a record after saving the current one' do
    pn = random_phone_number

    config = {
      player_contact: {
        in: 'this',
        with: { data: pn, rec_type: :phone, rank: 5 }
      }
    }
    @trigger = SaveTriggers::CreateReference.new(config, @al)
    @trigger.perform

    pc = PlayerContact.find_by(data: pn)
    expect(pc).not_to be nil
    expect(@al.model_references(force_reload: true).last.to_record).to eq pc
  end

  it 'creates a record using "force_create" even if the current user does not have access to create it' do
    pn = random_phone_number

    # Prevent user from being able to create player contact records
    uac = @user.has_access_to? :access, :table, :player_contacts
    uac.update! current_admin: @admin, user: @user, access: nil,
                resource_type: :table, resource_name: :player_contacts

    uac = @user.has_access_to? :access, :table, :player_contacts, force_reset: true
    expect(uac).to be nil

    config = {
      player_contact: {
        in: 'this',
        with: { data: pn, rec_type: :phone, rank: 5 }
      }
    }
    @trigger = SaveTriggers::CreateReference.new(config, @al)
    expect { @trigger.perform }.to raise_error FphsException

    pn = random_phone_number

    config = {
      player_contact: {
        in: 'this',
        with: { data: pn, rec_type: :phone, rank: 5 },
        force_create: true
      }
    }
    @trigger = SaveTriggers::CreateReference.new(config, @al)
    @trigger.perform
    pc = PlayerContact.find_by(data: pn)
    expect(pc).not_to be nil
    expect(@al.model_references(force_reload: true).last.to_record).to eq pc
  end

  it 'creates a reference to an existing record without creating a new record' do
    pn = random_phone_number

    pc_orig = @al.master.player_contacts.create! data: pn, rec_type: :phone, rank: 5

    config = {
      player_contact: {
        in: 'this',
        to_existing_record: {
          record_id: {
            player_contacts: { rank: 5, id: 'return_value' }
          }
        }
      }
    }
    @trigger = SaveTriggers::CreateReference.new(config, @al)
    @trigger.perform

    pc = PlayerContact.find_by(data: pn)
    expect(pc).not_to be nil
    expect(@al.model_references(force_reload: true).last.to_record).to eq pc
    expect(pc_orig.id).to eq pc.id
  end
end
