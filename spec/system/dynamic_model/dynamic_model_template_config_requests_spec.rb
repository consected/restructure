# frozen_string_literal: true

# Issue #1481 browser verification of lazy template_config loading, for dynamic models whose config is
# delivered inline by the cached masters skeleton.
#
# - On a full page load, no template_config request is made for records whose vdef_version slot the
#   skeleton already delivered, nor for a model with no records (its list chrome comes from the bundle
#   and the skeleton's inline v0 config).
# - After a config-only edit, the skeleton stays cached with the old config, the data reports the new
#   token, exactly one template_config request is made for the resource, the new config is rendered, and
#   both the v<n+1> slot and the v0 alias are updated.
#
# Requests are counted in two independent ways, so neither a browser-cached response nor a full browser
# resource timing buffer can hide a request. A script installed through the Chrome DevTools Protocol before
# any page script runs wraps XMLHttpRequest and fetch, recording every template_config URL for the page load
# (including requests answered from the browser cache). ActiveSupport::Notifications records those that
# reach the Rails app. Both must agree.
require 'rails_helper'

describe 'dynamic model template_config requests on page load', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include CacheKeyMemoizationSupport

  def filled_table
    'issue1481_tcreq_filled_recs'
  end

  def empty_table
    'issue1481_tcreq_empty_recs'
  end

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin

    masters = Master.no_temporary_masters
    create_data_set_outside_tx if masters.none? || masters.first&.id.to_i < 1
    @master = masters.first
    @master_id = @master.id
    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @app_type = @user.app_type
    expect(@app_type).not_to be_nil
    expect(@user.two_factor_auth_disabled).to be_truthy
  end

  def definition_options(label:, button_label:)
    <<~YAML
      _configurations:
        use_current_version: true

      default:
        button_label: #{button_label}
        fields:
          - test1
          - test2
        labels:
          test1: #{label}
          test2: Tcreq Second Field
    YAML
  end

  def create_definition(table_name, label:, button_label:)
    DynamicModel.active.where(table_name:).reload.each { |definition| definition.reload.disable!(@admin) }
    class_name = table_name.singularize.ns_camelize
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    definition = DynamicModel.create!(
      current_admin: @admin,
      name: "Issue1481 #{table_name}",
      table_name:,
      schema_name: 'dynamic_test',
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      category: 'details',
      field_list: 'test1 test2',
      options: definition_options(label:, button_label:)
    )
    definition.add_user_access_controls(force: true, app_type: @app_type)
    setup_access :"dynamic_model__#{table_name}", user: @user, app_type: @app_type
    definition
  end

  def panel_css(table_name)
    ".details-item-type-dynamic-model--#{table_name.hyphenate}"
  end

  # The current state slot token, read through a fresh definition record so it reflects the latest save
  def live_token(definition)
    fresh = DynamicModel.find(definition.id)
    fresh.refresh_current_def_version!
    fresh.template_version_token
  end

  def config_state_name(definition)
    "#{definition.item_type_name}_default".underscore
  end

  def skeleton_key
    Application.refresh_dynamic_defs
    fresh_master_skeleton_cache_key(@user)
  end

  # A config-only edit through the definition model, as the admin panel does, without table migration
  def edit_definition_options(definition, options)
    previous_allow_dynamic_migrations = Settings::AllowDynamicMigrations
    cached_updated_at = definition.reload.updated_at
    begin
      change_setting('AllowDynamicMigrations', false)
      definition.current_admin = @admin
      definition.options = options
      definition.save!
      definition.update_columns(updated_at: cached_updated_at + 3.seconds) # rubocop:disable Rails/SkipsModelValidations
    ensure
      change_setting('AllowDynamicMigrations', previous_allow_dynamic_migrations)
    end
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    definition.reload
  end

  def template_config_hook_script
    <<~JS
      (function () {
        window.__templateConfigRequests = [];
        var record = function (url) {
          if (String(url).indexOf('/template_config') >= 0) window.__templateConfigRequests.push(String(url));
        };
        var originalOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function (method, url) {
          record(url);
          return originalOpen.apply(this, arguments);
        };
        if (window.fetch) {
          var originalFetch = window.fetch;
          window.fetch = function (input) {
            record(input && input.url ? input.url : input);
            return originalFetch.apply(this, arguments);
          };
        }
      })();
    JS
  end

  def browser_template_config_requests
    page.evaluate_script('window.__templateConfigRequests')
  end

  def wait_for_ajax_idle
    Capybara.current_session.document.synchronize(20) do
      raise Capybara::ElementNotFound, 'ajax requests still running' unless page.evaluate_script('jQuery.active').zero?
    end
  end

  def load_details_tab
    page.driver.browser.execute_cdp('Network.clearBrowserCache')
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal
    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    finish_page_loading
    finish_form_formatting
    expect(page).to have_css('body.status-compiled', wait: 60)
  end

  def expect_record_label(label)
    expect(page).to have_css("#{panel_css(filled_table)} small.ctlabel", text: /#{Regexp.escape(label)}/i, wait: 30)
  end

  def slot_present?(state_name, token)
    page.evaluate_script("!!(_fpa.state.template_config[#{state_name.to_json}] || {}).v#{token}")
  end

  before(:all) do
    @previous_allow_dynamic_migrations = Settings::AllowDynamicMigrations
    @previous_user_two_factor_disabled = Settings::TwoFactorAuthDisabledForUser
    @previous_disable_vdef = Settings::DisableVDef
    @previous_perform_caching = Rails.configuration.action_controller.perform_caching

    change_setting('AllowDynamicMigrations', true)
    change_setting('DisableVDef', false)
    Rails.configuration.action_controller.perform_caching = true
    set_up_feature

    @filled = create_definition(filled_table, label: 'Tcreq Label One', button_label: 'Add Tcreq Filled Thing')
    @empty = create_definition(empty_table, label: 'Tcreq Empty Label', button_label: 'Add Tcreq Empty Thing')
    @definitions = [@filled, @empty]
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    DynamicModel.reset_active_model_configurations!
    SetupHelper.reload_configs
    Rails.application.routes_reloader.reload!

    filled_class = "DynamicModel::#{filled_table.singularize.ns_camelize}".constantize
    filled_class.where(master_id: @master_id).delete_all
    "DynamicModel::#{empty_table.singularize.ns_camelize}".constantize.where(master_id: @master_id).delete_all
    @master.current_user = @user
    2.times do |index|
      @master.public_send("dynamic_model__#{filled_table}").create!(current_user: @user, test1: "tcreq filled #{index}")
    end
  end

  after(:all) do
    Array(@definitions).each do |definition|
      next unless DynamicModel.exists?(definition.id)

      definition.reload
      definition.disable!(@admin) unless definition.disabled?
    end

    if @definitions.present?
      DynamicModel.define_models
      Application.refresh_dynamic_defs
      DynamicModel.reset_active_model_configurations!
      SetupHelper.reload_configs
      Rails.application.routes_reloader.reload!
    end

    change_setting('AllowDynamicMigrations', @previous_allow_dynamic_migrations)
    change_setting('TwoFactorAuthDisabledForUser', @previous_user_two_factor_disabled)
    change_setting('DisableVDef', @previous_disable_vdef)
    Rails.configuration.action_controller.perform_caching = @previous_perform_caching
  end

  before(:each) do
    validate_setup
    login
    # Each example starts from a skeleton rendered with the current config
    Rails.cache.delete(skeleton_key)

    @server_template_config_paths = Concurrent::Array.new
    @request_subscription = ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
      path = args.last[:path].to_s
      @server_template_config_paths << path if path.include?('/template_config')
    end
    hook = page.driver.browser.execute_cdp(
      'Page.addScriptToEvaluateOnNewDocument', source: template_config_hook_script
    )
    @hook_identifier = hook['identifier']
  end

  after(:each) do
    ActiveSupport::Notifications.unsubscribe(@request_subscription) if @request_subscription
    if @hook_identifier
      page.driver.browser.execute_cdp('Page.removeScriptToEvaluateOnNewDocument', identifier: @hook_identifier)
    end
  end

  it 'makes no template_config request for records whose config the skeleton already delivered' do
    load_details_tab
    expect_record_label('Tcreq Label One')
    wait_for_ajax_idle

    state_name = config_state_name(@filled)
    token = live_token(@filled)
    expect(Rails.cache.exist?(skeleton_key)).to be(true)
    expect(slot_present?(state_name, token)).to be(true)
    expect(page.evaluate_script("_fpa.state.template_config[#{state_name.to_json}].v0.vdef_version")).to eq("v#{token}")
    expect(page).to have_css("#{panel_css(filled_table)} .common-templates--result-item", count: 2)

    expect(browser_template_config_requests).to eq([])
    expect(@server_template_config_paths.to_a).to eq([])
  end

  it 'renders a zero-record panel from the bundle and inline config with no template_config request' do
    load_details_tab
    expect_record_label('Tcreq Label One')
    wait_for_ajax_idle

    new_button = "#{panel_css(empty_table)} .new-button-container a.btn"
    expect(page).to have_css(new_button, text: /add tcreq empty thing/i, wait: 30)
    expect(page).to have_no_css("#{panel_css(empty_table)} .common-templates--result-item")
    expect(slot_present?(config_state_name(@empty), live_token(@empty))).to be(true)

    expect(browser_template_config_requests).to eq([])
    expect(@server_template_config_paths.to_a).to eq([])
  end

  it 'makes exactly one template_config request after a config-only edit and updates the v<n+1> slot and v0 alias' do
    load_details_tab
    expect_record_label('Tcreq Label One')
    wait_for_ajax_idle
    expect(browser_template_config_requests).to eq([])

    state_name = config_state_name(@filled)
    old_token = live_token(@filled)
    cached_skeleton_key = skeleton_key
    expect(Rails.cache.exist?(cached_skeleton_key)).to be(true)
    expect(page.evaluate_script("_fpa.state.template_config[#{state_name.to_json}].v0.vdef_version")).to eq("v#{old_token}")

    edit_definition_options(@filled, definition_options(label: 'Tcreq Label Two', button_label: 'Add Tcreq Filled Thing'))
    new_token = live_token(@filled)
    expect(new_token).not_to eq(old_token)
    expect(skeleton_key).to eq(cached_skeleton_key)
    expect(Rails.cache.exist?(cached_skeleton_key)).to be(true)
    @server_template_config_paths.clear

    load_details_tab
    expect_record_label('Tcreq Label Two')
    wait_for_ajax_idle

    # The cached skeleton still delivered the old slot; the one request patched in the new one
    expect(slot_present?(state_name, old_token)).to be(true)
    expect(slot_present?(state_name, new_token)).to be(true)
    expect(page.evaluate_script("_fpa.state.template_config[#{state_name.to_json}].v0.vdef_version")).to eq("v#{new_token}")
    expect(page.evaluate_script(
             "_fpa.state.template_config[#{state_name.to_json}].v0 === " \
             "_fpa.state.template_config[#{state_name.to_json}].v#{new_token}"
           )).to be(true)
    expect(page).to have_no_css("#{panel_css(filled_table)} small.ctlabel", text: /tcreq label one/i)

    browser_requests = browser_template_config_requests
    expect(browser_requests.length).to eq(1)
    expect(browser_requests.first).to include("/#{filled_table}/")
    expect(@server_template_config_paths.length).to eq(1)
    expect(@server_template_config_paths.first).to include("/#{filled_table}/")
    expect(@server_template_config_paths.first).to include('template_config')
  end
end
