# frozen_string_literal: true

# System specs for dynamic model fields and views.
# Tests dynamic model creation with various field types, option type views,
# merge/override configurations, and different option type field names.
# Each describe block sets up its own user, master record, and dynamic model
# with specific configuration options, then exercises the UI through the
# details tab panel.

require 'rails_helper'

describe 'dynamic models fields and views', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include TestFieldsDmSupport
  include TestOptionTypesDmSupport
  include DynamicModelExpectationsSupport

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin

    ms = Master.no_temporary_masters

    if ms.count == 0 || ms.first || ms.first.id < 1
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

  describe 'dynamic model fields for a default view' do
    before(:all) do
      resource_name = :dynamic_model__test_all_v2_fields
      set_up_feature
      setup_fields_dm

      expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id))
      setup_access resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    before :each do
      validate_setup
      login
    end

    # Test creation of a dynamic model and show a form with all available field types
    # Although we don't exercise all the fields for data entry, showing them ensures that
    # there isn't a regression in the UI.
    it 'creates a dynamic model' do
      # Validate user has expected access before browser interaction
      expect(@user.has_access_to?(:access, :table, :dynamic_model__test_all_v2_fields)).to be_truthy
      expect(@user.has_access_to?(:create, :table, :dynamic_model__test_all_v2_fields)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab and wait for the panel to fully expand
      expand_master_record_tab('details')

      c = '.details-item-type-dynamic-model--test-all-v2-fields .new-button-container a.btn'
      expect(page).to have_css(c)
      b = all(c).first
      expect(b).not_to be nil

      b.click
      expect(page).to have_css('form.new_dynamic_model_test_all_v2_field', wait: 10)
      new_num = rand(100_000_000..999_999_999)
      within('form.new_dynamic_model_test_all_v2_field') do
        sleep 2
        # Basic string fields
        fill_in 'A string', with: 'Test string value'
        fill_in 'A string2', with: 'Another string value'
        fill_in 'A mixed string', with: 'Mixed string 123'
        fill_in 'A unknown', with: 'Unknown type value'

        # Numeric fields
        fill_in 'A int', with: '42'
        fill_in 'A float', with: '3.14159'
        fill_in 'A timestamp', with: '1691534400'
        fill_in 'A decimal', with: '123.45'

        # Date and time fields
        fill_in 'A date', with: '2025-08-15'
        fill_in 'A time', with: '2025-08-15 14:30:00'
        fill_in 'Done when', with: '2025-09-01'

        # Boolean field
        check 'A boolean'

        # JSON/JSONB fields
        fill_in 'Json', with: '{"key": "value"}'
        fill_in 'Jsonb', with: '{"name": "Test", "active": true}'

        # Classification fields
        select 'General', from: 'Protocol'
        sleep 0.5
        select 'Communications', from: 'status'
        sleep 0.5
        select 'communication (outgoing)', from: 'method'
        fill_in 'College', with: 'Harvard University'

        # Address fields
        select 'Massachusetts', from: 'State'
        select 'United Kingdom', from: 'Country'
        fill_in 'Zip', with: '02115'

        # select 'Primary', from: 'Rank'
        # select 'Direct contact', from: 'Source'

        # Select fields
        # select 'Admin User', from: 'Select user with role admin' if page.has_select?('Select user with role admin')
        select 'Choice 2', from: 'Select value' if page.has_select?('Select value')

        # Yes/No fields
        select 'Yes', from: 'Done yes no' if page.has_select?('Done yes no')
        select 'No', from: 'Done no yes' if page.has_select?('Done no yes')
        select 'Yes', from: 'Done blank yes no' if page.has_select?('Done blank yes no')
        select "Don't Know", from: 'Done yes no dont know' if page.has_select?('Done yes no dont know')
        select 'Yes', from: 'Done blank yes no dont know' if page.has_select?('Done blank yes no dont know')

        # True/False field
        select 'True', from: 'Done true false' if page.has_select?('Done true false')

        # Text area fields
        fill_in 'Some description', with: 'This is a detailed description with multiple lines.\nSecond line of description.'
        fill_in 'Some details', with: 'These are some details about the record.'
        fill_in 'Some notes', with: 'Important notes about this record.'
        fill_in 'Description', with: 'Another description field value.'
        fill_in 'Notes', with: 'Additional notes.'
        fill_in 'Message', with: 'A message for this record.'

        # URL and link fields
        fill_in 'A link', with: 'https://example.com/link'
        fill_in 'A url', with: 'https://example.org/page'

        # Other string fields
        # fill_in 'Player contact rank', with: 'Primary'
        fill_in 'Some year', with: '2025'
        fill_in 'Email', with: 'test@example.com'
        fill_in 'Phone', with: '555-123-4567'
        # fill_in 'Rec type', with: 'Primary'

        # Fields that reference test_with_id_recs
        if page.has_select?('Select record from table test with id recs')
          select 'test value 1', from: 'Select record from table test with id recs'
        end
        if page.has_select?('Select record from test with id recs')
          select 'Test Name 2', from: 'Select record from test with id recs'
        end
        if page.has_select?('Select record id from test with id recs')
          select '3', from: 'Select record id from test with id recs'
        end

        # fill_in 'Fixed value', with: 'Predefined value'

        # E signature fields
        # fill_in 'E signed document', with: 'consent_form.pdf'
        # fill_in 'E signed how', with: 'Electronic signature'

        # Multi-select array fields
        # We'll use the label selectors, but keep the conditional logic
        # if page.has_select?('Multi editable choices abc', multiple: true)
        #   select 'Choice A', from: 'Multi editable choices abc'
        #   select 'Choice B', from: 'Multi editable choices abc'
        # else
        #   # Fallback for JavaScript-enhanced fields
        #   find('label', text: 'Multi editable choices abc').click
        #   within('.select2-dropdown, .dropdown-menu, .choices__list') do
        #     find('li, option, div', text: 'Choice A').click
        #     find('li, option, div', text: 'Choice B').click
        #   end
        #   # Close dropdown if needed
        #   find('body').send_keys(:escape)
        # end

        # Similar approach for other multi-selects
        # if page.has_select?('Multi editable list def', multiple: true)
        #   select 'Option X', from: 'Multi editable list def'
        #   select 'Option Y', from: 'Multi editable list def'
        # end

        # if page.has_select?('Multi player contact ranks', multiple: true)
        #   select 'Primary', from: 'Multi player contact ranks'
        #   select 'Secondary', from: 'Multi player contact ranks'
        # end

        # Tag select fields
        # if page.has_select?('Tag select users with role admin', multiple: true)
        #   select 'Admin 1', from: 'Tag select users with role admin'
        #   select 'Admin 2', from: 'Tag select users with role admin'
        # end

        # if page.has_select?('Tag select some values', multiple: true)
        #   select 'Value A', from: 'Tag select some values'
        #   select 'Value B', from: 'Tag select some values'
        # end

        # Multi-select references
        # if page.has_select?('Pick multiple records from table test with id recs', multiple: true)
        #   select 'test value 1', from: 'Pick multiple records from table test with id recs'
        #   select 'test value 3', from: 'Pick multiple records from table test with id recs'
        # end

        # Tag select references
        # if page.has_select?('Tag select record from table test with id recs', multiple: true)
        #   select 'test value 2', from: 'Tag select record from table test with id recs'
        # end

        # if page.has_select?('Tag select record from test with id recs', multiple: true)
        #   select 'Test Name 1', from: 'Tag select record from test with id recs'
        # end

        # if page.has_select?('Tag select record id from test with id recs', multiple: true)
        #   select '2', from: 'Tag select record id from test with id recs'
        # end

        sleep 0.5
        click_on 'Save'
      end
    end
  end

  describe 'dynamic model fields for multiple views' do
    before(:all) do
      @resource_name = :dynamic_model__test_multi_options
      set_up_feature
      setup_multi_option_types_dm

      expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id))
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    before :each do
      validate_setup
      login
    end

    # Test creation of a dynamic model and show a form with all available field types
    # Although we don't exercise all the fields for data entry, showing them ensures that
    # there isn't a regression in the UI.
    it 'creates a dynamic model with option_type views' do
      # Validate user has expected access before browser interaction
      expect(@user.has_access_to?(:access, :table, @resource_name)).to be_truthy
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab and wait for the panel to fully expand
      expand_master_record_tab('details')

      c = '.details-item-type-dynamic-model--test-multi-options .new-button-container a.btn'
      expect(page).to have_css(c)
      b = all(c).first
      expect(b).not_to be nil

      # Start by adding a new item
      # The "new" form will be set to view_option = 'default'
      # This shows a placeholder, 3 fields and a placeholder.
      # The third field is only shown if the second field is set to 'Choice 2'
      b.click

      #
      # View Type: default
      #
      expect_block.to have_new_form

      dm_form_mode :new

      within(new_form_css) do
        sleep 2
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        # Initially, field 3 should be hidden
        expect_block.not_to have_input_field(field_name)

        # The final placeholder shows
        expect_block.to have_caption_before('placeholder_default_bottom', 'This is the default view placeholder at the bottom')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        fill_in 'Field 1 Label', with: 'Test string value'
        select 'Choice 1', from: 'Field 2 Label'
        sleep 1

        field_name = 'field_3'

        # Check third field is not shown
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_field_label(field_name)

        select 'Choice 2', from: 'Field 2 Label'
        sleep 1
        # Now the third field should appear
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')

        click_on 'Save'
      end

      dm_form_mode :show
      expect_block.to have_show_form(@resource_name)

      expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

      field_name = 'field_1'
      expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
      expect_block.to have_field_label(field_name, 'Field 1 Label')
      expect_block.to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 2 Label')
      expect_block.to have_input_field(field_name, tagname: 'select')

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 3 Label')

      # Remaining fields are not listed
      field_name = 'field_4'
      expect_block.not_to have_input_field(field_name)
      field_name = 'field_5'
      expect_block.not_to have_input_field(field_name)

      field_name = 'option_type'
      expect_block.to have_field_label(field_name, 'View Type')
      expect_block.to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_view_1_top')
      expect_block.not_to have_caption_before('placeholder_view_1_bottom')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(@resource_name)

      within(edit_form_css) do
        dm_form_mode :edit
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        # Now set the view type to 'view_1', which should show a different form in the next series of steps
        fill_in 'View Type', with: 'view_1'
        click_on 'Save'
      end

      #
      # View Type: view_1
      #
      dm_form_mode :show
      expect_block.to have_show_form
      expect_block.to have_show_form(option_type: 'view_1')

      expect_block.to have_caption_before('placeholder_view_1_top', 'This is view 1 placeholder at the top')

      field_name = 'field_1'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 1 Label')
      expect_block.to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 2 Label')
      expect_block.to have_input_field(field_name, tagname: 'select')

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.not_to have_input_field(field_name)

      # Remaining fields are not listed
      field_name = 'field_4'
      expect_block.not_to have_input_field(field_name)
      field_name = 'field_5'
      expect_block.not_to have_input_field(field_name)

      field_name = 'option_type'
      expect_block.not_to have_field_label(field_name)
      expect_block.not_to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_default_top')
      expect_block.not_to have_caption_before('placeholder_default_bottom')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(option_type: 'view_1')

      within(edit_form_css) do
        dm_form_mode :edit
        expect_block.to have_caption_before('placeholder_view_1_top', 'This is view 1 placeholder at the top')

        field_name = 'field_1'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_input_field(field_name)

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'option_type'
        expect_block.not_to have_field_label(field_name)
        expect_block.not_to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_default_top')
        expect_block.not_to have_caption_before('placeholder_default_bottom')

        select 'Choice v1-1', from: 'Field 2 Label'
        select 'Choice v1-2', from: 'Field 2 Label'
        select 'Choice v1-3', from: 'Field 2 Label'
        click_on 'Save'
      end
    end

    # Test creation of a dynamic model that incorporates
    # options with _default..., _merge... and _override.
    # Also tests _configurations...
    it 'creates a dynamic model and tests _merge... and _override' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      dm_def = DynamicModel::TestMultiOption.definition
      expect(dm_def.configurations[:use_current_version]).to be true
      expect(dm_def.configurations[:option_type_attr_name]).to eq 'option_type'
      expect(dm_def.option_type_config_for(:test_defaults_only).view_options).to eq(data_attribute: 'field_1')
      expect(dm_def.option_type_config_for(:test_defaults_only).field_options).to eq(field_1: { no_downcase: true })
      expect(dm_def.option_type_config_for(:test_defaults_only).labels).to eq(field_1: 'Field 1 Label', field_2: 'Field 2 Label', field_3: 'Field 3 Label', field_4: 'Field 4 Label', field_5: 'Field 5 Label', option_type: 'View Type')

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab and wait for the panel to fully expand
      expand_master_record_tab('details')

      c = '.details-item-type-dynamic-model--test-multi-options .new-button-container a.btn'
      expect(page).to have_css(c)
      b = all(c).first
      expect(b).not_to be nil

      # Start by adding a new item
      # The "new" form will be set to view_option = 'default'
      # This shows a placeholder, 3 fields and a placeholder.
      # The third field is only shown if the second field is set to 'Choice 2'
      b.click

      #
      # View Type: default
      #
      expect_block.to have_new_form

      dm_form_mode :new

      within(new_form_css) do
        sleep 2
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        # Initially, field 3 should be hidden
        expect_block.not_to have_input_field(field_name)

        # The final placeholder shows
        expect_block.to have_caption_before('placeholder_default_bottom', 'This is the default view placeholder at the bottom')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        fill_in 'Field 1 Label', with: 'Test string value'
        select 'Choice 1', from: 'Field 2 Label'
        sleep 1

        field_name = 'field_3'

        # Check third field is not shown
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_field_label(field_name)

        select 'Choice 2', from: 'Field 2 Label'
        sleep 1
        # Now the third field should appear
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')
        fill_in 'View Type', with: 'view_3'

        click_on 'Save'
      end

      dm_form_mode :show
      expect_block.to have_show_form(@resource_name)

      field_name = 'field_1'
      expect_block.not_to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_input_field(field_name)

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'field 3 in view 3')

      field_name = 'field_4'
      expect_block.to have_input_field(field_name)
      # field_name = 'field_5'
      # expect_block.to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_view_1_top')
      expect_block.not_to have_caption_before('placeholder_view_1_bottom')

      expect_block.to have_caption_before('placeholder_merge_default', 'This caption will remain set')
      expect_block.to have_caption_before('placeholder_merge_override', 'Override with this caption')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(@resource_name)

      # Set the value of field_5 to test the _override option.
      within(edit_form_css) do
        sleep 2
        fill_in 'Field 5', with: 'never valid'
        click_on 'Save'
      end

      expect(page).to have_css('.error-help', text: 'Entry is invalid. Expected value not to be : never valid')
    end
  end

  describe 'dynamic model fields for multiple views using a different option type field name' do
    before(:all) do
      @resource_name = :dynamic_model__test_multi_options
      set_up_feature
      setup_multi_option_types_dm(option_type_field: 'alt_option_type')

      expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id))
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    before :each do
      validate_setup
      login
    end

    # Test creation of a dynamic model and show a form with all available field types
    # Although we don't exercise all the fields for data entry, showing them ensures that
    # there isn't a regression in the UI.
    it 'creates a dynamic model with option type views using a different option type field' do
      # Validate user has expected access before browser interaction
      expect(@user.has_access_to?(:access, :table, @resource_name)).to be_truthy
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab and wait for the panel to fully expand
      expand_master_record_tab('details')

      c = '.details-item-type-dynamic-model--test-multi-options .new-button-container a.btn'
      expect(page).to have_css(c)
      b = all(c).first
      expect(b).not_to be nil

      # Start by adding a new item
      # The "new" form will be set to view_option = 'default'
      # This shows a placeholder, 3 fields and a placeholder.
      # The third field is only shown if the second field is set to 'Choice 2'
      b.click

      #
      # View Type: default
      #
      expect_block.to have_new_form

      dm_form_mode :new

      within(new_form_css) do
        sleep 2
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        # Initially, field 3 should be hidden
        expect_block.not_to have_input_field(field_name)

        # The final placeholder shows
        expect_block.to have_caption_before('placeholder_default_bottom', 'This is the default view placeholder at the bottom')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'alt_option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        fill_in 'Field 1 Label', with: 'Test string value'
        select 'Choice 1', from: 'Field 2 Label'
        sleep 1

        field_name = 'field_3'

        # Check third field is not shown
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_field_label(field_name)

        select 'Choice 2', from: 'Field 2 Label'
        sleep 1
        # Now the third field should appear
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')

        click_on 'Save'
      end

      dm_form_mode :show
      expect_block.to have_show_form(@resource_name)

      expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

      field_name = 'field_1'
      expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
      expect_block.to have_field_label(field_name, 'Field 1 Label')
      expect_block.to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 2 Label')
      expect_block.to have_input_field(field_name, tagname: 'select')

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 3 Label')

      # Remaining fields are not listed
      field_name = 'field_4'
      expect_block.not_to have_input_field(field_name)
      field_name = 'field_5'
      expect_block.not_to have_input_field(field_name)

      field_name = 'alt_option_type'
      expect_block.to have_field_label(field_name, 'View Type')
      expect_block.to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_view_1_top')
      expect_block.not_to have_caption_before('placeholder_view_1_bottom')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(@resource_name)

      within(edit_form_css) do
        dm_form_mode :edit
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'alt_option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        # Now set the view type to 'view_1', which should show a different form in the next series of steps
        fill_in 'View Type', with: 'view_1'
        click_on 'Save'
      end

      #
      # View Type: view_1
      #
      dm_form_mode :show
      expect_block.to have_show_form
      expect_block.to have_show_form(option_type: 'view_1')

      expect_block.to have_caption_before('placeholder_view_1_top', 'This is view 1 placeholder at the top')

      field_name = 'field_1'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 1 Label')
      expect_block.to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 2 Label')
      expect_block.to have_input_field(field_name, tagname: 'select')

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.not_to have_input_field(field_name)

      # Remaining fields are not listed
      field_name = 'field_4'
      expect_block.not_to have_input_field(field_name)
      field_name = 'field_5'
      expect_block.not_to have_input_field(field_name)

      field_name = 'alt_option_type'
      expect_block.not_to have_field_label(field_name)
      expect_block.not_to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_default_top')
      expect_block.not_to have_caption_before('placeholder_default_bottom')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(option_type: 'view_1')

      within(edit_form_css) do
        dm_form_mode :edit
        expect_block.to have_caption_before('placeholder_view_1_top', 'This is view 1 placeholder at the top')

        field_name = 'field_1'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_input_field(field_name)

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'alt_option_type'
        expect_block.not_to have_field_label(field_name)
        expect_block.not_to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_default_top')
        expect_block.not_to have_caption_before('placeholder_default_bottom')

        select 'Choice v1-1', from: 'Field 2 Label'
        select 'Choice v1-2', from: 'Field 2 Label'
        select 'Choice v1-3', from: 'Field 2 Label'
        click_on 'Save'
      end
    end
  end

  describe 'dynamic model fields for multiple views using a different default option type name' do
    before(:all) do
      @resource_name = :dynamic_model__test_multi_options
      set_up_feature
      setup_multi_option_types_dm(option_type_field: 'alt_option_type', default_option_type_name: 'alt_default')

      expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id))
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    before :each do
      validate_setup
      login
    end

    # Test creation of a dynamic model and show a form with all available field types
    # Although we don't exercise all the fields for data entry, showing them ensures that
    # there isn't a regression in the UI.
    it 'creates a dynamic model with option type views using a different default option type name' do
      # Validate user has expected access before browser interaction
      expect(@user.has_access_to?(:access, :table, @resource_name)).to be_truthy
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab and wait for the panel to fully expand
      expand_master_record_tab('details')

      c = '.details-item-type-dynamic-model--test-multi-options .new-button-container a.btn'
      expect(page).to have_css(c, wait: 10)
      b = all(c).first
      expect(b).not_to be nil

      # Start by adding a new item
      # The "new" form will be set to view_option = 'alt_default'
      # This shows a placeholder, 3 fields and a placeholder.
      # The third field is only shown if the second field is set to 'Choice 2'
      b.click

      #
      # View Type: alt_default
      #
      expect_block.to have_new_form

      dm_form_mode :new

      within(new_form_css) do
        sleep 2
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        # Initially, field 3 should be hidden
        expect_block.not_to have_input_field(field_name)

        # The final placeholder shows
        expect_block.to have_caption_before('placeholder_default_bottom', 'This is the default view placeholder at the bottom')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'alt_option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        fill_in 'Field 1 Label', with: 'Test string value'
        select 'Choice 1', from: 'Field 2 Label'
        sleep 1

        field_name = 'field_3'

        # Check third field is not shown
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_field_label(field_name)

        select 'Choice 2', from: 'Field 2 Label'
        sleep 1
        # Now the third field should appear
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')

        click_on 'Save'
      end

      dm_form_mode :show
      expect_block.to have_show_form

      expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

      field_name = 'field_1'
      expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
      expect_block.to have_field_label(field_name, 'Field 1 Label')
      expect_block.to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 2 Label')
      expect_block.to have_input_field(field_name, tagname: 'select')

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 3 Label')

      # Remaining fields are not listed
      field_name = 'field_4'
      expect_block.not_to have_input_field(field_name)
      field_name = 'field_5'
      expect_block.not_to have_input_field(field_name)

      field_name = 'alt_option_type'
      expect_block.to have_field_label(field_name, 'View Type')
      expect_block.to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_view_1_top')
      expect_block.not_to have_caption_before('placeholder_view_1_bottom')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(@resource_name)

      within(edit_form_css) do
        dm_form_mode :edit
        expect_block.to have_caption_before('placeholder_default_top', 'This is the default view placeholder at the top')

        field_name = 'field_1'
        expect_block.to have_caption_before(field_name, 'This is the default view caption for field 1')
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 3 Label')

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'alt_option_type'
        expect_block.to have_field_label(field_name, 'View Type')
        expect_block.to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_view_1_top')
        expect_block.not_to have_caption_before('placeholder_view_1_bottom')

        # Now set the view type to 'view_1', which should show a different form in the next series of steps
        fill_in 'View Type', with: 'view_1'
        click_on 'Save'
      end

      #
      # View Type: view_1
      #
      dm_form_mode :show
      expect_block.to have_show_form
      expect_block.to have_show_form(option_type: 'view_1')

      expect_block.to have_caption_before('placeholder_view_1_top', 'This is view 1 placeholder at the top')

      field_name = 'field_1'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 1 Label')
      expect_block.to have_input_field(field_name)

      field_name = 'field_2'
      expect_block.not_to have_caption_before(field_name)
      expect_block.to have_field_label(field_name, 'Field 2 Label')
      expect_block.to have_input_field(field_name, tagname: 'select')

      field_name = 'field_3'
      expect_block.not_to have_caption_before(field_name)
      expect_block.not_to have_input_field(field_name)

      # Remaining fields are not listed
      field_name = 'field_4'
      expect_block.not_to have_input_field(field_name)
      field_name = 'field_5'
      expect_block.not_to have_input_field(field_name)

      field_name = 'alt_option_type'
      expect_block.not_to have_field_label(field_name)
      expect_block.not_to have_input_field(field_name)

      expect_block.not_to have_caption_before('placeholder_default_top')
      expect_block.not_to have_caption_before('placeholder_default_bottom')

      # Click the edit button and check the edit form reappears correctly
      click_edit_button_in(show_form_css)
      expect_block.to have_edit_form(option_type: 'view_1')

      within(edit_form_css) do
        dm_form_mode :edit
        expect_block.to have_caption_before('placeholder_view_1_top', 'This is view 1 placeholder at the top')

        field_name = 'field_1'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 1 Label')
        expect_block.to have_input_field(field_name)

        field_name = 'field_2'
        expect_block.not_to have_caption_before(field_name)
        expect_block.to have_field_label(field_name, 'Field 2 Label')
        expect_block.to have_input_field(field_name, tagname: 'select')

        field_name = 'field_3'
        expect_block.not_to have_caption_before(field_name)
        expect_block.not_to have_input_field(field_name)

        # Remaining fields are not listed
        field_name = 'field_4'
        expect_block.not_to have_input_field(field_name)
        field_name = 'field_5'
        expect_block.not_to have_input_field(field_name)

        field_name = 'alt_option_type'
        expect_block.not_to have_field_label(field_name)
        expect_block.not_to have_input_field(field_name)

        expect_block.not_to have_caption_before('placeholder_default_top')
        expect_block.not_to have_caption_before('placeholder_default_bottom')

        select 'Choice v1-1', from: 'Field 2 Label'
        select 'Choice v1-2', from: 'Field 2 Label'
        select 'Choice v1-3', from: 'Field 2 Label'
        click_on 'Save'
      end
    end
  end
end
