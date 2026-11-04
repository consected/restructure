# frozen_string_literal: true

# Browser regressions for dynamic-model show_if behavior and versioned template config
# loading after definition edits. An edit form opened first after a config edit promotes
# the list-level v0 alias to the new token, so list chrome does not stay on the old config.
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
      @show_if_definitions = DynamicModel.active.where(
        table_name: %w[test_show_if_fields test_show_if_embedded_recs]
      ).to_a
      setup_access @resource_name, user: @user, app_type: @app_type
      SetupHelper.reload_configs
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      @show_if_definitions.each { |definition| definition.reload.disable!(@admin) }
      change_setting('DisableVDef', @previous_disable_vdef)
      DynamicModel.define_models
      Application.refresh_dynamic_defs
    end

    before(:each) do
      validate_setup
      login
    end

    def update_show_if_definition_options(updated_options)
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
      update_show_if_definition_options(updated_options)
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
      current_alias_matches_form = page.evaluate_script(
        "_fpa.state.template_config[#{state_name.to_json}].v0 === " \
        "_fpa.state.template_config[#{state_name.to_json}].v#{new_token}"
      )
      expect(current_alias_matches_form).to be(true)
      expect(page.evaluate_script(
        "_fpa.state.template_config[#{state_name.to_json}].v0 === window.__initialTemplateConfigV0"
      )).to be(false)

      dm_form_mode :new
      within(new_form) do
        finish_form_formatting
        expect_block.not_to have_input_field('conditional_field_1')
        fill_in_field 'main_field_1', 'show_after_config_edit'
        expect_block.to have_input_field('conditional_field_1')
        expect_block.to have_field_label('conditional_field_1', 'Updated Conditional Field', mode: :new)
      end
    end

    it 'promotes v0 to the new token when an existing record opens a current edit form first' do
      @master.current_user = @user
      record = @master.dynamic_model__test_show_if_fields.create!(
        current_user: @user,
        main_field_1: 'edit after config change'
      )

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
      dismiss_modal
      expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
      finish_page_loading
      finish_form_formatting
      expect(page).to have_css('body.status-compiled', wait: 60)

      state_name = "#{@show_if_dm.item_type_name}_default".underscore
      old_token = @show_if_dm.current_def_version.to_s
      v0_version_before_edit = page.evaluate_script(
        "_fpa.state.template_config[#{state_name.to_json}].v0.vdef_version"
      )
      expect(v0_version_before_edit).to be_present

      updated_options = @show_if_dm.options.gsub('show_conditional_1', 'show_after_config_edit')
                                         .gsub('conditional_field_1: Conditional Field 1',
                                               'conditional_field_1: Updated Conditional Field')
      update_show_if_definition_options(updated_options)
      new_token = @show_if_dm.current_def_version.to_s
      expect(new_token).not_to eq(old_token)

      record_block = find("#{show_form_css(@resource_name)}[data-sub-id='#{record.id}']")
      click_edit_button_within_target(record_block)
      dm_form_mode :edit

      form_state_script_id = "fpa_state_config--#{state_name}--v#{new_token}--form"
      expect(page).to have_css("##{form_state_script_id}", visible: :all)
      expect(page.evaluate_script(
        "!!_fpa.state.template_config[#{state_name.to_json}].v#{new_token}"
      )).to be(true)
      v0_version_after_edit = page.evaluate_script(
        "_fpa.state.template_config[#{state_name.to_json}].v0.vdef_version"
      )
      expect(v0_version_after_edit).to eq("v#{new_token}")
      expect(v0_version_after_edit).not_to eq(v0_version_before_edit)
    end
  end

  # A new form refreshes stale empty-list v0 inline, without a template-config fetch.
  describe 'list-level v0 config after a config-only definition edit' do
    before(:all) do
      @previous_disable_vdef = Settings::DisableVDef
      @previous_perform_caching = Rails.configuration.action_controller.perform_caching
      change_setting('DisableVDef', false)
      Rails.configuration.action_controller.perform_caching = true
      @resource_name = :dynamic_model__test_show_if_fields
      set_up_feature
      @show_if_dm = setup_show_if_dm
      @show_if_definitions = DynamicModel.active.where(
        table_name: %w[test_show_if_fields test_show_if_embedded_recs]
      ).to_a
      setup_access @resource_name, user: @user, app_type: @app_type
      SetupHelper.reload_configs
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      @show_if_definitions.each { |definition| definition.reload.disable!(@admin) }
      Rails.configuration.action_controller.perform_caching = @previous_perform_caching
      change_setting('DisableVDef', @previous_disable_vdef)
      DynamicModel.define_models
      Application.refresh_dynamic_defs
    end

    before(:each) do
      validate_setup
      login
    end

    def skeleton_key
      helpers = ApplicationController.helpers
      helpers.instance_variable_set(:@master_templates_skeleton_cache_signatures, nil)
      helpers.instance_variable_set(:@partial_cache_key_access_control_timestamps, nil)
      helpers.master_templates_skeleton_cache_key(force_user_or_admin: @user)
    end

    def load_details_tab
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
      dismiss_modal
      expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
      finish_page_loading
      finish_form_formatting
      expect(page).to have_css('body.status-compiled', wait: 60)
    end

    def v0_add_item_label(list_key)
      page.evaluate_script("_fpa.state.template_config[#{list_key.to_json}].v0.add_item_label")
    end

    it 'updates list-level v0 from the current form without a template-config request' do
      DynamicModel::TestShowIfField.where(master_id: @master_id).delete_all
      Rails.cache.delete(skeleton_key)
      page.driver.browser.execute_cdp('Network.clearBrowserCache')
      # The list wrapper reads this name's v0; its per-option-type slot is the same object
      list_key = @show_if_dm.item_type_name.underscore
      new_label = 'Add Changed Thing'

      load_details_tab
      expect(Rails.cache.exist?(skeleton_key)).to be(true)
      old_token = @show_if_dm.current_def_version
      old_label = v0_add_item_label(list_key)
      expect(old_label).to be_present
      expect(old_label).not_to eq(new_label)
      expect(page.evaluate_script("!!_fpa.state.template_config[#{list_key.to_json}].v#{old_token}")).to be(true)
      key_before_edit = skeleton_key

      previous_allow_dynamic_migrations = Settings::AllowDynamicMigrations
      cached_updated_at = @show_if_dm.updated_at
      begin
        change_setting('AllowDynamicMigrations', false)
        @show_if_dm.current_admin = @admin
        @show_if_dm.options = @show_if_dm.options.sub("default:\n", "default:\n  button_label: #{new_label}\n")
        @show_if_dm.save!
        @show_if_dm.update_columns(updated_at: cached_updated_at + 3.seconds)
      ensure
        change_setting('AllowDynamicMigrations', previous_allow_dynamic_migrations)
      end
      DynamicModel.define_models
      Application.refresh_dynamic_defs
      @show_if_dm.reload
      new_token = @show_if_dm.current_def_version
      expect(new_token).not_to eq(old_token)
      expect(@show_if_dm.option_type_config_for(:default).button_label).to eq(new_label)
      expect(skeleton_key).to eq(key_before_edit)

      page.driver.browser.execute_cdp('Network.clearBrowserCache')
      load_details_tab
      expect(Rails.cache.exist?(key_before_edit)).to be(true)
      template_request_count = page.evaluate_script(<<~JS)
        performance.getEntriesByType('resource').filter(function (entry) {
          return entry.name.indexOf('/pages/') >= 0 && entry.name.endsWith('/template');
        }).length
      JS
      expect(template_request_count).to eq(1)
      template_config_request_count = page.evaluate_script(<<~JS)
        performance.getEntriesByType('resource').filter(function (entry) {
          return entry.name.indexOf('/template_config') >= 0;
        }).length
      JS
      expect(template_config_request_count).to eq(0)
      page.execute_script(<<~JS)
        window.__templateConfigRequests = [];
        var originalAjax = $.ajax;
        $.ajax = function (url, options) {
          var requestUrl = typeof url === 'string' ? url : (url && url.url);
          if (requestUrl && requestUrl.indexOf('/template_config') >= 0) window.__templateConfigRequests.push(requestUrl);
          return originalAjax.apply(this, arguments);
        };
      JS

      expect(v0_add_item_label(list_key)).to eq(old_label)
      expect(page.evaluate_script("!!_fpa.state.template_config[#{list_key.to_json}].v#{new_token}")).to be(false)
      expect(page.evaluate_script('window.__templateConfigRequests.length')).to eq(0)

      new_button_css = '.details-item-type-dynamic-model--test-show-if-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_css)
      find(new_button_css).click
      expect(page).to have_css(new_form_css(@resource_name), wait: 20)

      expect(v0_add_item_label(list_key)).to eq(new_label)
      expect(page.evaluate_script('window.__templateConfigRequests.length')).to eq(0)
    end
  end
end
