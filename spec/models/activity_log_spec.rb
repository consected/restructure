# frozen_string_literal: true

require 'rails_helper'

# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern.
#
# Tests cover:
# - Master association definitions for activity log extra log types
# - Reconfiguration of extra log types with new steps
# - View recreation when activity log definition changes
# - Regression: disabling an activity log definition skips item_type_exists validation

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
      # al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ActivityLog.refresh_outdated
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

  describe 'master association definitions work when config has changed' do
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


        new_step:
          label: New Step
          fields:
            - new_field
      ENDDEF

      al_def.extra_log_types = config

      al_def.current_admin = @admin
      # al_def.force_regenerate = true
      al_def.updated_at = DateTime.now # force a save
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      Application.refresh_dynamic_defs unless al_def.option_configs_names == %i[step_1 step_2 primary blank_log]

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__step_2, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__new_step, resource_type: :activity_log_type, access: :create, user: @user
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__step_1)).to be_truthy
      expect(@user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_phone__new_step)).to be_truthy
      al_def.add_master_association

      @al_def = al_def
    end

    it 'has a set of master associations pointing to the full table and individual extra log types' do
      expect(@al_def.option_configs_names).to eq %i[step_1 step_2 new_step primary blank_log]

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
      expect(@master.activity_log__player_contact_phone__new_step.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0

      expect(ActivityLog::PlayerContactPhone.definition.option_configs_names).to include :new_step

      @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'new_step')

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 2
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__new_step.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0

      @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'step_1')

      expect(@master.activity_log__player_contact_phones.reload.count).to eq 3
      expect(@master.activity_log__player_contact_phone__blank_log.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__primary.reload.count).to eq 0
      expect(@master.activity_log__player_contact_phone__new_step.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_1.reload.count).to eq 1
      expect(@master.activity_log__player_contact_phone__step_2.reload.count).to eq 0
    end
  end

  describe 'dynamic model view recreation when activity log changes' do
    # We test most of this outside the example to avoid the migration blocking
    before :all do
      change_setting('AllowDynamicMigrations', true)

      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS test_activity_log_views CASCADE')
      ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS activity_log_player_contact_view_tests CASCADE')

      config = <<~ENDDEF
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who
            - disabled
      ENDDEF

      ActivityLog.active.where(name: 'activity_log_player_contact_view_tests').each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      # Set up initial activity log definition
      @al_def = al_def = ActivityLog.create!(
        name: 'activity_log_player_contact_view_tests',
        item_type: 'player_contact',
        process_name: 'view_test',
        schema_name: 'dynamic_test',
        category: 'test',
        action_when_attribute: 'created_at',
        current_admin: @admin,
        extra_log_types: config
      )

      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      setup_access :activity_log__player_contact_view_tests, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_view_test__step_1, resource_type: :activity_log_type, access: :create, user: @user
      al_def.add_master_association

      @al_def = al_def
      @al_table_name = al_def.table_name

      ActiveRecord::Base.connection.schema_cache.clear!
      al_columns = Admin::MigrationGenerator.table_column_names(@al_table_name)
      expect(al_columns).not_to include('new_field')

      # Create a dynamic model with a view referencing the activity log table
      @dm = DynamicModel.create!(
        name: 'test activity log view',
        table_name: 'test_activity_log_views',
        schema_name: 'dynamic_test',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        category: :test,
        current_admin: @admin,
        options: <<~END_TEXT
          _configurations:
            view_sql: select * from #{@al_table_name}
        END_TEXT
      )

      expect(@dm.persisted?).to be_truthy
      expect(Admin::MigrationGenerator.view_exists?(@dm.table_name)).to be_truthy

      # Verify the view was created
      view_exists = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'dynamic_test' AND table_name = '#{@dm.table_name}'"
      ).first['count'].to_i > 0
      expect(view_exists).to be_truthy

      # Get initial view columns
      # initial_columns = Admin::MigrationGenerator.table_column_names(@dm.table_name)
      # expect(initial_columns).to include('select_call_direction', 'select_who')
      # expect(initial_columns).not_to include('new_field')
      ActiveRecord::Base.connection.schema_cache.clear!

      change_setting('AllowDynamicMigrations', nil)
    end

    before :all do
      change_setting('AllowDynamicMigrations', true)
      ActiveRecord::Base.connection.schema_cache.clear!

      @al_def = @al_def.class.find(@al_def.id)

      # Update the activity log definition to add a new field
      updated_config = <<~ENDDEF
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who
            - new_field
            - disabled
      ENDDEF

      @al_def.schema_name = 'dynamic_test'
      @al_def.extra_log_types = updated_config
      @al_def.current_admin = @admin
      @al_def.updated_at = DateTime.now
      @al_def.option_configs(force: true)
      @al_def.migration_generator(force_reset: true)
      @al_def.save!
      ActivityLog.refresh_outdated
      @al_def.reload
      @al_def.option_configs(force: true)
      @al_def.migration_generator(force_reset: true)

      # Verify the activity log table has the new field
      ActiveRecord::Base.connection.schema_cache.clear!
      al_columns = Admin::MigrationGenerator.table_column_names(@al_table_name)
      expect(al_columns).to include('new_field')

      change_setting('AllowDynamicMigrations', nil)
    end

    it 'recreates dependent views when activity log definition changes' do
      # Force dynamic model regeneration to pick up the view recreation
      ActiveRecord::Base.connection.schema_cache.clear!
      @dm = @dm.class.find(@dm.id)
      @dm.field_list = nil
      @dm.current_admin = @admin
      @dm.updated_at = DateTime.now
      @dm.save!
      DynamicModel.refresh_outdated
      @dm = @dm.class.find(@dm.id)
      @dm.field_list

      res = @dm.implementation_class.new
      # We don't expect the new field to appear in the view, since the view definition
      # pulled from the database explicitly names all the columns, so the previous set
      # are what we get when recreating the view.
      expect(res.attribute_names).not_to include('new_field')
      updated_columns = Admin::MigrationGenerator.table_column_names(@dm.table_name)
      expect(updated_columns).not_to include('new_field')
    end

    after :all do
      ActiveRecord::Base.connection.schema_cache.clear!
      change_setting('AllowDynamicMigrations', nil)
      ActivityLog.refresh_outdated

      if @al_def&.id
        @al_def = @al_def.class.find(@al_def.id)
        @al_def.disabled = true
        @al_def.current_admin = @admin
        @al_def.save!
        ActivityLog.refresh_outdated

        ActiveRecord::Base.connection.schema_cache.clear!
      end
    end
  end

  describe 'item_type_exists validation' do
    before :each do
      create_user
    end

    it 'skips validation when disabling a record with an unresolvable item type' do
      # Find an existing enabled activity log definition
      al_def = ActivityLog.active.first
      expect(al_def).not_to be_nil

      # Directly write an invalid item_type to simulate a model that no longer exists,
      # bypassing validations so the record is in the database with the bad value
      al_def.update_columns(item_type: 'nonexistent_model_type')
      al_def.reload

      # Disabling the record should succeed despite the unresolvable item_type
      al_def.current_admin = @admin
      al_def.disabled = true
      expect(al_def.save).to be true
    end

    it 'still validates item_type_exists for enabled records' do
      al_def = ActivityLog.active.first
      expect(al_def).not_to be_nil

      al_def.update_columns(item_type: 'nonexistent_model_type')
      al_def.reload

      # Saving an enabled record with an unresolvable item_type should fail validation
      al_def.current_admin = @admin
      al_def.disabled = false
      expect(al_def.save).to be false
      expect(al_def.errors[:item_type]).not_to be_empty
    end
  end
end
