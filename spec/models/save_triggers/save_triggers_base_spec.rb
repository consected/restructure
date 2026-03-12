require 'rails_helper'

RSpec.describe SaveTriggers::SaveTriggersBase, type: :model do
  include ModelSupport
  include PlayerContactSupport

  describe 'save_trigger actions called on create, update or any save' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        save_trigger_test_1:
          label: Save Trigger Test 1
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              update_this:
                one:
                  with:
                    select_who: 'created value'

            on_update:
              update_this:
                one:
                  with:
                    select_who: 'updated value'

        save_trigger_test_2:
          label: Save Trigger Test 2
          fields:
            - select_call_direction
            - extra_text

          field_options:
            select_who:
              blank_preset_value: 'from preset value - {{select_call_direction}}'

          save_trigger:
            on_update:
              update_this:
                one:
                  with:
                    select_who: 'updated value2'

        save_trigger_test_3:
          label: Save Trigger Test 3
          fields:
            - select_call_direction
            - notes

          field_options:
            select_who:
              blank_preset_value: 'from preset value - {{select_call_direction}}'

          save_trigger:
            on_update:
              - update_this:
                  one:
                    with:
                      select_who: 'updated value2'
              - create_reference:
                  player_contact:
                    in: master
                    with:
                      rank: 10
                      rec_type: email
                      data: test@test.tst
              - update_this:
                  one:
                    with:
                      notes: 'this was updated with player contact {{player_contact_emails.first.data}}'
              - create_reference:
                  player_contact:
                    in: master
                    with:
                      rank: 10
                      rec_type: phone
                      data: (617) 794 2300

              - update_this:
                  one:
                    with:
                      notes: |
                        - {{notes}}
                        - this was updated with player contact phone {{player_contact_phones.first.data}}

        save_trigger_test_4:
          label: Save Trigger Test 4
          fields:
            - select_call_direction
            - extra_text

          field_options:
            select_who:
              blank_preset_value: 'a,b,c'
            bad_field_name_test_preset_value:
              blank_preset_value: 'should not break'

          save_trigger:
            on_update:
              - update_this:
                  one:
                    with:
                      notes: |-
                        List of results
              - each:
                  value: '{{{select_who::split_csv}}}'
                  if:
                    not_any:
                      this:
                        save_trigger_results:
                          element: iterator_value
                          value:
                            - ''
                            - null
                  do:
                    - update_this:
                        one:
                          with:
                            notes: |-
                              {{notes}}
                              - {{save_trigger_results.iterator_index}} => {{save_trigger_results.iterator_value}}
                    - update_this:
                        one:
                          with:
                            select_who: 'an iterator'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      unless al_def.option_configs_names == %i[save_trigger_test_1 save_trigger_test_2 primary blank_log]
        Application.refresh_dynamic_defs
      end

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__save_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__save_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__save_trigger_test_3, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__save_trigger_test_4, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__save_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'does not run the trigger when an instance is created if not defined' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'save_trigger_test_2')
      expect(al.select_who).to eq 'user'
      expect(al.select_call_direction).to eq 'from player'
    end

    it 'runs the on_create trigger when an instance is created' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'save_trigger_test_1')
      expect(al.select_who).to eq 'created value'
    end

    it 'runs the on_update trigger when an instance is updated' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'save_trigger_test_2')
      expect(al.select_who).to eq 'user'
      al.skip_save_trigger = false
      al.update!(select_call_direction: 'to player')
      expect(al.select_who).to eq 'updated value2'
    end

    it 'runs the on_update trigger when an instance is updated after the create trigger' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'save_trigger_test_1')
      expect(al.select_who).to eq 'created value'
      al.reload
      al.skip_save_trigger = false
      al.current_user = @master.current_user
      al.update!(select_call_direction: 'to player')
      expect(al.select_who).to eq 'updated value'
    end

    it 'sets a preset value, which can be overridden in the on_update trigger' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       extra_log_type: 'save_trigger_test_2')
      expect(al.select_who).to eq 'from preset value - from player'
      al.skip_save_trigger = false
      al.update!(select_call_direction: 'make update')
      expect(al.select_who).to eq 'updated value2'
    end

    it 'runs a list of triggers in the desired order' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'save_trigger_test_3')
      expect(al.select_who).to eq 'user'
      al.skip_save_trigger = false
      al.update!(select_call_direction: 'to player')
      expect(al.select_who).to eq 'updated value2'
      expect(al.notes).to eq <<~END_TEXT
        - this was updated with player contact test@test.tst
        - this was updated with player contact phone (617)794-2300
      END_TEXT
    end

    it 'runs a list of triggers for each value specified' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: '"",a,b,,c,',
                                                                       extra_log_type: 'save_trigger_test_4')
      expect(al.select_who).to eq '"",a,b,,c,'
      al.skip_save_trigger = false
      al.update!(select_call_direction: 'to player')
      expect(al.select_who).to eq 'an iterator'
      expect(al.notes).to eq <<~END_TEXT
        List of results
        - 1 => a
        - 2 => b
        - 4 => c
      END_TEXT
        .strip
    end
  end

  describe 'batch_trigger actions called directly' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        batch_trigger_test_1:
          label: Batch Trigger Test 1
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              update_this:
                one:
                  with:
                    select_who: 'created value'

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value'

        batch_trigger_test_2:
          label: Batch Trigger Test 2
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value 2'

        batch_trigger_test_3:
          label: Batch Trigger Test 3
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              update_this:
                one:
                  with:
                    select_who: 'created value'

          batch_trigger:
            on_record:
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'batch updated value 3'
              - create_reference:
                  player_contact:
                    in: master
                    with:
                      rec_type: email
                      rank: 5
                      data: test2@test.tst
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: |
                        - {{select_who}}
                        - added {{player_contact_emails.first.data}}

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      unless al_def.option_configs_names == %i[batch_trigger_test_1 batch_trigger_test_2 primary blank_log]
        Application.refresh_dynamic_defs
      end

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_3, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__batch_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'does not run the trigger when an instance is created or updated' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')

      expect(al.select_who).to eq 'created value'
      al.skip_save_trigger = false
      al.update!(select_call_direction: 'to player')
      expect(al.select_who).to eq 'created value'

      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_2')
      expect(al.select_who).to eq 'user'
      al.skip_save_trigger = false
      al.update!(select_call_direction: 'to player')
      expect(al.select_who).to eq 'user'
    end

    it 'runs the correct trigger when called' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'
      all_recs = al.class.all.pluck(:id)

      al.reload
      al.skip_save_trigger = false
      al.current_user = @master.current_user

      al2.reload
      al2.skip_save_trigger = false
      al2.current_user = @master.current_user

      res = al.class.trigger_batch_now
      expect(res).to eq all_recs

      al.reload
      al2.reload
      expect(al.select_who).to eq 'batch updated value'
      expect(al2.select_who).to eq 'batch updated value 2'
    end

    it 'runs the the triggers in a list' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_3')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'
      all_recs = al.class.all.pluck(:id)

      al.reload
      al.skip_save_trigger = false
      al.current_user = @master.current_user

      al2.reload
      al2.skip_save_trigger = false
      al2.current_user = @master.current_user

      res = al.class.trigger_batch_now
      expect(res).to eq all_recs

      al.reload
      al2.reload
      expect(al2.select_who).to eq 'batch updated value 2'
      expect(al.select_who).to eq <<~END_TEXT
        - batch updated value 3
        - added test2@test.tst
      END_TEXT
    end
  end

  describe 'batch_trigger limits number of records processed' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        _configurations:
          batch_trigger:
            frequency: '1 minute'
            limit: 1

        batch_trigger_test_1:
          label: Batch Trigger Test 1
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              update_this:
                one:
                  with:
                    select_who: 'created value'

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value'

        batch_trigger_test_2:
          label: Batch Trigger Test 2
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value 2'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      unless al_def.option_configs_names == %i[batch_trigger_test_1 batch_trigger_test_2 batch_trigger_scheduled primary blank_log]
        Application.refresh_dynamic_defs
      end

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__batch_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'limits the number of records processed' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'
      all_recs = al.class.all.pluck(:id)[0, 1]

      al.reload
      al.skip_save_trigger = false
      al.current_user = @master.current_user

      al2.reload
      al2.skip_save_trigger = false
      al2.current_user = @master.current_user

      res = al.class.trigger_batch_now # limit: 1 is set by config
      expect(res).to eq all_recs

      al.reload
      al2.reload
      # The activity log sorting is reverse chronological, so the limit will process the last one created only
      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'batch updated value 2'
    end
  end

  describe 'batch_trigger provides if: condition' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        _configurations:
          batch_trigger:
            frequency: '1 minute'
            limit: 500 # limit is processed differently when there is an if condition
            if:
              all:
                this:
                  extra_log_type: batch_trigger_test_1

        batch_trigger_test_1:
          label: Batch Trigger Test 1
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              update_this:
                one:
                  with:
                    select_who: 'created value'

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value'

        batch_trigger_test_2:
          label: Batch Trigger Test 2
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value 2'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      unless al_def.option_configs_names == %i[batch_trigger_test_1 batch_trigger_test_2 primary blank_log]
        Application.refresh_dynamic_defs
      end

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__batch_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'enforces the if condition' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')
      al3 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user3',
                                                                        extra_log_type: 'batch_trigger_test_1')
      al4 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user4',
                                                                        extra_log_type: 'batch_trigger_test_1')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'
      al.class.all.pluck(:id)[0, 1]

      al.reload
      al.skip_save_trigger = false
      al.current_user = @master.current_user

      al2.reload
      al2.skip_save_trigger = false
      al2.current_user = @master.current_user

      res = al.class.trigger_batch_now # limit: 1 is set by config
      expect(res).to eq [al4.id, al3.id, al.id]

      al.reload
      al2.reload
      al3.reload
      al4.reload
      # The activity log sorting is reverse chronological, so the limit will process the last one created only
      expect(al.select_who).to eq 'batch updated value'
      expect(al3.select_who).to eq 'batch updated value'
      expect(al4.select_who).to eq 'batch updated value'
      expect(al2.select_who).to eq 'user'
    end
  end

  describe 'batch_trigger scheduling' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        _configurations:
          batch_trigger:
            frequency: '1 hour'

        batch_trigger_test_1:
          label: Batch Trigger Test 1
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              update_this:
                one:
                  with:
                    select_who: 'created value'

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value'

        batch_trigger_test_2:
          label: Batch Trigger Test 2
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value 2'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      Delayed::Worker.delay_jobs = true
      al_def.save!
      Delayed::Worker.delay_jobs = false
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      unless al_def.option_configs_names == %i[batch_trigger_test_1 batch_trigger_test_2 batch_trigger_scheduled primary blank_log]
        Application.refresh_dynamic_defs
      end

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__batch_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'runs trigger as a job' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'
      al.class.all.pluck(:id)

      al.reload
      al.skip_save_trigger = false
      al.current_user = @master.current_user

      al2.reload
      al2.skip_save_trigger = false
      al2.current_user = @master.current_user

      al.class.trigger_batch

      al.reload
      al2.reload
      expect(al.select_who).to eq 'batch updated value'
      expect(al2.select_who).to eq 'batch updated value 2'
    end

    it 'sets a frequency to run batches' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'

      expect(al.class.definition.configurations[:batch_trigger][:frequency]).to eq '1 hour'
    end

    it 'adds a recurring job' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'

      expect(al.class.definition.task_schedule.run_at).to be_between(DateTime.now + 59.minutes, DateTime.now + 1.hour)
    end

    it 'unschedules a recurring job' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')
      al2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                        select_who: 'user',
                                                                        extra_log_type: 'batch_trigger_test_2')

      expect(al.select_who).to eq 'created value'
      expect(al2.select_who).to eq 'user'

      al_def = al.class.definition
      expect(al_def.task_schedule.run_at).to be_between(DateTime.now + 59.minutes, DateTime.now + 1.hour)

      config = <<~ENDDEF
        _configurations:
          batch_trigger:
            limit: 1

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value 2'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      Delayed::Worker.delay_jobs = true
      al_def.save!
      Delayed::Worker.delay_jobs = false

      expect(al_def.task_schedule).to be_nil
    end
  end

  describe 'batch_trigger run once' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        _configurations:
          batch_trigger:
            frequency: 'once'

        batch_trigger_test_1:
          label: Batch Trigger Test 1
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      Delayed::Worker.delay_jobs = true
      al_def.save!
      Delayed::Worker.delay_jobs = false
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      Application.refresh_dynamic_defs unless al_def.option_configs_names == %i[batch_trigger_test_1 primary blank_log]

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      # setup_access :activity_log__player_contact_phone__batch_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__batch_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'sets a frequency to run batch one time' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')

      expect(al.class.definition.configurations[:batch_trigger][:frequency]).to eq 'once'
    end
  end

  describe 'batch_trigger run at' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up additional steps in the activity log definition
      # Find the actual current version of the definition
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        _configurations:
          batch_trigger:
            frequency: '1 day'
            run_at: '13:00'

        batch_trigger_test_1:
          label: Batch Trigger Test 1
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch updated value'

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      Delayed::Worker.delay_jobs = true
      al_def.save!
      Delayed::Worker.delay_jobs = false
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      unless al_def.option_configs_names == %i[batch_trigger_test_1 batch_trigger_scheduled primary blank_log]
        Application.refresh_dynamic_defs
      end

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_trigger_test_1, resource_type: :activity_log_type, access: :create, user: @user
      # setup_access :activity_log__player_contact_phone__batch_trigger_test_2, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__batch_trigger_test_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'sets a frequency to run batch at a specific time' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'user',
                                                                       extra_log_type: 'batch_trigger_test_1')

      expect(al.class.definition.configurations[:batch_trigger][:frequency]).to eq '1 day'
      expect(al.class.definition.configurations[:batch_trigger][:run_at]).to eq '13:00'
    end
  end

  describe 'error reporting for invalid trigger configurations - Issue #984' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      al_def = ActivityLog.find_by(id: ActivityLog::PlayerContactPhone.definition.id)
      unless al_def
        SetupHelper.setup_al_gen_tests('Phone Log', nil, 'player_contact', rec_type: 'phone')
        al_def = ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').first
      end

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      al_def.extra_log_types = <<~END_DEF
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who
      END_DEF

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create,
                                                                user: @user
      al_def.add_master_association

      @activity_log = @master.activity_log__player_contact_phones.create!(
        select_call_direction: 'to player',
        select_who: 'user',
        extra_log_type: 'step_1',
        player_contact: @player_contact,
        master: @master,
        current_user: @user
      )
      @activity_log.save_trigger_results ||= {}
    end

    describe '#execute_trigger_list' do
      it 'includes the full trigger config in the error when a trigger name is invalid - Issue #984' do
        trigger_list = [
          { invalid_trigger_xyz: { message: 'bad config data' } }
        ]

        # Use a valid trigger (log) to get a SaveTriggersBase instance to call execute_trigger_list
        base_trigger = SaveTriggers::Log.new({ message: 'test' }, @activity_log)

        expect { base_trigger.send(:execute_trigger_list, trigger_list) }.to raise_error(FphsException) do |error|
          expect(error.message).to include('invalid_trigger_xyz')
          expect(error.message).to include('bad config data')
        end
      end
    end

    describe '.calc_triggers' do
      it 'includes the full trigger config in the error when a trigger name is invalid - Issue #984' do
        configs = { nonexistent_trigger: { key: 'value123' } }

        error = nil
        begin
          OptionConfigs::ExtraOptionImplementers::SaveTriggers::ClassMethods
            .instance_method(:calc_triggers)
            .bind_call(OptionConfigs::ExtraOptions, @activity_log, configs)
        rescue FphsException => e
          error = e
        end

        expect(error).to be_a(FphsException)
        expect(error.message).to include('nonexistent_trigger')
        expect(error.message).to include('value123')
      end
    end
  end
end
