require 'rails_helper'

AlNameGenTestUr = 'Gen Test ELT Save'

RSpec.describe SaveTriggers::UpdateReference, type: :model do
  include ModelSupport
  include ActivityLogSupport

  describe 'updating a referenced model from an activity log' do
    before :example do
      SetupHelper.setup_al_player_contact_phones
      SetupHelper.setup_al_gen_tests AlNameGenTestUr, 'elt_save_test', 'player_contact'
      create_user
      @master = create_master
      @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
      @al = create_item master: @master
      add_reference_def_to(@al, [player_contacts: { from: 'this', add: 'many' }])
      expect(@al.master_id).to eq @master.id
      setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
    end

    it 'updates a record after saving the current one' do
      pn_first = random_phone_number
      pn = random_phone_number

      ei = @al.create_embedded_item({ rank: 10, data: pn_first, rec_type: :phone })
      expect(ei).to be_a PlayerContact

      config = {
        player_contact: {
          first: {
            player_contacts: {
              update: 'return_result'
            }
          },
          in: 'this',
          with: { data: pn, rec_type: :phone, rank: 5 }
        }
      }
      @trigger = SaveTriggers::UpdateReference.new(config, @al)
      @trigger.perform

      pc = PlayerContact.find_by(data: pn)
      expect(pc).not_to be nil
      expect(@al.model_references(force_reload: true).last.to_record).to eq pc
      expect(@al.save_trigger_results['updated_items'].last).to eq pc
    end
  end

  describe 'updating a referenced activity log from an activity log' do
    before :context do
      SetupHelper.setup_al_gen_tests 'Gen Test ELT', 'elt', 'player_contact'
    end

    before :example do
      al_name = 'Gen Test ELT'

      create_admin
      create_user
      @master = create_master

      setup_access :player_contacts, user: @user
      setup_access :addresses, user: @user
      setup_access :activity_log__player_contact_phones, user: @user

      @activity_log = al = ActivityLog.active.where(name: al_name).first
      @working_data = '(111)222-3333 ext 12312312'
      @working_data2 = '(111)222-3333 ext 7654321'

      raise "Activity Log #{al_name} not set up" if al.nil?

      al.extra_log_types = <<~END_DEF
        mr_ref_pc:
          label: Reference Player Contact
          fields:
            - select_call_direction
            - select_who
          references:
            player_contacts:
              from: this
              add: one_to_this

        mr_ref_al:
          label: Reference Activity Log
          fields:
            - select_call_direction
            - select_who
            - disabled
          editable_if:
            always: true
          references:
            activity_log__player_contact_elt:
              from: this
              add: one_to_this
              also_disable_record: true
              filter_by:
                extra_log_type: 'mr_ref_pc'
              add_with:
                extra_log_type: 'mr_ref_pc'

          save_trigger:
            on_update:
              update_reference:
                activity_log__player_contact_elt:
                  first:
                    activity_log__player_contact_elts:
                      extra_log_type: mr_ref_pc
                      update: return_result

                  with:
                    embedded_item:
                      data: '#{@working_data}'
                      rec_type: phone
                      rank: 5
                  force_not_editable_save: true

        mr_ref_al2:
          label: Reference Activity Log 2
          fields:
            - select_call_direction
            - select_who
            - disabled
          editable_if:
            always: true
          references:
            activity_log__player_contact_elt:
              from: this
              add: one_to_this
              also_disable_record: true
              filter_by:
                extra_log_type: 'mr_ref_pc'
              add_with:
                extra_log_type: 'mr_ref_pc'

          save_trigger:
            on_update:
              update_reference:
                - activity_log__player_contact_elt:
                    first:
                      activity_log__player_contact_elts:
                        extra_log_type: mr_ref_pc
                        update: return_result
                    with:
                      embedded_item:
                        rank: 10
                    with_result:
                      from:
                        player_contacts:
                          data: '#{@working_data2}'
                          return: return_result
                      attributes:
                        embedded_item:
                          data: data
                          rec_type: rec_type
                    force_not_editable_save: true

      END_DEF

      al.current_admin = @admin
      al.save!
      al = @activity_log

      setup_access al.resource_name, resource_type: :table, user: @user

      setup_option_config 0, 'Reference Player Contact', %w[select_call_direction select_who]
      setup_option_config 1, 'Reference Activity Log', %w[select_call_direction select_who disabled]
      setup_option_config 2, 'Reference Activity Log 2', %w[select_call_direction select_who disabled]
    end

    it 'updates an embedded_item when creating another record' do
      pn_first = random_phone_number
      pn = random_phone_number
      pn2 = random_phone_number

      pc_hash = {
        rec_type: :phone,
        rank: 10,
        data: pn
      }

      pc_hash_1 = {
        rec_type: :phone,
        rank: 5,
        data: @working_data
      }

      pc_hash_2 = {
        rec_type: :phone,
        rank: 5,
        data: @working_data2
      }

      al_hash = { select_call_direction: 'from staff',
                  extra_log_type: 'mr_ref_pc',
                  select_who: 'abc',
                  master_id: @master.id }

      # Check we can create the basic activity log
      al_pc = ActivityLog::PlayerContactElt.new(select_call_direction: 'from staff',
                                                extra_log_type: 'mr_ref_pc',
                                                select_who: 'abc',
                                                master: @master)

      al_pc.save!
      ei = al_pc.create_embedded_item({ rank: 10, data: pn_first, rec_type: :phone })
      expect(ei).to be_a PlayerContact

      al_pc.update_embedded_item(pc_hash)
      pc = PlayerContact.find_by(pc_hash)
      expect(pc).not_to be nil

      al_pc.clear_embedded_item_memo
      expect(al_pc.embedded_item).to eq pc

      # Now create the activity log with create_reference defined
      al_cr = ActivityLog::PlayerContactElt.new(select_call_direction: 'from staff',
                                                extra_log_type: 'mr_ref_al',
                                                select_who: 'abc',
                                                master: @master)
      al_cr.save!

      expect(ActivityLog::PlayerContactElt.find_by(al_hash)).to eq al_pc
      al_pc.clear_embedded_item_memo
      ei = al_pc.embedded_item

      # Update the activity log to fire the save_trigger on_update
      al_cr.update!(select_who: 'def')
      pc2 = PlayerContact.find_by(pc_hash_1)
      expect(pc2).not_to be nil
      expect(al_pc.embedded_item).to eq pc2

      # Now create the activity log with create_reference with_result defined
      @master.player_contacts.create!(pc_hash_2)

      al_cr = ActivityLog::PlayerContactElt.new(select_call_direction: 'from staff',
                                                extra_log_type: 'mr_ref_al2',
                                                select_who: 'abc',
                                                master: @master)
      al_cr.save!

      expect(ActivityLog::PlayerContactElt.find_by(al_hash)).to eq al_pc

      # Update the activity log to fire the save_trigger on_update
      al_cr.update!(select_who: 'def')

      pc2 = PlayerContact.find_by(pc_hash_2.merge(rank: 10))
      expect(pc2).not_to be nil
      al_pc.clear_embedded_item_memo
      expect(al_pc.embedded_item).to eq pc2
    end
  end
end
