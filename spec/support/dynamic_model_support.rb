# frozen_string_literal: true

require "#{Rails.root}/spec/support/seed_support"
require "#{Rails.root}/spec/support/user_support"

module DynamicModelSupport
  module ClassMethods
    def generate_test_dynamic_model_before_all(**)
      before(:all) do
        generate_test_dynamic_model(**)
      end
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  # Manually trigger migration generation and execution
  # Force reset the migration generator to ensure it picks up the new db_configs
  def force_migration(dm)
    change_setting('AllowDynamicMigrations', true)
    prev_prevent_migrations = dm.prevent_migrations
    dm.force_prevent_migrations = false
    dm.instance_variable_set(:@migration_generator, nil)
    dm.send(:generate_migration)
    if dm.instance_variable_get(:@do_migration)
      dm.send(:run_migration)
    else
      puts 'Skipped migration'
    end
    change_setting('AllowDynamicMigrations', false)
    dm.force_prevent_migrations = prev_prevent_migrations

    dm.update_tracker_events

    # Force column cache refresh
    ActiveRecord::Base.connection.schema_cache.clear!
    DynamicModel.reset_active_model_configurations!
  end

  def alt_name_for_file(file)
    File.basename(file).gsub('_spec.rb', '').singularize
  end

  #
  # Set up a dynamic model definition, defining a DynamicModel::TestCreatedByRec
  # with fields test1, test2, created_by_user_id
  # Create an instance with
  #
  #     master.dynamic_model__test_created_by_recs.create! test1: 'abc'
  #
  # We default it to being readonly, to allow us to reuse the same dynamic model without accidental modifications.
  def generate_test_dynamic_model(table_name: 'test_created_by_recs', reset_access: false, extra_attrs: {})
    # @master = Master.create! current_user: @user
    # @master.current_user = @user
    @test_dynamic_models ||= {}
    dm = @test_dynamic_models[table_name]
    if dm && !reset_access && !dm.disabled? && extra_attrs.empty?
      dm.reload
      dm.generate_model
      dm.add_master_association
      return dm
    end

    put_now "Getting test dynamic model for table #{table_name}"
    dm = DynamicModel.active.find_by(table_name: table_name)
    dm ||= DynamicModel.find_by(table_name: table_name)
    dm ||= DynamicModelSupport.generate_test_dynamic_model(table_name:, name: table_name, allow_updating: true)
    expect(dm).not_to be_nil, "Expected to find a dynamic model for table #{table_name}"
    full_attrs = extra_attrs.merge(disabled: false, current_admin: @admin)
    if dm.disabled? || extra_attrs.any?
      dm.class.where(id: dm.id).update_all(full_attrs.except(:current_admin))
      dm.reload
      dm.current_admin = @admin
      dm.update_tracker_events
    end

    expect(dm.disabled).not_to be_truthy, "Expected dynamic model not to be disabled for table #{table_name}"
    # dm.update!(current_admin: @admin, updated_at: Time.current)
    setup_access :"dynamic_model__#{table_name}", user: @user
    setup_access :"dynamic_model__#{table_name}", user: @user0
    dm.generate_model
    dm.add_master_association
    @test_dynamic_models[table_name] = dm
  end

  def self.generate_test_dynamic_model(table_name: 'test_created_by_recs', name: 'test created by', schema_name: nil, category: :test, allow_updating: false)
    admin = Admin.active.first
    TableGenerators.dynamic_models_table(table_name, :create_do, 'test1', 'test2', 'created_by_user_id', 'use_def_version_at', 'text_array', skip_if_exists: true)
    Admin::MigrationGenerator.tables_and_views_reset!
    schema_name ||= Admin::MigrationGenerator.table_schema_hash[table_name]

    const_name = table_name.camelize

    DynamicModel.active.where(table_name: table_name).update_all(disabled: true, updated_at: Time.current)
    DynamicModel.reset_active_model_configurations!
    # Use const_defined? with inherit=false to only check directly-defined constants,
    # and rescue in case the constant was removed by a parallel test
    begin
      DynamicModel.send(:remove_const, const_name) if DynamicModel.const_defined?(const_name, false)
    rescue NameError
      # Constant may have been removed by another parallel test
    end
    dm = DynamicModel.create!(current_admin: admin, name:, table_name:, primary_key_name: :id, foreign_key_name: :master_id, category:, schema_name:)
    dm.update_tracker_events

    raise "Expected test dynamic model to be a DynamicModel, got #{dm.class.name}" unless dm.is_a? ::DynamicModel

    active_count = DynamicModel.active.where(table_name: table_name).reload.count
    raise "Expected 1 active dynamic model for table #{table_name}, got #{active_count}" unless active_count == 1

    dm.send :reset_all_versions

    unless allow_updating
      @prevent_dm_updates_to_ids ||= []
      @prevent_dm_updates_to_ids << dm.id
      prevent_dm_updates_to_ids = @prevent_dm_updates_to_ids
      DynamicModel.define_method(:readonly?) do
        raise "Expected dynamic model #{table_name} to be readonly" if prevent_dm_updates_to_ids.include?(id)

        super()
      end
    end

    dm
  end

  def generate_test_dynamic_view
    create_user
    @master = Master.create! current_user: @user
    @master.current_user = @user

    yaml = <<~YAML
      _configurations:
        view_sql: |
          select
            id,
            master_id,
            first_name,
            last_name
          from player_infos
    YAML

    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test view',
      table_name: 'test_views',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: yaml,
      schema_name: 'dynamic_test'
    )
  end

  def generate_test_embed_dynamic_models
    @admin, = create_admin unless @admin

    unless Admin::MigrationGenerator.table_exists? 'test_embed_fields'
      TableGenerators.dynamic_models_table('test_embed_fields', :create_do, 'test1', 'test2', 'embed_resource_name')
    end

    unless Admin::MigrationGenerator.table_exists? 'test_embed_field_and_ids'
      TableGenerators.dynamic_models_table('test_embed_field_and_ids', :create_do, 'test1', 'test2', 'embed_resource_name', 'embed_resource_id')
    end

    unless Admin::MigrationGenerator.table_exists? 'test_embed_options'
      TableGenerators.dynamic_models_table('test_embed_options', :create_do, 'test1', 'test2')
    end

    unless Admin::MigrationGenerator.table_exists? 'test_embedded_recs'
      TableGenerators.dynamic_models_table('test_embedded_recs', :create_do, 'test1', 'test2', 'test_embed_field_id', 'test_embed_option_id', 'test_embed_field_and_id')
    end

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test embed fields',
                              table_name: 'test_embed_fields',
                              schema_name: 'dynamic_test',
                              category: :test

    dm.update_tracker_events

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test embed field and ids',
                              table_name: 'test_embed_field_and_ids',
                              schema_name: 'dynamic_test',
                              category: :test

    dm.update_tracker_events

    options = <<~END_DEF
      default:
        label: Reference Simple Test
        embed:
          resource_name: dynamic_model__test_embedded_recs
    END_DEF

    dm = DynamicModel.create!(current_admin: @admin,
                              name: 'test embed options',
                              table_name: 'test_embed_options',
                              schema_name: 'dynamic_test',
                              category: :test,
                              options:)

    dm.update_tracker_events

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test embedded recs',
                              table_name: 'test_embedded_recs',
                              schema_name: 'dynamic_test',
                              category: :test

    dm.update_tracker_events
  end
end
