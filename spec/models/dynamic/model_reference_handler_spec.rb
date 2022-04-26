# frozen_string_literal: true

require 'rails_helper'

AlNameGenTest = 'Gen Test ELT'
# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Model reference implementation', type: :model do
  def al_name
    AlNameGenTest
  end

  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTest, 'elt', 'player_contact'
  end

  def setup_option_config(position, label, fields)
    c = @activity_log.option_configs[position]
    expect(c.label).to eq label
    expect(c.fields).to eq fields

    setup_access c.resource_name, resource_type: :activity_log_type, user: @user
  end

  describe 'references defined for activity logs' do
    before :each do
      create_admin
      create_user
      setup_access :player_contacts
      setup_access :addresses
      setup_access :activity_log__player_contact_phones
      @player_contact1 = create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact2 = create_item({ data: rand(10_000_000_000_000_000), rank: 10 }, @player_contact1.master)
      @player_contact3 = create_item({ data: rand(10_000_000_000_000_000), rank: 10 }, @player_contact1.master)

      @activity_log = al = ActivityLog.active.where(name: al_name).first
      @working_data = '(111)222-3333 ext 7654321'

      raise "Activity Log #{al_name} not set up" if al.nil?

      al.extra_log_types = <<~END_DEF
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who

        step_2:
          label: Step 2
          fields:
            - select_call_direction
            - select_who


        mr_simple_test:
          label: Reference Simple Test
          fields:
            - select_call_direction
            - select_who
          references:
            player_contacts:
              from: master
              add: many

        mr_showable_test:
          label: Reference Showable Test
          fields:
            - select_call_direction
            - select_who
          references:
            player_contacts:
              from: master
              add: many
              showable_if:
                all:
                  this:
                    select_who: 'xyz'
                  reference:
                    data: '#{@working_data}'


        mr_self_ref:
          label: Reference Self Test
          fields:
            - select_call_direction
            - select_who
            - disabled
          editable_if:
            always: true
          references:
            player_contacts:
              from: master
              add: many
            activity_log__player_contact_elt:
              from: this
              add: many
              also_disable_record: true

        mr_creatables:
          label: Creatables Test
          fields:
            - select_call_direction
            - select_who
          editable_if:
            always: true
          references:
            player_contacts:
              from: master
              add: many
              limit: 2
            activity_log__player_contact_elt:
              from: this
              add: one_to_this
              also_disable_record: true
              add_with:
                extra_log_type: mr_self_ref

        mr_activity_selector:
          label: Activity Selector
          fields:
            - select_call_direction
            - select_who
          editable_if:
            always: true
          references:
            player_contacts:
              from: master
              add: many
              limit: 2
            activity_log__player_contact_elt:
              from: this
              add: many
              also_disable_record: true
              type_config:
                activity_selector:
                  mr_showable_test: Showable Test
                  mr_simple_test: Simple Test
                  mr_creatables: Creatables

        mr_creatable_master:
          label: Creatable on Master Test
          fields:
            - select_call_direction
            - select_who
          editable_if:
            always: true
          references:
            player_contacts:
              from: master
              add: many
              limit: 2
            activity_log__player_contact_elt:
              from: this
              add: one_to_master
              also_disable_record: true
              add_with:
                extra_log_type: mr_self_ref


        always_embed:
          label: Always Embed
          fields:
            - select_call_direction
            - select_who
          editable_if:
            always: true
          view_options:
            always_embed_reference: player_contact
            always_embed_creatable_reference: address
          references:
            player_contact:
              from: master
              add: many
              limit: 2
            address:
              from: this
              add: many
              also_disable_record: true

        avoid_missing:
          label: Avoid Missing
          fields:
            - select_call_direction
            - select_who
          editable_if:
            always: true
          references:
            player_contact:
              from: this
              add: many
              limit: 2

        mr_showable_test2:
          label: Reference Showable Test2
          fields:
            - select_call_direction
            - select_who
            - tag_select_allowed
          references:
            player_contacts:
                from: master
                add: many
                showable_if:
                  any:
                    this:
                      select_who:
                        condition: '= ANY REV'
                        value: current_user_role_names
                    user:
                      role_name:
                        - editor
            activity_log__player_contact_elt:
                from: master
                add: many
                showable_if:
                  any:
                    this:
                      extra_log_type: never-match
                      tag_select_allowed:
                        condition: '&&'
                        value: current_user_role_names
                    user:
                      role_name:
                        - editor

      END_DEF

      al.current_admin = @admin
      al.save!
      al = @activity_log

      c1 = al.option_configs.first
      expect(c1.label).to eq 'Step 1'
      expect(c1.fields).to eq %w[select_call_direction select_who]
      setup_access al.resource_name, resource_type: :table, user: @user

      setup_option_config 2, 'Reference Simple Test', %w[select_call_direction select_who]
      setup_option_config 3, 'Reference Showable Test', %w[select_call_direction select_who]
      setup_option_config 4, 'Reference Self Test', %w[select_call_direction select_who disabled]
      setup_option_config 5, 'Creatables Test', %w[select_call_direction select_who]
      setup_option_config 6, 'Activity Selector', %w[select_call_direction select_who]
      setup_option_config 7, 'Creatable on Master Test', %w[select_call_direction select_who]
      setup_option_config 8, 'Always Embed', %w[select_call_direction select_who]
      setup_option_config 9, 'Avoid Missing', %w[select_call_direction select_who]
      setup_option_config 10, 'Reference Showable Test2', %w[select_call_direction select_who tag_select_allowed]
    end

    it 'evaluates rules to optionally show references' do
      puts @activity_log.resource_name

      @player_contact.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_simple_test',
                                                                          select_who: 'abc')
      al_simple.save!

      ModelReference.create_from_master_with(al_simple.master, @player_contact)

      al_showable = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                            extra_log_type: 'mr_showable_test',
                                                                            select_who: 'xyz')
      al_showable.save!

      master = al_showable.master

      # Simple always works
      expect(al_simple.model_references.length).to be > 0
      # Showable doesn't work initially because the reference data does not match
      expect(al_showable.model_references.length).to eq 0

      # Requires the to record to have data: (111)...
      att = {
        data: @working_data,
        rec_type: 'phone',
        source: 'nfl',
        rank: 10
      }
      pc2 = create_item(att, master)
      ModelReference.create_from_master_with(master, pc2)

      # Showable should now work, since the current record matches on select_who, and the reference matches on data

      al_showable.reference = pc2
      ref_config = al_showable.extra_log_type_config.references.first.last[:player_contact]
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_truthy

      al_showable.reset_model_references
      expect(al_showable.model_references.length).to eq 1
      expect(al_simple.model_references.length).to be > 0

      # Showable should now not work, since the current record does not match on select_who,
      # even though the reference matches on data
      al_showable.update! select_who: 'ghi'
      al_showable.reset_model_references
      expect(al_showable.model_references.length).to eq 0
      expect(al_simple.model_references.length).to be > 0

      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_falsey
    end

    it 'handles disabling of references and referenced items' do
      @player_contact.current_user = @user
      @player_contact.master.current_user = @user

      referenced = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                             extra_log_type: 'mr_self_ref',
                                                                             select_who: 'abc',
                                                                             master: @player_contact.master)

      referenced2 = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                              extra_log_type: 'mr_self_ref',
                                                                              select_who: 'abc2',
                                                                              master: @player_contact.master)

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_self_ref',
                                                                          select_who: 'abc')
      al_simple.save!

      mr = ModelReference.create_from_master_with(al_simple.master, @player_contact)

      mr_ref = ModelReference.create_with(al_simple, referenced)
      mr_ref2 = ModelReference.create_with(al_simple, referenced2)

      expect(al_simple.model_references.length).to be > 0

      # Disabling a reference pointing to a record with no disabled field should work
      mr.update!(disabled: true)
      expect(mr.disabled).to be true

      # Disabling a reference having the option also_disable_record also disables the to_record
      mr_ref.update!(disabled: true)
      expect(mr_ref.disabled).to be true
      referenced.reload
      expect(referenced.disabled).to be true

      # Disabling the to_record should lead to the model reference records pointing to it being disabled
      referenced2.update!(disabled: true, current_user: @user)
      referenced2.reload
      mr_ref2.reload
      expect(referenced2.disabled).to be true
      expect(mr_ref2.disabled).to be true
    end

    it 'limits number of references that can be created' do
      @player_contact.current_user = @user
      @player_contact.master.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_creatables',
                                                                          select_who: 'abc')
      al_simple.save!

      cmrs = al_simple.creatable_model_references only_creatables: true
      expect(cmrs.keys).to eq %i[activity_log__player_contact_elt_mr_self_ref player_contact]

      res = ModelReference.create_from_master_with(al_simple.master, @player_contact1)
      expect(res).to be_truthy
      res = ModelReference.create_from_master_with(al_simple.master, @player_contact2)
      expect(res).to be_truthy

      # We have gone beyond the limit of 2. Fail.
      cmrs = al_simple.creatable_model_references only_creatables: true, force_reload: true
      expect(cmrs.keys).to eq %i[activity_log__player_contact_elt_mr_self_ref]
      res = ModelReference.create_from_master_with(al_simple.master, @player_contact3)
      # expect(res).to be_falsey
      # @todo - we should enforce the limits in the actual creation. This will require some additional testing of\
      #         apps to ensure we don't have automated actions that depend on this.

      referenced = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                             extra_log_type: 'mr_self_ref',
                                                                             select_who: 'abc',
                                                                             master: @player_contact.master)
      mr_ref = ModelReference.create_with(al_simple, referenced)
      expect(mr_ref).to be_truthy

      cmrs = al_simple.creatable_model_references only_creatables: true, force_reload: true
      expect(cmrs.keys).to be_empty
      # We should only be able to add one to this item.
      res = ModelReference.create_with(al_simple, referenced)
      # expect(res).to be_falsey
      res
    end

    it 'presents creatable references based on a activity_selector configuration' do
      @player_contact.current_user = @user
      @player_contact.master.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_activity_selector',
                                                                          select_who: 'abc')
      al_simple.save!

      cmrs = al_simple.creatable_model_references only_creatables: true
      expect(cmrs.keys).to eq %i[activity_log__player_contact_elt_mr_showable_test
                                 activity_log__player_contact_elt_mr_simple_test
                                 activity_log__player_contact_elt_mr_creatables
                                 player_contact]
      expect(cmrs[:activity_log__player_contact_elt_mr_showable_test][:activity_log__player_contact_elt][:ref_config][:label]).to eq 'Showable Test'
      expect(cmrs[:activity_log__player_contact_elt_mr_simple_test][:activity_log__player_contact_elt][:ref_config][:label]).to eq 'Simple Test'
      expect(cmrs[:activity_log__player_contact_elt_mr_creatables][:activity_log__player_contact_elt][:ref_config][:label]).to eq 'Creatables'
    end

    it 'handles model references created on a master' do
      @player_contact.current_user = @user
      @player_contact.master.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_creatable_master',
                                                                          select_who: 'abc')
      al_simple.save!

      referenced = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                             extra_log_type: 'mr_self_ref',
                                                                             select_who: 'abc',
                                                                             master: @player_contact.master)

      cmrs = al_simple.creatable_model_references only_creatables: true
      expect(cmrs.keys).to eq %i[activity_log__player_contact_elt_mr_self_ref player_contact]
      ModelReference.create_from_master_with(al_simple.master, referenced)
      # We should not be able to create another, since this is set as one_to_master
      cmrs = al_simple.creatable_model_references only_creatables: true, force_reload: true
      expect(cmrs.keys).to eq %i[player_contact]
    end

    it 'always embeds defined references' do
      @player_contact.current_user = @user
      @player_contact.master.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'always_embed',
                                                                          select_who: 'abc')
      al_simple.save!

      # Create a player contact reference to show embedded
      ModelReference.create_with(al_simple, @player_contact3)

      cmrs = al_simple.creatable_model_references only_creatables: true
      expect(al_simple.always_embed_creatable_model_reference(cmrs).keys.first).to eq :address

      # In view mode, expect the embedded item to be the the player contact
      expect(al_simple.embedded_item).to be_a PlayerContact

      al_simple.action_name = 'show'
      al_simple.reset_model_references
      expect(al_simple.embedded_item).to be_a PlayerContact

      # In edit mode, continue to show player contact embedded
      al_simple.action_name = 'show'
      al_simple.reset_model_references
      expect(al_simple.embedded_item).to be_a PlayerContact

      # During new / create, show the other reference
      al_simple.action_name = 'create'
      al_simple.reset_model_references
      expect(al_simple.embedded_item).to be_a Address
    end

    it 'handles embedded references without a view_options definition' do
      @player_contact.current_user = @user
      @player_contact.master.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'avoid_missing',
                                                                          select_who: 'abc')
      al_simple.save!

      # In new / create mode, expect the embedded item to be the the player contact, since there are no other creatable references
      al_simple.action_name = 'create'
      al_simple.reset_model_references
      expect(al_simple.embedded_item).to be_a PlayerContact

      # Create a player contact reference to show embedded
      ModelReference.create_with(al_simple, @player_contact3)

      cmrs = al_simple.creatable_model_references only_creatables: true
      expect(al_simple.always_embed_creatable_model_reference(cmrs).keys.first).to be nil

      # In view mode, the player contact will not be embedded, since
      # multiple may be created.
      al_simple.action_name = 'show'
      expect(al_simple.embedded_item).to be nil

      # In edit mode, show the player contact embedded
      al_simple.action_name = 'edit'
      expect(al_simple.embedded_item).to be_a PlayerContact

      # Create a second player contact reference - now they will not appear embedded when viewed
      ModelReference.create_with(al_simple, @player_contact1)
      expect(al_simple.model_references(force_reload: true).length).to eq 2

      al_simple.action_name = 'show'
      expect(al_simple.embedded_item).to be nil

      # In edit mode, show the player contact embedded
      al_simple.action_name = 'edit'
      expect(al_simple.embedded_item).to be nil
    end

    it 'evaluates rules to optionally show references' do
      puts @activity_log.resource_name

      @player_contact.current_user = @user

      al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_simple_test',
                                                                          select_who: 'abc')
      al_simple.save!

      ModelReference.create_from_master_with(al_simple.master, @player_contact)

      al_showable = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                            extra_log_type: 'mr_showable_test2',
                                                                            select_who: 'xyz')
      al_showable.save!

      master = al_showable.master

      # Simple always works
      expect(al_simple.model_references.length).to be > 0
      # Showable doesn't work initially because the reference data does not match
      res = al_showable.model_references.length
      expect(res).to eq 0

      @user.user_roles.create!(app_type_id: @user.app_type_id, role_name: 'xyz', current_admin: @admin)

      # Showable should now work, since the user roles matches on select_who
      ref_config = al_showable.extra_log_type_config.references[:player_contact][:player_contact]
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_truthy

      # Second reference should not work, since the tag select field is empty

      @user.user_roles.find_by(app_type_id: @user.app_type_id, role_name: 'editor')&.disable!(@admin)

      ref_config = al_showable.extra_log_type_config.references[:activity_log__player_contact_elt][:activity_log__player_contact_elt]
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_falsey

      al_showable.reset_model_references

      al_showable.update!(tag_select_allowed: ['abc'])
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_falsey

      al_showable.reset_model_references

      al_showable.update!(tag_select_allowed: ['abc', 'sdfsdf'])
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_falsey

      al_showable.reset_model_references

      ur = @user.user_roles.create!(app_type_id: @user.app_type_id, role_name: 'editor', current_admin: @admin)
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_truthy

      ur.update!(disabled: true)
      al_showable.reset_model_references
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_falsey

      al_showable.reset_model_references
      al_showable.update!(tag_select_allowed: ['abc', 'xyz'])
      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_truthy

      al_showable.reset_model_references
      expect(al_showable.model_references.length).to eq 1
      expect(al_simple.model_references.length).to be > 0

      al_showable.update! select_who: 'ghi'
      al_showable.reset_model_references
      expect(al_showable.model_references.length).to eq 0
      expect(al_simple.model_references.length).to be > 0

      res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
      expect(res).to be_truthy
    end
  end

  describe 'references defined for dynamic modesl' do
    before :each do
      dm_name = 'Player Contact Phone Info'
      create_admin
      create_user
      import_bulk_msg_app
      setup_access :player_contacts
      setup_access :addresses
      let_user_create :dynamic_model__player_contact_phone_infos

      @player_contact1 = create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact2 = create_item({ data: rand(10_000_000_000_000_000), rank: 10 }, @player_contact1.master)
      @player_contact3 = create_item({ data: rand(10_000_000_000_000_000), rank: 10 }, @player_contact1.master)

      @dynamic_model = dm = DynamicModel.active.find_by(name: dm_name)
      @working_data = '(111)222-3333 ext 7654321'

      raise "Dynamic Model #{dm_name} not set up" if dm.nil?

      dm.options = <<~END_DEF
        default:
          label: Reference Simple Test
          references:
            player_contacts:
              from: master
              add: many
      END_DEF

      dm.current_admin = @admin
      dm.save!
    end

    it 'evaluates rules to show references' do
      puts @dynamic_model.resource_name

      @player_contact.current_user = @user

      dm = @dynamic_model.implementation_class.new(master: @player_contact.master)
      dm.save!

      ModelReference.create_from_master_with(dm.master, @player_contact)

      expect(dm.model_references.length).to be > 0
    end
  end
end
