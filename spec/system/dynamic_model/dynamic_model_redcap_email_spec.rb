# frozen_string_literal: true

# System specs for dynamic model fields configured with redcap_email and redcap_phone field types.
# Tests that email and phone values display correctly in both show and edit modes.
#
# Background (GitHub Issue #558):
# When a dynamic model field uses `edit_as: field_type: redcap_email` with `alt_options: {}`,
# the email value appears blank in "show" mode. The root cause is that the show template's
# alt_options handler catches the field (since alt_options is present, even if empty) before
# the default text renderer. The fix adds a `^redcap_` catch-all handler before alt_options,
# so redcap text-validation field types render their values correctly.

require 'rails_helper'

describe 'dynamic model redcap email and phone fields', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
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

    set_notes_field_format(markdown: false)
  end

  describe 'redcap_email and redcap_phone field types in show and edit modes' do
    before(:all) do
      change_setting('AllowDynamicMigrations', true)

      @resource_name = :dynamic_model__test_redcap_email_fields

      set_up_feature
      setup_redcap_email_dm
      SetupHelper.reload_configs
      expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id))
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      change_setting('AllowDynamicMigrations', false)
    end

    before(:each) do
      validate_setup
      login
    end

    it 'displays redcap_email and redcap_phone values in show mode after saving a record' do
      expect(@user.has_access_to?(:access, :table, @resource_name)).to be_truthy
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab
      expand_master_record_tab('details')

      # Click the new button for the dynamic model
      new_btn_css = '.details-item-type-dynamic-model--test-redcap-email-fields .new-button-container a.btn'
      expect(page).to have_css(new_btn_css)
      btn = all(new_btn_css).first
      expect(btn).not_to be nil
      btn.click

      # Fill in the new form
      new_form = new_form_css(@resource_name)
      expect(page).to have_css(new_form, wait: 10)

      dm_form_mode :new

      within(new_form) do
        finish_form_formatting
        fill_in_field 'email_address', 'testuser@example.com'
        fill_in_field 'phone_number', '(555)123-4567'
        fill_in_field 'description', 'Test redcap email record'
        click_on 'Save'
      end

      # After save, the record should appear in show mode
      finish_page_loading
      dm_form_mode :show
      show_css = show_form_css(@resource_name)
      expect(page).to have_css(show_css, wait: 10)

      within(show_css) do
        # Verify the email address value is visible in show mode
        # The <strong> tag should contain the email value, not be empty
        email_field = find("[data-field-name='email_address']")
        email_strong = email_field.find('strong')
        expect(email_strong.text.strip).to eq('testuser@example.com'),
                                           "Expected email 'testuser@example.com' visible in show mode <strong>, got '#{email_strong.text.strip}' (bug #558: redcap_email shows blank)"

        # Verify the phone number value is visible in show mode
        phone_field = find("[data-field-name='phone_number']")
        phone_strong = phone_field.find('strong')
        expect(phone_strong.text.strip).not_to be_empty,
                                               'Expected phone number visible in show mode <strong>, got blank (bug #558: redcap_phone shows blank)'

        # Verify description is visible (standard field, capitalized on display)
        expect(page).to have_css("[data-field-name='description']", text: 'Test redcap email record')
      end
    end

    it 'displays redcap_email and redcap_phone values in edit mode' do
      expect(@user.has_access_to?(:access, :table, @resource_name)).to be_truthy
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      # Expand the details tab
      expand_master_record_tab('details')

      # Click the new button
      new_btn_css = '.details-item-type-dynamic-model--test-redcap-email-fields .new-button-container a.btn'
      expect(page).to have_css(new_btn_css)
      btn = all(new_btn_css).first
      expect(btn).not_to be nil
      btn.click

      # Fill in and save a record first
      new_form = new_form_css(@resource_name)
      expect(page).to have_css(new_form, wait: 10)

      dm_form_mode :new

      within(new_form) do
        finish_form_formatting
        fill_in_field 'email_address', 'editcheck@example.com'
        fill_in_field 'phone_number', '(555)987-6543'
        fill_in_field 'description', 'Edit mode test record'
        click_on 'Save'
      end

      # Wait for the show form to render after save
      finish_page_loading
      dm_form_mode :show
      show_css = show_form_css(@resource_name)
      expect(page).to have_css(show_css, wait: 10)

      # Click edit to go into edit mode
      click_edit_button_in(show_css)

      dm_form_mode :edit
      edit_css = edit_form_css(@resource_name)
      expect(page).to have_css(edit_css, wait: 10)

      within(edit_css) do
        expect(element_for_field('email_address').value).to eq('editcheck@example.com')
        expect(element_for_field('phone_number').value).not_to be_empty
      end
    end
  end

  describe 'field named email with redcap_email edit_as type' do
    before(:all) do
      change_setting('AllowDynamicMigrations', true)

      @resource_name_named = :dynamic_model__test_redcap_email_nameds

      set_up_feature
      setup_redcap_email_named_email_dm
      SetupHelper.reload_configs

      expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id))
      setup_access @resource_name_named, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name_named)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      change_setting('AllowDynamicMigrations', false)
    end

    before(:each) do
      validate_setup
      login
    end

    it 'displays email value in show mode when field is named email' do
      expect(@user.has_access_to?(:access, :table, @resource_name_named)).to be_truthy
      expect(@user.has_access_to?(:create, :table, @resource_name_named)).to be_truthy

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master.id}")
      expect(page).not_to have_css('.alert')

      expand_master_record_tab('details')

      new_btn_css = '.details-item-type-dynamic-model--test-redcap-email-nameds .new-button-container a.btn'
      expect(page).to have_css(new_btn_css)
      btn = all(new_btn_css).first
      expect(btn).not_to be nil
      btn.click

      new_form = new_form_css(@resource_name_named)
      expect(page).to have_css(new_form, wait: 10)

      dm_form_mode :new

      within(new_form) do
        finish_form_formatting
        fill_in_field 'email', 'namedfield@example.com'
        fill_in_field 'phone', '(555)111-2222'
        fill_in_field 'description', 'Test named email field'
        click_on 'Save'
      end

      finish_page_loading
      dm_form_mode :show
      show_css = show_form_css(@resource_name_named)
      expect(page).to have_css(show_css, wait: 10)

      within(show_css) do
        email_field = find("[data-field-name='email']")
        email_strong = email_field.find('strong')
        expect(email_strong.text.strip).to eq('namedfield@example.com'),
                                           "Expected email 'namedfield@example.com' visible in show mode, got '#{email_strong.text.strip}'"
      end
    end
  end

  private

  def setup_redcap_email_dm
    # Clean up any existing definitions with this table name
    DynamicModel.active.where(table_name: 'test_redcap_email_fields').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestRedcapEmailField) if defined?(DynamicModel::TestRedcapEmailField)

    dm_options = <<~YAML
      _configurations: {}
      default:
        field_configs:
          email_address:
            labels: Email Address
            field_options:
              no_downcase: true
              edit_as:
                field_type: redcap_email
                alt_options: {}
          phone_number:
            labels: Phone Number
            field_options:
              edit_as:
                field_type: redcap_phone
                alt_options: {}
          description:
            labels: Description
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Redcap Email',
                              schema_name: 'dynamic_test',
                              table_name: 'test_redcap_email_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'email_address phone_number description',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 10

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a DynamicModel

    app = @user.app_type
    expect(app).to be_a Admin::AppType
    Admin::PageLayout.active.where(app_type_id: app.id).each do |p|
      p.disable! @admin
    end

    setup_access :dynamic_model__test_redcap_email_fields, user: @user

    dm
  end

  def setup_redcap_email_named_email_dm
    # Clean up any existing definitions with this table name
    DynamicModel.active.where(table_name: 'test_redcap_email_nameds').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestRedcapEmailNamed) if defined?(DynamicModel::TestRedcapEmailNamed)

    dm_options = <<~YAML
      _configurations: {}
      default:
        field_configs:
          email:
            labels: Email
            field_options:
              no_downcase: true
              edit_as:
                field_type: redcap_email
                alt_options: {}
            caption_before: 'E-mail '
          phone:
            labels: Phone
            field_options:
              edit_as:
                field_type: redcap_phone
          description:
            labels: Description
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Redcap Email Named',
                              schema_name: 'dynamic_test',
                              table_name: 'test_redcap_email_nameds',
                              category: :details,
                              options: dm_options,
                              field_list: 'email phone description',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 11

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a DynamicModel

    app = @user.app_type
    expect(app).to be_a Admin::AppType

    setup_access :dynamic_model__test_redcap_email_nameds, user: @user

    dm
  end
end
