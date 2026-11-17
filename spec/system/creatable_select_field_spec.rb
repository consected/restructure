# frozen_string_literal: true

require 'rails_helper'

# System tests for the creatable select field component (Issue #73)
#
# Test Coverage:
# ✅ Renders typeahead input instead of select dropdown when creatable.enabled is true
# ✅ Shows typeahead suggestions when typing a matching value
# ✅ Saves existing value from typeahead without creating duplicates in source model
# ✅ Saves new value and auto-creates record in source model
#
# When a dynamic model field uses `select_record_from_table_<target>` with
# `creatable: { enabled: true }` in its `edit_as` field_options config,
# the field renders as a typeahead text input instead of a standard <select> dropdown.
# The Bloodhound/typeahead.js component provides autocomplete suggestions from existing
# source model records. When a user types a value that doesn't exist in the source model,
# a new record is auto-created in the source model via a before_save callback on save.
#
# Implementation Notes:
# - Uses dynamic models for test data (test_creatable_sources, test_creatable_consumers)
# - Tests run with AllowDynamicMigrations enabled to create tables on-the-fly
# - Typeahead input has class 'creatable-select-input typeahead'
# - Suggestions appear in '.tt-suggestion' elements from typeahead.js
# - Standard string/varchar fields downcase on storage and titleize on display
describe 'creatable select field component', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('AllowDynamicMigrations', true)
    create_admin

    ms = Master.no_temporary_masters
    if ms.count == 0 || ms.first.nil? || ms.first.id < 1
      create_data_set_outside_tx
      @master ||= ms.first
      @master_id ||= @master.id
    else
      @master = ms.first
      @master_id = @master.id
    end

    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    @app_type = @user.app_type
    expect(@app_type).not_to be nil
    expect(@user.two_factor_setup_required?).to be_falsey
    disable_active_panel_layout('test-columns-panel')
    # Disable all master-layout panels so the default tab template is used,
    # which includes the "details" tab for dynamic models with category: :details
    Admin::PageLayout.active.where(app_type_id: @app_type.id, layout_name: 'master').each do |pl|
      pl.disable!(@admin)
    end
  end

  # Create a source table with test data for creatable select
  # This table provides the "tag list" that the consumer field selects from
  def setup_source_data_table
    DynamicModel.active.where(table_name: 'test_creatable_sources').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestCreatableSource) if defined? DynamicModel::TestCreatableSource

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Creatable Sources',
                              schema_name: 'dynamic_test',
                              table_name: 'test_creatable_sources',
                              category: :test,
                              field_list: 'name',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id'

    dm.current_admin = @admin
    dm.update_tracker_events
    setup_access :dynamic_model__test_creatable_sources, resource_type: :table, access: :create, user: @user

    @master.current_user = @user
    ic = dm.implementation_class

    # Seed existing source values for typeahead suggestions
    @source_alpha = ic.create!(current_user: @user, master: @master, name: 'alpha source')
    @source_beta = ic.create!(current_user: @user, master: @master, name: 'beta source')

    dm
  end

  # Create a consumer dynamic model with a creatable select field
  # Uses select_record_from_table_test_creatable_sources with creatable.enabled
  def setup_creatable_consumer_dm
    DynamicModel.active.where(table_name: 'test_creatable_consumers').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestCreatableConsumer) if defined? DynamicModel::TestCreatableConsumer

    dm_options = <<~YAML
      _configurations: {}

      default:
        field_options:
          select_record_from_table_test_creatable_sources:
            edit_as:
              field_type: select_record_from_table_test_creatable_sources
              value_attr: name
              label_attr: name
              creatable:
                enabled: true
        labels:
          select_record_from_table_test_creatable_sources: Creatable Source
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Creatable Consumers',
                              schema_name: 'dynamic_test',
                              table_name: 'test_creatable_consumers',
                              category: :details,
                              options: dm_options,
                              field_list: 'select_record_from_table_test_creatable_sources',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 10

    dm.current_admin = @admin
    dm.update_tracker_events
    setup_access :dynamic_model__test_creatable_consumers, user: @user

    dm
  end

  # Navigate to the creatable consumer form within the master record details tab
  def navigate_to_creatable_form
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal
    finish_page_loading

    expect(page).to have_css("#master-#{@master.id}")
    expect(page).not_to have_css('.alert')

    # Expand the details tab - nav_q_id auto-expands the master record
    expand_master_record_tab('details')
    finish_page_loading

    new_button_selector = '.details-item-type-dynamic-model--test-creatable-consumers .new-button-container a.btn'
    expect(page).to have_css(new_button_selector, wait: 10)
    5.times do
      new_button = find(new_button_selector, wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      break if page.has_css?('form.new_dynamic_model_test_creatable_consumer', wait: 2)
    end

    expect(page).to have_css('form.new_dynamic_model_test_creatable_consumer', wait: 10)
    finish_form_formatting
    sleep 1 # Allow JavaScript to fully initialize typeahead
  end

  # Navigate to an existing saved creatable consumer record and open it in edit mode
  def navigate_to_saved_creatable_edit_form(expected_value:)
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal
    finish_page_loading

    expect(page).to have_css("#master-#{@master.id}")
    expect(page).not_to have_css('.alert')

    expand_master_record_tab('details')
    finish_page_loading

    details_section = find('.details-item-type-dynamic-model--test-creatable-consumers', wait: 10)

    record_item = details_section.all('li.list-group-item, .common-template-item', wait: 10).find do |item|
      item.text.downcase.include?(expected_value.downcase)
    end

    expect(record_item).not_to be_nil
    click_edit_button_within_target(record_item)
  end

  before :all do
    set_up_feature
    @source_dm = setup_source_data_table
    @consumer_dm = setup_creatable_consumer_dm

    [@source_dm, @consumer_dm].each do |dm|
      dm.force_regenerate = true
      dm.generate_model
      dm.add_master_association
    end
    SetupHelper.reload_configs
    DynamicModel.routes_load
    Rails.application.routes_reloader.reload!
  end

  before :each do
    login
  end

  it 'renders typeahead input instead of select dropdown' do
    navigate_to_creatable_form

    within('form.new_dynamic_model_test_creatable_consumer') do
      # Verify typeahead input is rendered
      expect(page).to have_css('input.creatable-select-input.typeahead[data-attr-name="select_record_from_table_test_creatable_sources"]')

      # Verify no select dropdown is rendered for the field
      expect(page).not_to have_css('select[data-attr-name="select_record_from_table_test_creatable_sources"]')
    end
  end

  it 'shows typeahead suggestions when typing a matching value' do
    navigate_to_creatable_form

    within('form.new_dynamic_model_test_creatable_consumer') do
      # typeahead.js duplicates the input; use match: :first to get the active one
      typeahead_input = find('input.creatable-select-input.tt-input', match: :first)
      scroll_into_view(typeahead_input)
      typeahead_input.send_keys('alpha')
    end

    # Typeahead suggestions appear outside the form scope
    expect(page).to have_css('.tt-suggestion', wait: 5)
    suggestion_texts = all('.tt-suggestion').map(&:text)
    expect(suggestion_texts).to include(a_string_matching(/alpha source/i))
  end

  it 'saves existing value from typeahead and does not create duplicate' do
    source_class = @source_dm.implementation_class
    initial_count = source_class.where(name: 'alpha source').count
    expect(initial_count).to be >= 1

    navigate_to_creatable_form

    within('form.new_dynamic_model_test_creatable_consumer') do
      # typeahead.js duplicates the input; use match: :first to get the active one
      typeahead_input = find('input.creatable-select-input.tt-input', match: :first)
      scroll_into_view(typeahead_input)
      typeahead_input.send_keys('alpha')
    end

    # Wait for and click the suggestion
    expect(page).to have_css('.tt-suggestion', wait: 5)
    find('.tt-suggestion', text: /alpha source/i, match: :first).click
    sleep 0.5

    within('form.new_dynamic_model_test_creatable_consumer') do
      click_button 'Save'
    end
    finish_form_formatting
    puts_form_validation_errors
    # Verify the record was saved and the value is displayed
    expect(page).to have_css('.details-item-type-dynamic-model--test-creatable-consumers', wait: 10)
    # Value is displayed as stored (lowercase)
    expect(page).to have_content('alpha source', normalize_ws: true)

    # Verify no duplicate was created in the source model
    expect(source_class.where(name: 'alpha source').count).to eq initial_count
  end

  it 'saves new value and auto-creates record in source model' do
    source_class = @source_dm.implementation_class
    expect(source_class.where(name: 'gamma source').count).to eq 0

    navigate_to_creatable_form

    within('form.new_dynamic_model_test_creatable_consumer') do
      # typeahead.js duplicates the input; use match: :first to get the active one
      typeahead_input = find('input.creatable-select-input.tt-input', match: :first)
      scroll_into_view(typeahead_input)
      typeahead_input.send_keys('gamma source')
    end

    sleep 0.5

    within('form.new_dynamic_model_test_creatable_consumer') do
      click_button 'Save'
    end
    finish_page_loading

    # Verify the record was saved and the value is displayed
    expect(page).to have_css('.details-item-type-dynamic-model--test-creatable-consumers', wait: 10)
    # Value is displayed as stored (lowercase)
    expect(page).to have_content('gamma source', normalize_ws: true)

    # Verify a new record was auto-created in the source model
    expect(source_class.where(name: 'gamma source').count).to eq 1

    # Re-open the saved dynamic model instance in edit mode and confirm
    # the newly added value is available in typeahead suggestions.
    edit_form = navigate_to_saved_creatable_edit_form(expected_value: 'gamma source')

    within(edit_form) do
      typeahead_input = find('input.creatable-select-input.tt-input', match: :first)
      scroll_into_view(typeahead_input)
      typeahead_input.send_keys([:control, 'a'])
      typeahead_input.send_keys(:delete)
      typeahead_input.send_keys('gam')
    end

    expect(page).to have_css('.tt-suggestion', wait: 5)
    suggestion_texts = all('.tt-suggestion').map(&:text)
    expect(suggestion_texts).to include(a_string_matching(/gamma source/i))
  end
end
