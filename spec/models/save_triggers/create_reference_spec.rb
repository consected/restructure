require 'rails_helper'

AlNameGenTestCr = 'Gen Test ELT Save'

RSpec.describe SaveTriggers::CreateReference, type: :model do
  include ModelSupport
  include ActivityLogSupport

  describe 'creating a referenced model from an activity log' do
    before :example do
      SetupHelper.setup_al_player_contact_phones
      SetupHelper.setup_al_gen_tests AlNameGenTestCr, 'elt_save_test', 'player_contact'
      create_user
      @master = create_master
      @player_contact_prev = @master.player_contacts.create! data: '(617)123-1234 prev', rec_type: :phone, rank: 5, source: 'nflpa2'
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
      expect(@al.save_trigger_results['created_items'].last).to eq pc
    end

    it 'creates a record using "force_create" even if the current user does not have access to create it' do
      pn = random_phone_number

      # Prevent user from being able to create player contact records
      uac = @user.has_access_to? :access, :table, :player_contacts
      uac = Admin::UserAccessControl.find(uac.id)
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

    it 'creates a record in a master without a model reference' do
      pn = random_phone_number

      config = {
        player_contact: {
          in: 'master',
          with: { data: pn, rec_type: :phone, rank: 5 }
        }
      }
      @trigger = SaveTriggers::CreateReference.new(config, @al)
      @trigger.perform

      pc = PlayerContact.find_by(data: pn)
      expect(pc).not_to be nil
      expect(pc.master_id).to eq @al.master_id
      expect(ModelReference.last&.reload&.to_record_id).not_to eq pc.id
    end

    it 'creates a record in the previously created master' do
      pn = random_phone_number

      config = {
        if: { always: true }
      }
      @trigger = SaveTriggers::CreateMaster.new(config, @al)
      @trigger.perform

      new_master = @al.save_trigger_results['created_master']
      expect(new_master).not_to eq @al.master

      config = {
        player_contact: {
          in: 'master_with_reference',
          with: { data: pn, rec_type: :phone, rank: 5, master_id: '{{save_trigger_results.created_master.id}}' }
        }
      }
      @trigger = SaveTriggers::CreateReference.new(config, @al)
      @trigger.perform

      pc = PlayerContact.find_by(data: pn).reload
      expect(pc).not_to be nil
      expect(pc.master_id).to eq new_master.id

      mr = ModelReference.last&.reload
      expect(mr.to_record_id).to eq pc.id
      expect(mr.to_record_master_id).to eq pc.master_id
      expect(mr.from_record_master_id).to eq pc.master_id
    end

    it 'creates a reference in a specific record' do
      pn = random_phone_number

      config = {
        if: { always: true }
      }

      al_alt = create_item master: @master

      config = {
        player_contact: {
          in: {
            specific_record: {
              activity_log__player_contact_phones: {
                id: al_alt.id,
                return: 'return_result'
              }
            }
          },
          with: { data: pn, rec_type: :phone, rank: 5 }
        }
      }
      @trigger = SaveTriggers::CreateReference.new(config, @al)
      @trigger.perform

      pc = PlayerContact.find_by(data: pn)
      expect(pc).not_to be nil
      expect(pc.master_id).to eq @al.master.id

      mr = ModelReference.last&.reload
      expect(mr.to_record_id).to eq pc.id
      expect(mr.to_record_master_id).to eq pc.master_id
      expect(mr.from_record_master_id).to eq pc.master_id
      expect(mr.from_record_id).to eq al_alt.id
    end

    it 'creates a reference in a specific record with other item attributes' do
      pn = @player_contact.data

      config = {
        if: { always: true }
      }

      al_alt = create_item master: @master

      config = {
        player_contact: {
          in: {
            specific_record: {
              activity_log__player_contact_phones: {
                id: al_alt.id,
                return: 'return_result'
              }
            }
          },
          with_result: {
            from: {
              player_contacts: {
                id: @player_contact.id,
                return: 'return_result'
              }
            },
            attributes: {
              data: '{{data}} new',
              rec_type: 'rec_type'
            }
          },
          with: { rank: 5 }
        }
      }
      @trigger = SaveTriggers::CreateReference.new(config, @al)
      @trigger.perform

      pc = PlayerContact.find_by(data: "#{pn} new", rank: 5, rec_type: 'phone')
      expect(pc).not_to be nil
      expect(pc.master_id).to eq @al.master.id

      mr = ModelReference.last&.reload
      expect(mr.to_record_id).to eq pc.id
      expect(mr.to_record_master_id).to eq pc.master_id
      expect(mr.from_record_master_id).to eq pc.master_id
      expect(mr.from_record_id).to eq al_alt.id
    end

    it 'creates a reference in a specific record with attributes from multiple items' do
      pn = @player_contact.data
      pn_prev = @player_contact_prev.data

      config = {
        if: { always: true }
      }

      al_alt = create_item master: @master

      config = {
        player_contact: {
          in: {
            specific_record: {
              activity_log__player_contact_phones: {
                id: al_alt.id,
                return: 'return_result'
              }
            }
          },
          with_result: [
            {
              from: {
                player_contacts: {
                  id: @player_contact.id,
                  return: 'return_result'
                }
              },
              attributes: {
                data: '{{data}} new',
                rec_type: 'rec_type'
              }
            },
            {
              from: {
                player_contacts: {
                  id: @player_contact_prev.id,
                  return: 'return_result'
                }
              },
              attributes: {
                source: 'source'
              }
            }
          ],
          with: { rank: 5 }
        }
      }
      @trigger = SaveTriggers::CreateReference.new(config, @al)
      @trigger.perform

      pc = PlayerContact.find_by(data: "#{pn} new", rank: 5, rec_type: 'phone', source: 'nflpa2')
      expect(pc).not_to be nil
      expect(pc.master_id).to eq @al.master.id

      mr = ModelReference.last&.reload
      expect(mr.to_record_id).to eq pc.id
      expect(mr.to_record_master_id).to eq pc.master_id
      expect(mr.from_record_master_id).to eq pc.master_id
      expect(mr.from_record_id).to eq al_alt.id
    end
  end

  describe 'creating a referenced activity log from an activity log' do
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
            on_create:
              create_reference:
                activity_log__player_contact_elt:
                  force_create: true
                  in: this
                  with:
                    extra_log_type: mr_ref_pc
                    embedded_item:
                      data: '#{@working_data}'
                      rec_type: phone
                      rank: 5

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
            on_create:
              create_reference:
                activity_log__player_contact_elt:
                  force_create: true
                  in: this
                  with:
                    extra_log_type: mr_ref_pc
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

      END_DEF

      al.current_admin = @admin
      al.save!
      al = @activity_log

      setup_access al.resource_name, resource_type: :table, user: @user

      setup_option_config 0, 'Reference Player Contact', %w[select_call_direction select_who]
      setup_option_config 1, 'Reference Activity Log', %w[select_call_direction select_who disabled]
      setup_option_config 2, 'Reference Activity Log 2', %w[select_call_direction select_who disabled]
    end

    it 'creates an embedded_item when creating another record' do
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

      # Check we can create the basic activity log
      al_pc = ActivityLog::PlayerContactElt.new(select_call_direction: 'from staff',
                                                extra_log_type: 'mr_ref_pc',
                                                select_who: 'abc',
                                                master: @master)
      al_pc.save!

      expect(@master.current_user).to eq @user
      @master.player_contacts.create!(rec_type: 'email', data: 'test@test.tst', rank: -1)
      expect(al_pc.master).to eq @master
      expect(@master.current_user).to eq al_pc.current_user
      expect(al_pc.current_user.has_access_to?(:create, :table, :player_contacts)).to be_truthy
      ei = al_pc.create_embedded_item(pc_hash)
      expect(ei).to be_a PlayerContact

      pc = PlayerContact.all.reload.find_by(pc_hash)
      expect(pc).not_to be nil

      al_pc.clear_embedded_item_memo
      expect(al_pc.embedded_item).to eq pc

      # Now create the activity log with create_reference defined
      al_cr = ActivityLog::PlayerContactElt.new(select_call_direction: 'from staff',
                                                extra_log_type: 'mr_ref_al',
                                                select_who: 'abc',
                                                master: @master)
      al_cr.save!
      al_cr.clear_embedded_item_memo

      expect(al_cr.model_references.length).to eq 1
      ei = al_cr.embedded_item
      expect(ei).to be_a ActivityLog::PlayerContactElt
      ei.clear_model_reference_memo
      expect(ei.extra_log_type).to eq :mr_ref_pc

      pc2 = PlayerContact.find_by(pc_hash_1)
      expect(pc2).not_to be nil
      eiei = ei.embedded_item(embed_action_type: :viewing, force_reload: true)
      expect(eiei).to eq pc2

      # Now create the activity log with create_reference with_result defined
      @master.player_contacts.create!(pc_hash_2)

      al_cr = ActivityLog::PlayerContactElt.new(select_call_direction: 'from staff',
                                                extra_log_type: 'mr_ref_al2',
                                                select_who: 'abc',
                                                master: @master)
      al_cr.save!
      expect(al_cr.model_references.length).to eq 1
      expect(al_cr.embedded_item).to be_a ActivityLog::PlayerContactElt
      expect(al_cr.embedded_item.extra_log_type).to eq :mr_ref_pc

      pc2 = PlayerContact.find_by(pc_hash_2.merge(rank: 10))
      expect(pc2).not_to be nil

      expect(al_cr.embedded_item.embedded_item).to eq pc2
    end
  end
end
