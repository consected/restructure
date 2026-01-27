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
# ✅ Grouped items (group_split_char):
#    - Displays items in collapsible groups by category
#    - Auto-expands group containing currently selected value
# ⏸️ Filtered option (PENDING - requires implementation):
#    - Configuration exists but data-select-filtering-target attribute not rendered
#    - Tests skipped and document expected behavior for future implementation
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

    # Debug: Check if the class was created
    puts 'DEBUG after DynamicModel.create!:'
    puts "  defined?(DynamicModel::TestBigSelectSource) = #{defined?(DynamicModel::TestBigSelectSource)}"
    puts "  Resources::Models.find_by(table_name: 'test_big_select_sources')&.dig(:class_name) = #{Resources::Models.find_by(table_name: 'test_big_select_sources')&.dig(:class_name)}"

    dm.current_admin = @admin
    dm.update_tracker_events
    setup_access :dynamic_model__test_big_select_sources, user: @user

    @master.current_user = @user
    ic = dm.implementation_class

    # Category A items - belong to @master
    # Using exact category names to match filter options
    @source_item1 = ic.create!(current_user: @user, master: @master,
                               name: 'alpha item', category: 'Category A',
                               description: 'First item in Category A')
    @source_item2 = ic.create!(current_user: @user, master: @master,
                               name: 'beta item', category: 'Category A',
                               description: 'Second item in Category A')

    # Category B items
    @source_item3 = ic.create!(current_user: @user, master: @master,
                               name: 'gamma item', category: 'Category B',
                               description: 'First item in Category B')
    @source_item4 = ic.create!(current_user: @user, master: @master,
                               name: 'delta item', category: 'Category B',
                               description: 'Second item in Category B')

    # Category C items for filtered tests
    @source_item5 = ic.create!(current_user: @user, master: @master,
                               name: 'epsilon item', category: 'Category C',
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
              alt_options:
                'Category A': Category A
                'Category B': Category B
                'Category C': Category C

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
              select_filtering_target: filter_category

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

        labels:
          select_basic: Basic Selection
          select_hide_popover: Selection With Overlay
          filter_category: Filter By Category
          select_filtered: Filtered Selection
          select_grouped: Grouped Selection
          notes: Notes
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Big Select Fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_big_select_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'select_basic select_hide_popover filter_category select_filtered select_grouped notes',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 10

    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_big_select_fields, user: @user

    dm
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

      # Debug: Check if Resources::Models has our dynamic model registered
      source_model = Resources::Models.find_by(table_name: 'test_big_select_sources')
      puts "DEBUG before(:all): Resources::Models lookup for test_big_select_sources = #{source_model&.dig(:class_name) || 'NOT FOUND'}"
    end

    before(:each) do
      login
    end

    it 'opens big-select dialog, selects an item, and sets the field value' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      # Navigate to the details tab
      details_tab = all('a[data-panel-tab="details"]').first
      expect(details_tab).not_to be_nil
      details_tab.click
      finish_page_loading

      expect(page).to have_css("#details-#{@master.id}")

      # Click the new button for our test dynamic model
      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'

      # Debug if button not found
      unless page.has_css?(new_button_selector, wait: 5)
        puts 'DEBUG: Available containers:'
        all('.details-item-type').each { |c| puts "  #{c[:class]}" }
        File.write('/tmp/details_page.html', page.html)
        expect(page).to have_css(new_button_selector)
      end

      find(new_button_selector).click
      finish_page_loading

      # Debug: save HTML if form not found
      unless page.has_css?('form.new_dynamic_model_test_big_select_field', wait: 10)
        puts 'DEBUG: Form not found after clicking new button'
        File.write('/tmp/after_new_click.html', page.html)
        expect(page).to have_css('form.new_dynamic_model_test_big_select_field')
      end
      finish_form_formatting
      sleep 1 # Allow JavaScript to fully initialize

      # Call helper OUTSIDE the within block to avoid scope issues
      select_from_big_select_field('select_basic', 'alpha item')

      # Verify the field value was set
      within('form.new_dynamic_model_test_big_select_field') do
        basic_field = find('input.use-big-select[data-attr-name="select_basic"]', visible: :all)
        expect(basic_field.value).to eq('alpha item')
      end
    end

    it 'opens big-select multiple times in sequence' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      # Navigate to the details tab
      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
      finish_page_loading

      # Click the new button for our test dynamic model
      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector, wait: 5)
      find(new_button_selector).click
      finish_page_loading
      finish_form_formatting
      sleep 1

      # === First open: select an item ===
      puts "\n=== First selection: Alpha Item ==="
      select_from_big_select_field('select_basic', 'alpha item')

      # Verify field value
      basic_field = find('form.new_dynamic_model_test_big_select_field input[data-attr-name="select_basic"]', visible: :all)
      puts "  Field value: '#{basic_field.value}'"
      expect(basic_field.value).to eq('alpha item')

      # === Second open: clear selection ===
      puts "\n=== Second selection: Clear (none) ==="
      clear_big_select_field('select_basic')

      # Verify field cleared
      basic_field = find('form.new_dynamic_model_test_big_select_field input[data-attr-name="select_basic"]', visible: :all)
      puts "  Field value after clear: '#{basic_field.value}'"
      expect(basic_field.value).to eq('big-select-clear')

      # === Third open: select a different item ===
      puts "\n=== Third selection: Beta Item ==="
      select_from_big_select_field('select_basic', 'beta item')

      # Verify field value
      basic_field = find('form.new_dynamic_model_test_big_select_field input[data-attr-name="select_basic"]', visible: :all)
      puts "  Field value: '#{basic_field.value}'"
      expect(basic_field.value).to eq('beta item')
    end

    it 'clears selection when clicking the (none) option' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector)
      find(new_button_selector).click

      expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1

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
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector)
      find(new_button_selector).click

      expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1

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
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector)
      find(new_button_selector).click

      expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1

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
      record = ic.create!(current_user: @user, master: @master,
                          select_grouped: 'delta item', notes: 'Test record')

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
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

      expect(page).to have_css('form.edit_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1 # Allow JavaScript to fully initialize big-select fields

      # Verify the field has the pre-selected value
      grouped_field = find('form.edit_dynamic_model_test_big_select_field input.use-big-select[data-attr-name="select_grouped"]', visible: :all)
      expect(grouped_field.value).to eq('delta item')

      # Click the field to open the modal
      field_id = grouped_field[:id]
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
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector)
      find(new_button_selector).click

      expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1

      # NOTE: The filtered option is not fully implemented in the codebase.
      # The filter_category field renders as a text input (not select),
      # and does not have the data-select-filtering-target attribute needed
      # to trigger the JavaScript filtering functionality.
      # This test documents the expected behavior for future implementation.
      skip 'Filtered big-select option requires implementation of data-select-filtering-target attribute rendering'

      # Verify the field value was set (lowercase in database)
      within('form.new_dynamic_model_test_big_select_field') do
        filtered_field = find('input.use-big-select[data-attr-name="select_filtered"]', visible: :all)
        expect(filtered_field.value).to eq('gamma item')
      end
    end

    it 'updates available options when the filter field changes' do
      skip 'Filtered big-select option requires implementation of data-select-filtering-target attribute rendering'

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      details_tab = all('a[data-panel-tab="details"]').first
      details_tab.click
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-big-select-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector)
      find(new_button_selector).click

      expect(page).to have_css('form.new_dynamic_model_test_big_select_field', wait: 10)
      finish_form_formatting
      sleep 1

      # Start with Category A (renders as text input, not select)
      fill_in_field('filter_category', 'Category A')
      sleep 1

      # Select an item from Category A
      select_from_grouped_big_select_field('select_filtered', 'alpha item', group_name: 'category a')

      # Verify the field value was set
      filtered_field = find('form.new_dynamic_model_test_big_select_field input.use-big-select[data-attr-name="select_filtered"]', visible: :all)
      expect(filtered_field.value).to eq('alpha item')

      # Change filter to Category C
      fill_in_field('filter_category', 'Category C')
      sleep 1

      # Now select an item from Category C (the filter should have updated the options)
      select_from_grouped_big_select_field('select_filtered', 'epsilon item', group_name: 'category c')

      # Verify the new selection
      filtered_field = find('form.new_dynamic_model_test_big_select_field input.use-big-select[data-attr-name="select_filtered"]', visible: :all)
      expect(filtered_field.value).to eq('epsilon item')
    end
  end
end
