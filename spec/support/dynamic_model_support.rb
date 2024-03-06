# frozen_string_literal: true

require "#{::Rails.root}/spec/support/seed_support"
require "#{::Rails.root}/spec/support/user_support"

module DynamicModelSupport
  #
  # Set up a dynamic model definition, defining a DynamicModel::TestCreatedByRec
  # with fields test1, test2, created_by_user_id
  # Create an instance with
  #
  #     master.dynamic_model__test_created_by_recs.create! test1: 'abc'
  #
  def generate_test_dynamic_model
    unless Admin::MigrationGenerator.table_exists? 'test_created_by_recs'
      TableGenerators.dynamic_models_table('test_created_by_recs', :create_do, 'test1', 'test2', 'created_by_user_id', 'use_def_version_time', 'text_array')
    end

    setup_access :masters, user: @user
    @master = Master.create! current_user: @user
    @master.current_user = @user

    DynamicModel.active.where(table_name: 'test_created_by_recs').each { |dm| dm.disable!(@admin) }

    dm = DynamicModel.create! current_admin: @admin, name: 'test created by', table_name: 'test_created_by_recs', primary_key_name: :id, foreign_key_name: :master_id, category: :test
    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel

    setup_access :dynamic_model__test_created_by_recs, user: @user
    setup_access :dynamic_model__test_created_by_recs, user: @user0
    dm
  end

  def generate_test_dynamic_view
    create_user
    setup_access :masters, user: @user
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
                              schema_name: 'dynamic',
                              category: :test

    dm.update_tracker_events

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test embed field and ids',
                              table_name: 'test_embed_field_and_ids',
                              schema_name: 'dynamic',
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
                              schema_name: 'dynamic',
                              category: :test,
                              options:)

    dm.update_tracker_events

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test embedded recs',
                              table_name: 'test_embedded_recs',
                              schema_name: 'dynamic',
                              category: :test

    dm.update_tracker_events
  end
end
