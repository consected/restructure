# frozen_string_literal: true

# Tests for YAML anchor recovery in admin panel
#
# This spec tests the ability to recover from broken YAML configurations that
# contain anchors and aliases. It simulates the user workflow of:
# 1. Having valid YAML with anchors
# 2. Making a mistake that breaks YAML parsing
# 3. Saving (which shows errors but preserves data)
# 4. Fixing the YAML
# 5. Successfully saving the fix
#
# Note: Migrations are disabled after initial setup because the migration
# runner uses a separate thread that can have connection pool issues in
# Capybara system tests. The core functionality being tested is YAML
# handling, not database migrations.

require 'rails_helper'

describe 'admin YAML anchor recovery', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
    # Save original setting to restore later
    @original_allow_migrations = Settings::AllowDynamicMigrations
  end

  after(:all) do
    # Restore original migration setting
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  it 'allows recovery from broken YAML by saving fixed YAML through the UI' do
    table_name = 'yaml_anchor_ui_test'
    schema_name = 'dynamic_test'

    # Clean up any existing table
    DynamicModel.active.where(table_name:).each { |dm| dm.disable!(@admin) }
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{schema_name}.#{table_name}")
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{schema_name}.#{table_name}_history")

    # Create table and history table (to prevent migrations from being triggered)
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS #{schema_name}.#{table_name} (
        id SERIAL PRIMARY KEY,
        master_id INTEGER,
        name VARCHAR(255),
        user_id INTEGER,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS #{schema_name}.#{table_name}_history (
        id SERIAL PRIMARY KEY,
        #{table_name.singularize}_id INTEGER,
        master_id INTEGER,
        name VARCHAR(255),
        user_id INTEGER,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)

    # Start with valid YAML that includes an anchor and alias
    valid_yaml_with_anchor = <<~YAML
      _definitions:
        common: &common
          label: Common Label

      default:
        fields:
          - name
        name:
          <<: *common
          caption_before: Name Field
    YAML

    # Create dynamic model with valid YAML
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'YAML Anchor UI Test',
      table_name:,
      schema_name:,
      category: 'test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      field_list: 'name master_id',
      options: valid_yaml_with_anchor
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    # Disable migrations after setup - we're testing YAML handling, not migrations
    # This prevents thread/connection pool issues in system tests
    change_setting('AllowDynamicMigrations', false)

    admin_sign_in_with_2fa

    # Step 1: Navigate to Dynamic Models admin page and edit our model
    visit '/admin/dynamic_models'
    finish_page_loading

    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    finish_page_loading

    # Step 2: Add bad entry to the top of the YAML (simulating user's exact scenario)
    codemirror_prepend(form_id: "edit_dynamic_model_#{dm.id}", text: "  bad entry\n")
    finish_page_loading

    # Step 3: Save - should succeed but show errors in config-error-block
    within "#edit_dynamic_model_#{dm.id}" do
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    # Wait for save to complete - should NOT get a server error
    expect(page).to have_content('updated', wait: 10)
    finish_page_loading

    # After save, errors should be displayed
    expect(page).to have_css('.config-error-block', wait: 10)
    expect(page).to have_content('configuration errors')

    # Verify the broken YAML was actually saved to the database
    dm.reload
    expect(dm.options).to include('bad entry')

    # Step 4: Now fix the YAML by removing the bad entry
    codemirror_replace(form_id: "edit_dynamic_model_#{dm.id}", pattern: '^\\s*bad entry\\n', replacement: '')
    finish_page_loading

    # Step 5: Save again - THIS IS THE CRITICAL TEST
    # Previously this would result in a server error and no changes saved
    within "#edit_dynamic_model_#{dm.id}" do
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    # Should succeed, not get a server error flash
    expect(page).not_to have_content('server error', wait: 5)
    expect(page).to have_content('updated', wait: 10)
    finish_page_loading

    # Step 6: Verify the fixed YAML was actually saved
    dm.reload
    expect(dm.options).not_to include('bad entry')
    expect(dm.options).to include('&common') # The anchor should still be there

    # Verify errors are gone from the page
    expect(page).not_to have_css('.config-error-block')
  end

  it 'allows recovery from broken YAML with view_sql configuration' do
    view_name = 'view_players_test'
    schema_name = 'dynamic_test'

    # Clean up any existing view/table
    DynamicModel.active.where(table_name: view_name).each { |dm| dm.disable!(@admin) }
    ActiveRecord::Base.connection.execute("DROP VIEW IF EXISTS #{schema_name}.#{view_name}")

    # Create source table for the view
    source_table = 'player_infos_source_test'
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{schema_name}.#{source_table}")
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS #{schema_name}.#{source_table} (
        id SERIAL PRIMARY KEY,
        master_id INTEGER,
        name VARCHAR(255),
        user_id INTEGER,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
    SQL
    ActiveRecord::Base.connection.execute(sql)

    # Create the view
    view_sql = "SELECT * FROM #{schema_name}.#{source_table}"
    ActiveRecord::Base.connection.execute("CREATE VIEW #{schema_name}.#{view_name} AS #{view_sql}")

    # Start with valid YAML that includes view_sql configuration
    valid_yaml_with_view_sql = <<~YAML
      _configurations:
        view_sql: |
          #{view_sql}

      default:
        fields:
          - name
        name:
          caption_before: Name Field
    YAML

    # Create dynamic model pointing to the view
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'View Players Test',
      table_name: view_name,
      schema_name:,
      category: 'test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      field_list: 'name master_id',
      options: valid_yaml_with_view_sql
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    # Disable migrations after setup - we're testing YAML handling, not migrations
    change_setting('AllowDynamicMigrations', false)

    admin_sign_in_with_2fa

    # Step 1: Navigate to Dynamic Models admin page and edit our model
    visit '/admin/dynamic_models'
    finish_page_loading

    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    finish_page_loading

    # Step 2: Add bad entry to the top of the YAML (breaking the YAML syntax)
    codemirror_prepend(form_id: "edit_dynamic_model_#{dm.id}", text: "  bad entry\n")
    finish_page_loading

    # Step 3: Save - should succeed but show errors in config-error-block
    within "#edit_dynamic_model_#{dm.id}" do
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    # Wait for save to complete - should NOT get a server error
    expect(page).to have_content('updated', wait: 10)
    finish_page_loading

    # After save, errors should be displayed
    expect(page).to have_css('.config-error-block', wait: 10)
    expect(page).to have_content('configuration errors')

    # Verify the broken YAML was actually saved to the database
    dm.reload
    expect(dm.options).to include('bad entry')

    # Step 4: Now fix the YAML by removing the bad entry
    codemirror_replace(form_id: "edit_dynamic_model_#{dm.id}", pattern: '^\\s*bad entry\\n', replacement: '')
    finish_page_loading

    # Step 5: Save again - THIS IS THE CRITICAL TEST
    # Previously this would cause a server error in view_sql_changed? when parsing broken YAML
    within "#edit_dynamic_model_#{dm.id}" do
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    # Should succeed, not get a server error flash
    expect(page).not_to have_content('server error', wait: 5)
    expect(page).to have_content('updated', wait: 10)
    finish_page_loading

    # Step 6: Verify the fixed YAML was actually saved
    dm.reload
    expect(dm.options).not_to include('bad entry')
    expect(dm.options).to include('view_sql')

    # Verify errors are gone from the page
    expect(page).not_to have_css('.config-error-block')
  end
end
