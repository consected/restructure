# frozen_string_literal: true

require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log definition', type: :model do
  include ModelSupport
  include PlayerContactSupport

  describe 'master association definitions' do
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
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who

        step_2:
          label: Step 2
          fields:
            - select_call_direction
            - extra_text

      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ::ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      Application.refresh_dynamic_defs unless al_def.option_configs_names == %i[step_1 step_2 primary blank_log]

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__step_2, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__step_1)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'has a set of master associations pointing to the full table and individual extra log types' do
      expect(@al_def.option_configs_names).to eq %i[step_1 step_2 primary blank_log]

      expect(@master.activity_log__player_contact_phones.count).to eq 0
      expect(@master.activity_log__player_contact_phone__primary.count).to eq 0
      expect(@master.activity_log__player_contact_phone__blank_log.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_2.count).to eq 0

      @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                  select_who: 'user')

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0

      @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'primary')

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 2
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0

      @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'step_1')

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 3
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0
    end

    it 'creates activity logs with the correct extra log type through master associations' do
      expect(@master.activity_log__player_contact_phones.count).to eq 0
      expect(@master.activity_log__player_contact_phone__primary.count).to eq 0
      expect(@master.activity_log__player_contact_phone__blank_log.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_2.count).to eq 0

      al = @master.activity_log__player_contact_phone__step_1.build(select_call_direction: 'from player',
                                                                    select_who: 'user', player_contact: @player_contact)

      expect(al.extra_log_type).to eq :step_1
      al.save!

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0

      al = @master.activity_log__player_contact_phone__step_2.create!(select_call_direction: 'from player',
                                                                      select_who: 'user', player_contact: @player_contact)

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 2
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 1

      al = @master.activity_log__player_contact_phone__step_1.create!(select_call_direction: 'from player',
                                                                      select_who: 'user', player_contact: @player_contact)

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 3
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 2
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 1
    end

    it 'creates activity logs with the correct extra log type through item associations' do
      expect(@player_contact.activity_log__player_contact_phones.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__primary.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__blank_log.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__step_1.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__step_2.count).to eq 0

      al = @player_contact.activity_log__player_contact_phone__step_1.create!(select_call_direction: 'from player',
                                                                              select_who: 'user', player_contact: @player_contact)

      # expect(al.extra_log_type).to eq :step_1
      # al.save!

      expect(@player_contact.activity_log__player_contact_phones.reload.count).to eq 1
      expect(@player_contact.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__blank_log.reload.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__step_1.reload.count).to eq 1
      expect(@player_contact.activity_log__player_contact_phone__step_2.reload.count).to eq 0

      al = @player_contact.activity_log__player_contact_phone__step_2.create!(select_call_direction: 'from player',
                                                                              select_who: 'user', player_contact: @player_contact)

      expect(@player_contact.activity_log__player_contact_phones.reload.count).to eq 2
      expect(@player_contact.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__blank_log.reload.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__step_1.reload.count).to eq 1
      expect(@player_contact.activity_log__player_contact_phone__step_2.reload.count).to eq 1

      al = @player_contact.activity_log__player_contact_phone__step_1.create!(select_call_direction: 'from player',
                                                                              select_who: 'user', player_contact: @player_contact)

      expect(@player_contact.activity_log__player_contact_phones.reload.count).to eq 3
      expect(@player_contact.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__blank_log.reload.count).to eq 0
      expect(@player_contact.activity_log__player_contact_phone__step_1.reload.count).to eq 2
      expect(@player_contact.activity_log__player_contact_phone__step_2.reload.count).to eq 1
    end
  end
end
