# frozen_string_literal: true

# Browser regressions for dynamic-model show_if behavior, including the current
# template state supplied inline by a form after the page skeleton is stale.
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
      SetupHelper.reload_configs
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

  describe 'current form template state after a definition edit' do
    before(:all) do
      @previous_disable_vdef = Settings::DisableVDef
      change_setting('DisableVDef', false)
      @resource_name = :dynamic_model__test_show_if_fields
      set_up_feature
      @show_if_dm = setup_show_if_dm
      setup_access @resource_name, user: @user, app_type: @app_type
      SetupHelper.reload_configs
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      change_setting('DisableVDef', @previous_disable_vdef)
      DynamicModel.define_models
      Application.refresh_dynamic_defs
    end

    before(:each) do
      validate_setup
      login
    end

    it 'loads and executes the current show_if state inline with one form request and a matching CSP nonce' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
      dismiss_modal
      expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
      finish_page_loading
      finish_form_formatting
      expect(page).to have_css('body.status-compiled', wait: 60)

      state_name = "#{@show_if_dm.item_type_name}_default".underscore
      old_token = @show_if_dm.current_def_version.to_s
      old_state_present = page.evaluate_script(
        "!!(_fpa.state.template_config[#{state_name.to_json}] || {}).v#{old_token}"
      )
      expect(old_state_present).to be(true)
      page.execute_script(
        "window.__initialTemplateConfigV0 = _fpa.state.template_config[#{state_name.to_json}].v0"
      )
      page_nonce = page.evaluate_script("document.querySelector('script[nonce]').nonce")

      @master.current_user = @user
      2.times do |index|
        @master.dynamic_model__test_show_if_fields.create!(current_user: @user, main_field_1: "stale_#{index}")
      end

      old_options = @show_if_dm.options
      updated_options = old_options.gsub('show_conditional_1', 'show_after_config_edit')
                                   .gsub('conditional_field_1: Conditional Field 1',
                                         'conditional_field_1: Updated Conditional Field')
      previous_allow_dynamic_migrations = Settings::AllowDynamicMigrations
      cached_updated_at = @show_if_dm.updated_at
      begin
        change_setting('AllowDynamicMigrations', false)
        @show_if_dm.current_admin = @admin
        @show_if_dm.options = updated_options
        @show_if_dm.save!
        @show_if_dm.update_columns(updated_at: cached_updated_at + 3.seconds)
      ensure
        change_setting('AllowDynamicMigrations', previous_allow_dynamic_migrations)
      end
      DynamicModel.define_models
      Application.refresh_dynamic_defs
      AppControl.restart_server

      @show_if_dm.reload
      new_token = @show_if_dm.current_def_version.to_s
      expect(new_token).not_to eq(old_token)

      index_path = "/masters/#{@master_id}/#{@show_if_dm.base_route_segments}"
      page.execute_script(<<~JS)
        window.__reloadTemplateConfigRequests = [];
        window.__originalAjaxForReload = $.ajax;
        $.ajax = function (url, options) {
          var requestUrl = typeof url === 'string' ? url : (url && url.url);
          if (requestUrl && requestUrl.indexOf('/template_config') >= 0) {
            window.__reloadTemplateConfigRequests.push(requestUrl);
          }
          return window.__originalAjaxForReload.apply(this, arguments);
        };
        $.ajax(#{index_path.to_json}, { dataType: 'json' }).done(function (data) {
          _fpa.prepare_template_configs(data).then(function () {
            $.ajax = window.__originalAjaxForReload;
            window.__reloadedTemplateConfigV0 = _fpa.state.template_config[#{state_name.to_json}].v0;
            document.body.setAttribute('data-config-reload-complete', 'true');
          }).catch(function (error) {
            $.ajax = window.__originalAjaxForReload;
            document.body.setAttribute('data-config-reload-error', error.message);
          });
        }).fail(function (xhr) {
          $.ajax = window.__originalAjaxForReload;
          document.body.setAttribute('data-config-reload-error', 'index request failed: ' + xhr.status);
        });
      JS
      expect(page).to have_css('body[data-config-reload-complete="true"]', wait: 60)
      reload_config_requests = JSON.parse(page.evaluate_script('JSON.stringify(window.__reloadTemplateConfigRequests)'))
      expect(reload_config_requests.length).to eq(1)
      current_show_if_rule = page.evaluate_script(
        "_fpa.show_if.forms[#{state_name.to_json}].v#{new_token}.conditional_field_1.main_field_1"
      )
      expect(current_show_if_rule).to eq('show_after_config_edit')

      page.execute_script(<<~JS)
        window.__newFormRequests = [];
        window.__templateConfigRequests = [];
        var originalAjax = $.ajax;
        $.ajax = function (url, options) {
          var requestUrl = typeof url === 'string' ? url : (url && url.url);
          if (requestUrl && requestUrl.indexOf('/dynamic_model/test_show_if_fields/new') >= 0) {
            window.__newFormRequests.push(requestUrl);
          }
          if (requestUrl && requestUrl.indexOf('/template_config') >= 0) {
            window.__templateConfigRequests.push(requestUrl);
          }
          return originalAjax.apply(this, arguments);
        };
      JS

      new_button_css = '.details-item-type-dynamic-model--test-show-if-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_css)
      find(new_button_css).click

      new_form = new_form_css(@resource_name)
      expect(page).to have_css(new_form, wait: 20)
      state_script_id = "fpa_state_config--#{state_name}--v#{new_token}--form"
      inline_nonce = page.evaluate_script(
        "document.getElementById(#{state_script_id.to_json}) && " \
        "document.getElementById(#{state_script_id.to_json}).nonce"
      )

      expect(inline_nonce).to be_present
      expect(inline_nonce).to eq(page_nonce)
      expect(page.evaluate_script('window.__newFormRequests.length')).to eq(1)
      expect(page.evaluate_script('window.__templateConfigRequests.length')).to eq(0)
      current_state_present = page.evaluate_script(
        "!!_fpa.state.template_config[#{state_name.to_json}].v#{new_token}"
      )
      expect(current_state_present).to be(true)
      current_alias_preserved = page.evaluate_script(
        "window.__reloadedTemplateConfigV0 === _fpa.state.template_config[#{state_name.to_json}].v0"
      )
      expect(current_alias_preserved).to be(true)

      dm_form_mode :new
      within(new_form) do
        finish_form_formatting
        expect_block.not_to have_input_field('conditional_field_1')
        fill_in_field 'main_field_1', 'show_after_config_edit'
        expect_block.to have_input_field('conditional_field_1')
        expect_block.to have_field_label('conditional_field_1', 'Updated Conditional Field', mode: :new)
      end
    end
  end
end
