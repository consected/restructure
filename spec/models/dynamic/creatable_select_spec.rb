# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for the creatable select field feature (Issue #73)
#
# When a dynamic model field uses `select_record_from_table_<target>` with
# `creatable: { enabled: true }` in its `edit_as` config, saving a record
# with a value that doesn't already exist in the target model should
# auto-create a new record in that target model.
#
# Test Coverage:
# - Existing value: saving with a value already in the target model does NOT create a duplicate
# - New value: saving with a value not in the target model DOES create a new record
# - Access control: user without `create` access on the target model gets a validation error
# - Blank/nil values: do not trigger creation
# - Additional single-select variants are supported:
#   select_record_from_*, select_record_id_from_table_*, select_record_id_from_*
# - Works with `value_attr: name` (text storage)
RSpec.describe 'Creatable select fields', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    create_user

    # Pre-create tables to avoid auto-migration timeout issues
    unless Admin::MigrationGenerator.table_exists? 'test_creatable_sources'
      TableGenerators.dynamic_models_table('test_creatable_sources', :create_do, 'name')
    end
    unless Admin::MigrationGenerator.table_exists? 'test_creatable_consumers'
      TableGenerators.dynamic_models_table('test_creatable_consumers', :create_do, 'select_record_from_table_test_creatable_sources')
    end
    unless Admin::MigrationGenerator.table_exists? 'test_creatable_assoc_consumers'
      TableGenerators.dynamic_models_table('test_creatable_assoc_consumers', :create_do, 'select_record_from_test_creatable_sources')
    end
    unless Admin::MigrationGenerator.table_exists? 'test_creatable_id_consumers'
      TableGenerators.dynamic_models_table('test_creatable_id_consumers', :create_do,
                                           'select_record_id_from_table_test_creatable_sources',
                                           'select_record_id_from_test_creatable_sources')
    end

    @master = create_master

    # Source model: a dynamic model with a 'name' field
    # Acts as the "tag list" that the consumer selects from
    DynamicModel.active.where(table_name: 'test_creatable_sources').reload.each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestCreatableSource) if DynamicModel.const_defined?(:TestCreatableSource, false)
    rescue NameError
    end

    @source_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test creatable sources',
      table_name: 'test_creatable_sources',
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )
    @source_dm.current_admin = @admin
    @source_dm.update_tracker_events

    setup_access :dynamic_model__test_creatable_sources, resource_type: :table, access: :create, user: @user

    # Consumer model: has a select_record_from_table_test_creatable_sources field
    # configured with creatable: { enabled: true }
    DynamicModel.active.where(table_name: 'test_creatable_consumers').reload.each { |dm| dm.disable!(@admin) }
    begin
      if DynamicModel.const_defined?(:TestCreatableConsumer, false)
        DynamicModel.send(:remove_const, :TestCreatableConsumer)
      end
    rescue NameError
    end

    consumer_options = <<~YAML
      default:
        field_options:
          select_record_from_table_test_creatable_sources:
            edit_as:
              field_type: select_record_from_table_test_creatable_sources
              value_attr: name
              label_attr: name
              creatable:
                enabled: true
    YAML

    @consumer_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test creatable consumers',
      table_name: 'test_creatable_consumers',
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: consumer_options
    )
    @consumer_dm.current_admin = @admin
    @consumer_dm.update_tracker_events

    setup_access :dynamic_model__test_creatable_consumers, user: @user

    DynamicModel.active.where(table_name: 'test_creatable_assoc_consumers').reload.each { |dm| dm.disable!(@admin) }
    begin
      if DynamicModel.const_defined?(:TestCreatableConsumerAssoc, false)
        DynamicModel.send(:remove_const, :TestCreatableConsumerAssoc)
      end
    rescue NameError
    end

    assoc_consumer_options = <<~YAML
      default:
        field_options:
          select_record_from_test_creatable_sources:
            edit_as:
              field_type: select_record_from_test_creatable_sources
              value_attr: name
              label_attr: name
              creatable:
                enabled: true
    YAML

    @assoc_consumer_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test creatable consumers assoc',
      table_name: 'test_creatable_assoc_consumers',
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: assoc_consumer_options
    )
    @assoc_consumer_dm.current_admin = @admin
    @assoc_consumer_dm.update_tracker_events

    setup_access :dynamic_model__test_creatable_assoc_consumers, user: @user

    DynamicModel.active.where(table_name: 'test_creatable_id_consumers').reload.each { |dm| dm.disable!(@admin) }
    begin
      if DynamicModel.const_defined?(:TestCreatableConsumerId, false)
        DynamicModel.send(:remove_const, :TestCreatableConsumerId)
      end
    rescue NameError
    end

    id_consumer_options = <<~YAML
      default:
        field_options:
          select_record_id_from_table_test_creatable_sources:
            edit_as:
              field_type: select_record_id_from_table_test_creatable_sources
              label_attr: name
              creatable:
                enabled: true
          select_record_id_from_test_creatable_sources:
            edit_as:
              field_type: select_record_id_from_test_creatable_sources
              label_attr: name
              creatable:
                enabled: true
    YAML

    @id_consumer_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test creatable consumers id',
      table_name: 'test_creatable_id_consumers',
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: id_consumer_options
    )
    @id_consumer_dm.current_admin = @admin
    @id_consumer_dm.update_tracker_events

    setup_access :dynamic_model__test_creatable_id_consumers, user: @user
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :example do
    create_user
    @master = create_master
    setup_access :dynamic_model__test_creatable_sources, resource_type: :table, access: :create, user: @user
    setup_access :dynamic_model__test_creatable_consumers, user: @user
    setup_access :dynamic_model__test_creatable_assoc_consumers, user: @user
    setup_access :dynamic_model__test_creatable_id_consumers, user: @user
  end

  def source_class
    @source_dm.implementation_class
  end

  def consumer_class
    @consumer_dm.implementation_class
  end

  def assoc_consumer_class
    @assoc_consumer_dm.implementation_class
  end

  def id_consumer_class
    @id_consumer_dm.implementation_class
  end

  describe 'when saving with a value that already exists in the target model' do
    it 'does not create a duplicate record in the target model' do
      source_class.create!(current_user: @user, master: @master, name: 'existing tag one')
      existing_count = source_class.where(name: 'existing tag one').count
      expect(existing_count).to eq 1

      consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_from_table_test_creatable_sources: 'existing tag one'
      )

      expect(source_class.where(name: 'existing tag one').count).to eq 1
    end
  end

  describe 'when saving with a new value that does not exist in the target model' do
    it 'creates a new record in the target model with the configured value_attr' do
      expect(source_class.where(name: 'brand new tag').count).to eq 0

      consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_from_table_test_creatable_sources: 'brand new tag'
      )

      expect(source_class.where(name: 'brand new tag').count).to eq 1
    end
  end

  describe 'when the user does not have create access on the target model' do
    before :example do
      setup_access :dynamic_model__test_creatable_sources, resource_type: :table, access: :read, user: @user
    end

    it 'adds a validation error and does not create the new record' do
      expect(source_class.where(name: 'unauthorized new tag').count).to eq 0

      record = consumer_class.new(
        current_user: @user,
        master: @master,
        select_record_from_table_test_creatable_sources: 'unauthorized new tag'
      )

      expect(record.save).to be false
      expect(record.errors).not_to be_empty
      expect(source_class.where(name: 'unauthorized new tag').count).to eq 0
    end
  end

  describe 'when saving with a blank or nil value' do
    it 'does not trigger creation for a nil value' do
      initial_count = source_class.count

      consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_from_table_test_creatable_sources: nil
      )

      expect(source_class.count).to eq initial_count
    end

    it 'does not trigger creation for a blank string value' do
      initial_count = source_class.count

      consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_from_table_test_creatable_sources: ''
      )

      expect(source_class.count).to eq initial_count
    end
  end

  describe 'when using other single-select select_record variants' do
    it 'creates a new record for select_record_from_* fields' do
      expect(source_class.where(name: 'assoc new tag').count).to eq 0

      assoc_consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_from_test_creatable_sources: 'assoc new tag'
      )

      expect(source_class.where(name: 'assoc new tag').count).to eq 1
    end

    it 'creates a new record and stores its id for select_record_id_from_table_* fields' do
      expect(source_class.where(name: 'id table new tag').count).to eq 0

      rec = id_consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_id_from_table_test_creatable_sources: '__creatable_new__id table new tag'
      )

      created = source_class.find_by(name: 'id table new tag')
      expect(created).not_to be_nil
      expect(rec.select_record_id_from_table_test_creatable_sources.to_i).to eq(created.id)
    end

    it 'stores existing id directly when value is a numeric id' do
      existing = source_class.create!(current_user: @user, master: @master, name: 'id direct existing')

      rec = id_consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_id_from_table_test_creatable_sources: existing.id.to_s
      )

      expect(rec.select_record_id_from_table_test_creatable_sources.to_i).to eq(existing.id)
      expect(source_class.where(name: 'id direct existing').count).to eq 1
    end

    it 'maps existing labels to ids for select_record_id_from_* fields without creating duplicates' do
      existing = source_class.create!(current_user: @user, master: @master, name: 'id assoc existing')
      expect(source_class.where(name: 'id assoc existing').count).to eq 1

      rec = id_consumer_class.create!(
        current_user: @user,
        master: @master,
        select_record_id_from_test_creatable_sources: '__creatable_new__id assoc existing'
      )

      expect(rec.select_record_id_from_test_creatable_sources.to_i).to eq(existing.id)
      expect(source_class.where(name: 'id assoc existing').count).to eq 1
    end
  end
end
