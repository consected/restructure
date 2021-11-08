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
      TableGenerators.dynamic_models_table('test_created_by_recs', :create_do, 'test1', 'test2', 'created_by_user_id', 'use_def_version_time')
    end

    setup_access :masters, user: @user
    @master = Master.create! current_user: @user
    @master.current_user = @user

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
end
