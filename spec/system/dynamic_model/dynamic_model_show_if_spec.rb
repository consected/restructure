# frozen_string_literal: true

require 'rails_helper'

describe 'dynamic model show_if with embedded_item', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include TestShowIfDmSupport
  include DynamicModelExpectationsSupport

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin

    ms = Master.no_temporary_masters

    if ms.count == 0 || ms.first&.id.to_i < 1
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
    expect(@user.two_factor_auth_disabled).to be_truthy
  end

  describe 'dynamic model show_if conditions' do
    before(:all) do
      @resource_name = :dynamic_model__test_show_if_fields
      set_up_feature
      setup_show_if_dm

      expect(@resource_name).to eq :dynamic_model__test_show_if_fields
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    before :each do
      validate_setup
      login
    end

    # Test that show_if conditions work with basic field values
    it 'shows and hides fields based on simple show_if conditions' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master_id}")
      expect(page).not_to have_css('.alert')

      expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
      finish_page_loading
      finish_form_formatting

      expect(page).to have_css("#details-#{@master_id}")
      c = '.details-item-type-dynamic-model--test-show-if-fields .new-button-container a.btn'
      debug_state('test_show_if_fields', 'new button not found') unless has_css?(c)
      expect(page).to have_css(c)
      b = all(c).first
      expect(b).not_to be nil

      b.click
      expect(page).to have_css('form.new_dynamic_model_test_show_if_field')

      dm_form_mode :new

      within('form.new_dynamic_model_test_show_if_field') do
        # Initially, conditional fields should be hidden
        expect_block.not_to have_input_field('conditional_field_1')
        expect_block.not_to have_input_field('conditional_field_2')
        expect_block.not_to have_input_field('conditional_field_3')

        # Set main_field_1 to show conditional_field_1
        fill_in 'dynamic_model_test_show_if_field[main_field_1]', with: 'show_conditional_1'
        sleep 0.5

        # conditional_field_1 should now be visible
        expect_block.to have_input_field('conditional_field_1')

        # Fill in conditional_field_1
        fill_in 'dynamic_model_test_show_if_field[conditional_field_1]', with: 'conditional value 1'

        # Change main_field_1 to hide conditional_field_1 again
        fill_in 'dynamic_model_test_show_if_field[main_field_1]', with: 'other value'
        sleep 0.5

        # conditional_field_1 should be hidden
        expect_block.not_to have_input_field('conditional_field_1')

        # Test conditional_field_2 with select field
        select 'Option B', from: 'dynamic_model_test_show_if_field[main_field_2]'
        sleep 0.5

        # conditional_field_2 should now be visible
        expect_block.to have_input_field('conditional_field_2')

        # Fill in required fields and save
        fill_in 'dynamic_model_test_show_if_field[main_field_1]', with: 'test value'
        fill_in 'dynamic_model_test_show_if_field[conditional_field_2]', with: 'conditional value 2'

        click_button 'Save'
      end

      # Wait for save to complete
      sleep 1

      # Verify the record was saved
      dm_form_mode :show
      expect_block.to have_show_form

      # Verify the saved values are displayed
      expect(page).to have_content('test value')
      expect(page).to have_content('Option B')
      expect(page).to have_content('Conditional Value 2')
    end

    # Test that show_if conditions work with embedded_item data
    # This is a simplified validation test that confirms the configuration is properly set up
    it 'validates show_if configuration with embedded_item conditions' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master_id}")
      expect(page).not_to have_css('.alert')

      expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
      finish_page_loading
      finish_form_formatting
      expect(page).to have_css("#details-#{@master_id}")
      c = '.details-item-type-dynamic-model--test-show-if-fields .new-button-container a.btn'
      expect(page).to have_css(c)
      b = all(c).first
      debug_state('test_show_if_fields_2', 'new button not found') unless has_css?(c)
      expect(b).not_to be nil

      b.click
      expect(page).to have_css('form.new_dynamic_model_test_show_if_field')

      dm_form_mode :new

      within('form.new_dynamic_model_test_show_if_field') do
        # Verify that the form has loaded with the correct configuration
        # The embedded model should be available as a reference
        expect(page).to have_css('input[name="dynamic_model_test_show_if_field[main_field_1]"]')
        expect(page).to have_css('select[name="dynamic_model_test_show_if_field[main_field_2]"]')

        # conditional_field_3 has a complex condition with embedded_item
        # It should be hidden initially because conditions aren't met
        expect_block.not_to have_input_field('conditional_field_3')

        # Set main_field_1 to satisfy part of the condition
        fill_in 'dynamic_model_test_show_if_field[main_field_1]', with: 'show_conditional_3'
        sleep 0.5

        # conditional_field_3 should still be hidden because embedded_item conditions aren't met
        # (no embedded record exists yet)
        expect_block.not_to have_input_field('conditional_field_3')

        # Fill in basic fields and save
        fill_in 'dynamic_model_test_show_if_field[main_field_1]', with: 'test value'
        select 'Option A', from: 'dynamic_model_test_show_if_field[main_field_2]'

        click_button 'Save'
      end

      # Wait for save to complete
      sleep 1

      # Verify the record was saved
      dm_form_mode :show
      expect_block.to have_show_form
      expect(page).to have_content('test value')
    end
  end

  describe 'dynamic model show_if with any condition type' do
    before(:all) do
      @resource_name = :dynamic_model__test_show_if_fields
      set_up_feature
      setup_show_if_dm

      expect(@resource_name).to eq :dynamic_model__test_show_if_fields
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    before :each do
      validate_setup
      login
    end

    # Test that show_if works with 'any' condition type including embedded_item
    it 'shows field when any condition is satisfied' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
      dismiss_modal

      expect(page).to have_css("#master-#{@master_id}")
      expect(page).not_to have_css('.alert')

      expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
      finish_page_loading
      finish_form_formatting

      expect(page).to have_css("#details-#{@master_id}")
      c = '.details-item-type-dynamic-model--test-show-if-fields .new-button-container a.btn'
      debug_state('test_show_if_fields_3', 'details tab not found', force: true) unless has_css?(c)
      expect(page).to have_css(c)
      b = all(c).first
      expect(b).not_to be nil

      b.click

      expect(page).to have_css('form.new_dynamic_model_test_show_if_field')

      dm_form_mode :new

      within('form.new_dynamic_model_test_show_if_field') do
        # conditional_field_2 uses 'any' logic: main_field_2 = 'option_b' OR embedded_item.embedded_status = 'active'
        expect_block.not_to have_input_field('conditional_field_2')

        # Satisfy the first condition (main_field_2 = 'option_b')
        select 'Option B', from: 'dynamic_model_test_show_if_field[main_field_2]'
        sleep 0.5

        # conditional_field_2 should now be visible
        expect_block.to have_input_field('conditional_field_2')

        # Change to a different option
        select 'Option A', from: 'dynamic_model_test_show_if_field[main_field_2]'
        sleep 0.5

        # conditional_field_2 should be hidden again (unless embedded_item.embedded_status = 'active')
        expect_block.not_to have_input_field('conditional_field_2')

        # Clean up
        fill_in 'dynamic_model_test_show_if_field[main_field_1]', with: 'any test'
        select 'Option C', from: 'dynamic_model_test_show_if_field[main_field_2]'

        click_button 'Save'
      end

      sleep 1
      dm_form_mode :show
      expect_block.to have_show_form
    end
  end
end
