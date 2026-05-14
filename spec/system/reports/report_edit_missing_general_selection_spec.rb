# frozen_string_literal: true

require 'rails_helper'

# System spec for GitHub issue #1140:
#   "Can't edit a record in a report on an arbitrary table, and 'missing'
#    general selection configs"
#
# Before the fix, when a Report had `edit_model` pointing at a dynamic model
# whose field name matched a general selection naming convention (e.g. `source`,
# `rank`) but no `Classification::GeneralSelection` rows had been defined, the
# user-facing report flow raised an FphsException ("The general selection ...
# has not been defined.") and the report could not be opened or its rows
# edited.
#
# This spec verifies the user-facing behavior after the fix:
# - The report can be opened and run without raising errors when its
#   underlying arbitrary table has a selection-like field with no general
#   selection definitions.
# - The inline edit form for a row in an editable report opens for an
#   arbitrary-table dynamic model record without raising "general selection
#   has not been defined", exposing the regular and selection-like fields
#   ready for editing.
describe 'report edit on arbitrary table with missing general selection',
         js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  ArbitraryTableName = 'issue_arbitrary_recs'
  ArbitrarySchemaName = 'dynamic_test'
  SelectionFieldName = 'source'

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    change_setting('AllowDynamicMigrations', true)
    SetupHelper.feature_setup

    @admin, = create_admin

    seed_database
    create_data_set_outside_tx

    @user, @good_password = create_user nil, '', create_master: true
    @good_email = @user.email

    setup_arbitrary_dynamic_model
    setup_report
    grant_user_access
    create_test_record
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', false)
  end

  #
  # Setup helpers
  #
  def setup_arbitrary_dynamic_model
    # Remove any pre-existing model with the same table name to keep this
    # spec isolated.
    DynamicModel.active.where(table_name: ArbitraryTableName).reload.each do |existing|
      existing.disable!(@admin)
    end
    DynamicModel.send(:remove_const, :IssueArbitraryRec) if defined?(DynamicModel::IssueArbitraryRec)

    @dynamic_model = DynamicModel.create!(
      current_admin: @admin,
      name: 'Issue Arbitrary Recs',
      schema_name: ArbitrarySchemaName,
      table_name: ArbitraryTableName,
      category: :test,
      field_list: "name #{SelectionFieldName}",
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      options: <<~YAML
        _db_columns:
          id:
            type: integer
          master_id:
            type: integer
          name:
            type: string
          #{SelectionFieldName}:
            type: string
          created_at:
            type: datetime
          updated_at:
            type: datetime
      YAML
    )

    @dynamic_model.update_tracker_events
    DynamicModel.routes_reload
    Rails.application.routes_reloader.reload!

    # Confirm runtime class exists and selection-like field has no general
    # selection definitions (precondition for the bug scenario).
    expect(@dynamic_model.implementation_class).to be < ActiveRecord::Base
    expect(
      Classification::GeneralSelection.where(
        item_type: ["#{ArbitraryTableName}_#{SelectionFieldName}",
                    "#{ArbitraryTableName.singularize}_#{SelectionFieldName}"]
      ).count
    ).to eq 0
  end

  def setup_report
    @report = Report.create!(
      current_admin: @admin,
      name: "Issue Arbitrary Report #{SecureRandom.hex(4)}",
      description: 'Editable report over an arbitrary dynamic-model table',
      sql: "select id, master_id, name, #{SelectionFieldName} " \
           "from #{ArbitrarySchemaName}.#{ArbitraryTableName} order by id",
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false,
      edit_model: ArbitraryTableName,
      edit_field_names: "name,#{SelectionFieldName}"
    )
  end

  def grant_user_access
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id, user: @user, current_admin: @admin,
      access: :read, resource_type: :general, resource_name: :view_reports
    )
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id, user: @user, current_admin: @admin,
      access: :read, resource_type: :general, resource_name: :edit_report_data
    )
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id, user: @user, current_admin: @admin,
      access: :read, resource_type: :report, resource_name: @report.alt_resource_name
    )
    setup_access :"dynamic_model__#{ArbitraryTableName}", user: @user
  end

  def create_test_record
    @master = Master.create!(current_user: @user)
    # Insert a pre-existing record directly: this simulates an arbitrary-table
    # row whose `source` value pre-dates any general selection configuration
    # (e.g. data imported from an external system).
    @record = @dynamic_model.implementation_class.new(
      master: @master,
      name: 'Original Name',
      SelectionFieldName.to_sym => 'free text value',
      current_user: @user
    )
    @record.save(validate: false)
    expect(@record).to be_persisted
  end

  #
  # Tests
  #
  before :each do
    login
    visit '/reports'
    finish_page_loading
  end

  def navigate_and_run_report
    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{@report.id}']", wait: 10)
    within ".data-results table.tablesorter tr[data-report-id='#{@report.id}']" do
      click_link @report.name
    end
    expect(page).to have_css('.report-criteria', wait: 10)
    finish_page_loading

    within '#report_query_form' do
      click_button 'table'
    end
    expect(page).to have_css('.search-status-done', wait: 10)
    expect(page).to have_css('.report-results-block table.tablesorter')
  end

  it 'opens the report and runs it without raising a missing general selection error' do
    navigate_and_run_report
    expect(page).to have_css("tr#report-item-#{@record.id}")

    # No flash error should mention "general selection has not been defined"
    expect(page).not_to have_content(/general selection .* has not been defined/i)
  end

  it 'opens the inline edit form for the row without raising a missing ' \
     'general selection error' do
    navigate_and_run_report

    edit_btn = find("tr#report-item-#{@record.id} .edit-entity.glyphicon-pencil")
    scroll_into_view(edit_btn)
    sleep 0.5
    edit_btn.click
    finish_page_loading

    # The edit form should be loaded inline without raising FphsException for
    # the selection-like field that has no general selection configured.
    expect(page).to have_css("tr#report-item-edit-#{@record.id}", wait: 10)
    expect(page).not_to have_content(/general selection .* has not been defined/i)

    within("tr#report-item-edit-#{@record.id}") do
      # The editable form exposes both the regular `name` field and a control
      # for the selection-like `source` field; the render path completed
      # without exception even though no general selection is configured.
      expect(page).to have_css("[name*='[name]']")
      expect(page).to have_css("[name*='[#{SelectionFieldName}]']")
      expect(page).to have_css('button.report-edit-submit')

      # The selection-like field should fall back to a plain text input
      # (rather than rendering an empty `<select>` with no options) so the
      # user can still enter and submit a value.
      expect(page).to have_css("input[type='text'][name*='[#{SelectionFieldName}]']")
      expect(page).not_to have_css("select[name*='[#{SelectionFieldName}]']")
    end
  end
end
