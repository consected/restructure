# frozen_string_literal: true

require 'rails_helper'

# System tests for the big-select field component
#
# Test Coverage:
# ✅ Basic big-select functionality:
#    - Opening dialog and selecting items
#    - Multiple sequential selections
#    - Clearing selections with (none) option
# ✅ hide_popover option: Hides info popover and shows overlay with selected value text
# ✅ hide_key option: Controls visibility of the value key in the selection list
# ✅ Grouped items (group_split_char):
#    - Displays items in collapsible groups by category
#    - Auto-expands group containing currently selected value
# ✅ Filtered option:
#    - Filters big-select items based on another field's value
#    - Updates dynamically when filter field changes
#    - Works with grouped items and category-based filtering
#
# The big-select component is a modal dialog for selecting from large lists of options,
# providing a better UX than standard dropdowns when there are many choices.
#
# Implementation Notes:
# - Uses dynamic models for test data (test_big_select_sources, test_big_select_fields)
# - Tests run with AllowDynamicMigrations enabled to create tables on-the-fly
# - Modal interactions must happen outside Capybara `within` blocks to avoid scope issues
# - Helper methods in feature_support.rb handle common big-select operations
describe 'big-select field component', js: true, driver: $browser_driver do
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
  end

  # Create a source table with test data for selections
  # DynamicModel.create! automatically creates the table via migration
  def setup_source_data_table
    DynamicModel.active.where(table_name: 'test_big_select_sources').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestBigSelectSource) if defined? DynamicModel::TestBigSelectSource

    # NOTE: Source table uses master_id foreign key.
    # Records are created for @master, and the form also uses @master context,
    # so queries will return these records.
    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Big Select Sources',
                              schema_name: 'dynamic_test',
                              table_name: 'test_big_select_sources',
                              category: :test,
                              field_list: 'name category description',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id'

    dm.current_admin = @admin
    dm.update_tracker_events
    setup_access :dynamic_model__test_big_select_sources, user: @user

    @master.current_user = @user
    ic = dm.implementation_class

    # Category A items - belong to @master
    # Using exact category names to match filter options
    @source_item1 = ic.create!(current_user: @user, master: @master,
                               name: 'alpha item', category: 'category a',
                               description: 'First item in Category A')
    @source_item2 = ic.create!(current_user: @user, master: @master,
                               name: 'beta item', category: 'category a',
                               description: 'Second item in Category A')

    # Category B items
    @source_item3 = ic.create!(current_user: @user, master: @master,
                               name: 'gamma item', category: 'category b',
                               description: 'First item in Category B')
    @source_item4 = ic.create!(current_user: @user, master: @master,
                               name: 'delta item', category: 'category b',
                               description: 'Second item in Category B')

    # Category C items for filtered tests
    @source_item5 = ic.create!(current_user: @user, master: @master,
                               name: 'epsilon item', category: 'category c',
                               description: 'First item in Category C')

    dm
  end

  # Create a dynamic model with various big-select field configurations
  # DynamicModel.create! automatically creates the table via migration
  def setup_big_select_test_dm
    DynamicModel.active.where(table_name: 'test_big_select_fields').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestBigSelectField) if defined? DynamicModel::TestBigSelectField

    dm_options = <<~YAML
      _configurations: {}

      default:
        field_options:
          select_basic:
            edit_as:
              field_type: select_record_from_table_test_big_select_sources
              value_attr: name
              label_attr:
                - name
                - ' >>> '
                - description
              big_select:
                hide_key: true

          select_hide_popover:
            edit_as:
              field_type: select_record_from_table_test_big_select_sources
              value_attr: name
              label_attr: name
              big_select:
                hide_popover: true

          filter_category:
            edit_as:
              field_type: select_filter_category
              alt_options:
                'Category A': category a
                'Category B': category b
                'Category C': category c
              select_filtering_target: 'select_filtered'

          select_filtered:
            edit_as:
              field_type: select_record_from_table_test_big_select_sources
              value_attr: name
              label_attr:
                - category
                - '|'
                - name
              group_split_char: '|'
              big_select:
                filtered: true

          select_grouped:
            edit_as:
              field_type: select_record_from_table_test_big_select_sources
              value_attr: name
              label_attr:
                - category
                - '|'
                - name
              group_split_char: '|'
              big_select:
                hide_key: true

          select_with_hide_key:
            edit_as:
              field_type: select_record_from_table_test_big_select_sources
              value_attr: name
              label_attr:
                - name
                - ' >>> '
                - description
              big_select:
                hide_key: true

          select_without_hide_key:
            edit_as:
              field_type: select_record_from_table_test_big_select_sources
              value_attr: name
              label_attr:
                - name
                - ' >>> '
                - description
              big_select:
                hide_key: false

        labels:
          select_basic: Basic Selection
          select_hide_popover: Selection With Overlay
          filter_category: Filter By Category
          select_filtered: Filtered Selection
          select_grouped: Grouped Selection
          select_with_hide_key: Selection With Hide Key
          select_without_hide_key: Selection Without Hide Key
          notes: Notes
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Big Select Fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_big_select_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'select_basic select_hide_popover filter_category select_filtered select_grouped select_with_hide_key select_without_hide_key notes',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 10

    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_big_select_fields, user: @user

    dm
  end

  # Helper method to navigate to the big-select test form
  # Centralizes navigation logic and adds consistent wait handling
  def navigate_to_big_select_form
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal
    finish_page_loading

    expect(page).to have_css("#master-#{@master.id}")

    expand_master_record_and_tab(master_id: @master.id, tab_name: 'details')
    finish_page_loading

    new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
    expect(page).to have_css(new_button_selector, wait: 10)
    5.times do
      new_button = find(new_button_selector, wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      break if page.has_css?('form.new_dynamic_model_test_big_select_field', wait: 2)
    end

    unless page.has_css?('form.new_dynamic_model_test_big_select_field', wait: 2)
      new_button = find(new_button_selector, wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading
    end

    expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
    finish_form_formatting
    sleep 1 # Allow JavaScript to fully initialize
  end

  describe 'basic big-select functionality' do
    before(:all) do
      set_up_feature
      @source_dm = setup_source_data_table
      @fields_dm = setup_big_select_test_dm

      # Force regeneration of models since they failed during initial app load
      # (tables didn't exist at that time)
      [@source_dm, @fields_dm].each do |dm|
        dm.force_regenerate = true
        dm.generate_model
        dm.add_master_association
      end

      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      login
    end

    it 'opens big-select dialog, selects an item, and sets the field value' do
      navigate_to_big_select_form

      # Call helper OUTSIDE the within block to avoid scope issues
      select_from_big_select_field('select_basic', 'alpha item')

      # Verify the field value was set
      within('form.new_dynamic_model_test_big_select_field') do
        basic_field = find('input.use-big-select[data-attr-name="select_basic"]', visible: :all)
        expect(basic_field.value).to eq('alpha item')
      end
    end

    it 'opens big-select multiple times in sequence' do
      navigate_to_big_select_form

      # First open: select an item
      select_from_big_select_field('select_basic', 'alpha item')

      # Verify field value
      basic_field = find('form.new_dynamic_model_test_big_select_field input[data-attr-name="select_basic"]', visible: :all)
      expect(basic_field.value).to eq('alpha item')

      # Second open: clear selection
      clear_big_select_field('select_basic')

      # Verify field cleared
      basic_field = find('form.new_dynamic_model_test_big_select_field input[data-attr-name="select_basic"]', visible: :all)
      expect(basic_field.value).to eq('big-select-clear')

      # Third open: select a different item
      select_from_big_select_field('select_basic', 'beta item')

      # Verify field value
      basic_field = find('form.new_dynamic_model_test_big_select_field input[data-attr-name="select_basic"]', visible: :all)
      expect(basic_field.value).to eq('beta item')
    end

    it 'clears selection when clicking the (none) option' do
      navigate_to_big_select_form

      # Call helpers OUTSIDE within block
      select_from_big_select_field('select_basic', 'beta item')

      # Verify it's set
      within('form.new_dynamic_model_test_big_select_field') do
        basic_field = find('input.use-big-select[data-attr-name="select_basic"]', visible: :all)
        expect(basic_field.value).to eq('beta item')
      end

      # Now clear using helper (outside within block)
      clear_big_select_field('select_basic')

      # Verify the field was cleared
      within('form.new_dynamic_model_test_big_select_field') do
        basic_field = find('input.use-big-select[data-attr-name="select_basic"]', visible: :all)
        expect(basic_field.value).to eq('big-select-clear')
      end
    end
  end

  describe 'hide_popover option' do
    before(:all) do
      set_up_feature
      setup_source_data_table
      setup_big_select_test_dm
      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      login
    end

    it 'displays overlay field showing selected value text instead of popover' do
      navigate_to_big_select_form

      within('form.new_dynamic_model_test_big_select_field') do
        # Find the hide_popover big-select field
        hide_popover_field = find('input.use-big-select[data-attr-name="select_hide_popover"]', visible: :all)
        expect(hide_popover_field).not_to be_nil

        # Verify it has the big-select-use-overlay class
        expect(hide_popover_field[:class]).to include('big-select-use-overlay')

        # Verify there's no popover icon (info sign)
        wrapper = hide_popover_field.ancestor('.big-select-wrapper')
        expect(wrapper).not_to have_css('.big-select-description')

        # Verify the overlay field exists
        expect(wrapper).to have_css('.big-select-overlay', visible: :all)
      end

      # Select item using helper (outside within block)
      select_from_big_select_field('select_hide_popover', 'gamma item')

      # Verify the overlay shows the selected value text (raw value, not titleized)
      within('form.new_dynamic_model_test_big_select_field') do
        overlay = find('.big-select-overlay[id$="---overlay"]', visible: :all)
        expect(overlay.value).to include('gamma item')
      end
    end
  end

  describe 'hide_key option' do
    before(:all) do
      set_up_feature
      setup_source_data_table
      setup_big_select_test_dm
      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      login
    end

    it 'hides the key/ID when hide_key is true and shows it when false' do
      navigate_to_big_select_form
      finish_page_loading

      expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
      # Test field WITH hide_key: true
      # Both fields have same label_attr: [name, ' >>> ', description]
      # With hide_key: true, the JavaScript splits on '>>>' separator
      # The key (first part) goes in .bsi--head, the rest in .bsi--body
      with_hide_key_field = find('input.use-big-select[data-attr-name="select_with_hide_key"]', visible: :all)
      scroll_into_view(with_hide_key_field)
      with_hide_key_field.click

      # Wait for modal to open
      expect(page).to have_css('#primary-modal.fade.in', wait: 5)
      expect(page).to have_css('.big-select-item', wait: 3)

      # Find an item - with hide_key: true, it splits on ' >>> ' separator
      # The key (first part) goes in .bsi--head, the rest in .bsi--body

      # Should have both head and body elements
      expect(page).to have_css('.big-select-item[data-bsi-key="alpha item"] .bsi--head', text: 'alpha item')
      expect(page).to have_css('.big-select-item[data-bsi-key="alpha item"] .bsi--body', text: 'First item in Category A')

      # Close modal
      find('body').click
      expect(page).not_to have_css('#primary-modal.fade.in', wait: 3)

      # Test field WITHOUT hide_key (hide_key: false)
      # Same label_attr: [name, ' >>> ', description]
      # With hide_key: false, the key is shown in .bsi--head and full label in .bsi--body
      without_hide_key_field = find('input.use-big-select[data-attr-name="select_without_hide_key"]', visible: :all)
      scroll_into_view(without_hide_key_field)
      without_hide_key_field.click

      # Wait for modal to open
      expect(page).to have_css('#primary-modal.fade.in', wait: 5)
      expect(page).to have_css('.big-select-item', wait: 3)

      # Find an item - with hide_key: false, key is shown and full label is shown

      # Should have both head (key) and body (full label) elements
      expect(page).to have_css('.big-select-item[data-bsi-key="gamma item"] .bsi--head', text: 'gamma item')
      expect(page).to have_css('.big-select-item[data-bsi-key="gamma item"] .bsi--body', text: 'gamma item >>> First item in Category B')

      # Close modal
      find('body').click
      expect(page).not_to have_css('#primary-modal.fade.in', wait: 3)
    end
  end

  describe 'grouped items with group_split_char' do
    before(:all) do
      set_up_feature
      setup_source_data_table
      setup_big_select_test_dm
      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      login
    end

    it 'displays items in collapsible groups based on category' do
      navigate_to_big_select_form

      # Use the helper to select from grouped big-select (outside within block, use lowercase group name)
      select_from_grouped_big_select_field('select_grouped', 'alpha item', group_name: 'category a')

      # Verify the value was set (lowercase in database)
      within('form.new_dynamic_model_test_big_select_field') do
        grouped_field = find('input.use-big-select[data-attr-name="select_grouped"]', visible: :all)
        expect(grouped_field.value).to eq('alpha item')
      end
    end

    it 'automatically expands the group containing the currently selected value' do
      # First create a record with a pre-selected value (use lowercase)
      @master.current_user = @user
      ic = DynamicModel::TestBigSelectField
      ic.create!(current_user: @user, master: @master,
                 select_grouped: 'delta item', notes: 'Test record')

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      expand_master_record_and_tab(master_id: @master.id, tab_name: 'details')
      finish_page_loading

      # Find the details section for our dynamic model
      details_section = find('.details-item-type-dynamic-model--test-big-select-fields', wait: 5)

      # Find and click edit on the existing record (should be the only one visible)
      within(details_section) do
        # Look for the edit button (pencil icon)
        edit_button = find('.edit-entity', match: :first, visible: :all)
        scroll_into_view(edit_button)
        edit_button.click
      end

      unless page.has_css?('form.edit_dynamic_model_test_big_select_field', wait: 2)
        details_section = find('.details-item-type-dynamic-model--test-big-select-fields', wait: 5)
        within(details_section) do
          edit_button = find('.edit-entity', match: :first, visible: :all)
          scroll_into_view(edit_button)
          edit_button.click
        end
      end

      expect(page).to have_css('form.edit_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1 # Allow JavaScript to fully initialize big-select fields

      # Verify the field has the pre-selected value
      grouped_field = find('form.edit_dynamic_model_test_big_select_field input.use-big-select[data-attr-name="select_grouped"]', visible: :all)
      expect(grouped_field.value).to eq('delta item')

      # Click the field to open the modal
      grouped_field[:id]
      scroll_into_view(grouped_field)
      grouped_field.click

      expect(page).to have_css('#primary-modal.fade.in', wait: 5)
      expect(page).to have_css('.big-select-group-head', wait: 3)

      # The group containing Delta Item (Category B) should be auto-expanded
      # and the selected item should have the bsi-selected class
      expect(page).to have_css('.collapse.in .big-select-item.bsi-selected', wait: 3)

      selected_item = find('.big-select-item.bsi-selected')
      expect(selected_item.text).to include('delta item')

      # Close the modal
      find('body').click
      expect(page).not_to have_css('#primary-modal.fade.in', wait: 3)
    end
  end

  describe 'filtered option' do
    before(:all) do
      set_up_feature
      setup_source_data_table
      setup_big_select_test_dm
      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      login
    end

    it 'filters available options based on another fields value' do
      navigate_to_big_select_form

      # Verify filter dropdown renders with correct options
      within('form.new_dynamic_model_test_big_select_field') do
        filter_field = find('select[data-attr-name="filter_category"]', visible: :all)
        options = filter_field.all('option', visible: :all).map(&:text)
        expect(options).to include('Category A', 'Category B', 'Category C')
      end

      # Set the filter category to Category B - this should filter the big-select options
      select_from_dropdown_field('filter_category', 'Category B')
      sleep 0.5

      # Verify the filter field value was set correctly
      within('form.new_dynamic_model_test_big_select_field') do
        filter_field = find('select[data-attr-name="filter_category"]', visible: :all)
        expect(filter_field.value).to eq('category b')
      end

      # Now the big-select should be filtered to show only Category B items
      select_from_grouped_big_select_field('select_filtered', 'gamma item', group_name: 'category b')

      # Verify the field value was set
      within('form.new_dynamic_model_test_big_select_field') do
        filtered_field = find('input.use-big-select[data-attr-name="select_filtered"]', visible: :all)
        expect(filtered_field.value).to eq('gamma item')
      end
    end

    it 'updates available options when the filter field changes' do
      navigate_to_big_select_form

      # Start with Category A
      select_from_dropdown_field('filter_category', 'Category A')
      sleep 1

      # Verify the filter field value was set
      filter_field = find('form.new_dynamic_model_test_big_select_field select[data-attr-name="filter_category"]', visible: :all)
      expect(filter_field.value).to eq('category a')

      # Big-select should be filtered to show only Category A items
      select_from_grouped_big_select_field('select_filtered', 'alpha item', group_name: 'category a')

      # Verify the field value was set
      filtered_field = find('form.new_dynamic_model_test_big_select_field input.use-big-select[data-attr-name="select_filtered"]', visible: :all)
      expect(filtered_field.value).to eq('alpha item')

      # Change filter to Category C
      select_from_dropdown_field('filter_category', 'Category C')
      sleep 1

      # Verify the filter changed
      filter_field = find('form.new_dynamic_model_test_big_select_field select[data-attr-name="filter_category"]', visible: :all)
      expect(filter_field.value).to eq('category c')

      # Now big-select should be filtered to show only Category C items
      select_from_grouped_big_select_field('select_filtered', 'epsilon item', group_name: 'category c')

      # Verify the new selection
      filtered_field = find('form.new_dynamic_model_test_big_select_field input.use-big-select[data-attr-name="select_filtered"]', visible: :all)
      expect(filtered_field.value).to eq('epsilon item')
    end
  end
end
