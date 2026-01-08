# frozen_string_literal: true

require 'rails_helper'

describe 'admin YAML anchor recovery', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  it 'allows recovery from broken YAML by saving fixed YAML through the UI' do
    table_name = 'yaml_anchor_ui_test'
    schema_name = 'dynamic_test'

    # Clean up any existing table
    DynamicModel.active.where(table_name:).each { |dm| dm.disable!(@admin) }
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{schema_name}.#{table_name}")

    # Create table
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS #{schema_name}.#{table_name} (
        id SERIAL PRIMARY KEY,
        master_id INTEGER,
        name VARCHAR(255),
        user_id INTEGER,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
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
    # The user reported: "add the text '  bad entry' on the top line on the editor"
    page.execute_script(<<~JS)
      var editor = document.querySelector('textarea.code-editor');
      if (editor && editor.CodeMirror) {
        var currentValue = editor.CodeMirror.getValue();
        // Add bad entry at the very top of the content
        var brokenValue = '  bad entry\\n' + currentValue;
        editor.CodeMirror.setValue(brokenValue);
        // Do NOT call editor.CodeMirror.save() - let the form submission handle syncing
      }
    JS

    finish_page_loading

    # Step 3: Save - should succeed but show errors in config-error-block
    within '.admin-edit-form' do
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
    # The user reported: "delete the text '  bad entry' from the editor"
    page.execute_script(<<~JS)
      var editor = document.querySelector('textarea.code-editor');
      if (editor && editor.CodeMirror) {
        var currentValue = editor.CodeMirror.getValue();
        // Remove the bad entry line from the top
        var fixedValue = currentValue.replace(/^\\s*bad entry\\n/m, '');
        editor.CodeMirror.setValue(fixedValue);
        // Do NOT call editor.CodeMirror.save() - let the form submission handle syncing
      }
    JS

    finish_page_loading

    # Step 5: Save again - THIS IS THE CRITICAL TEST
    # Previously this would result in a server error and no changes saved
    within '.admin-edit-form' do
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
    page.execute_script(<<~JS)
      var editor = document.querySelector('textarea.code-editor');
      if (editor && editor.CodeMirror) {
        var currentValue = editor.CodeMirror.getValue();
        // Add bad entry at the very top of the content
        var brokenValue = '  bad entry\\n' + currentValue;
        editor.CodeMirror.setValue(brokenValue);
      }
    JS

    finish_page_loading

    # Step 3: Save - should succeed but show errors in config-error-block
    within '.admin-edit-form' do
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
    page.execute_script(<<~JS)
      var editor = document.querySelector('textarea.code-editor');
      if (editor && editor.CodeMirror) {
        var currentValue = editor.CodeMirror.getValue();
        // Remove the bad entry line from the top
        var fixedValue = currentValue.replace(/^\\s*bad entry\\n/m, '');
        editor.CodeMirror.setValue(fixedValue);
      }
    JS

    finish_page_loading

    # Step 5: Save again - THIS IS THE CRITICAL TEST
    # Previously this would cause a server error in view_sql_changed? when parsing broken YAML
    within '.admin-edit-form' do
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
