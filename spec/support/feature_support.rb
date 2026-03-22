# frozen_string_literal: true

# Helper methods for Capybara system specs
#
# This module provides reusable methods for interacting with the application UI
# in system tests, abstracting common patterns and handling edge cases.
#
# Key Method Categories:
# - Field Interaction: fill_in_field, select_from_dropdown_field, set_yes_no_field,
#   set_checkbox_field, select_from_big_select_field, select_from_grouped_big_select_field
# - Navigation: expand_master_record, expand_master_record_tab, expand_model_reference,
#   click_edit_button_within_target
# - Debugging: debug_process_status, available_form_fields, puts_alerts
# - Waiting: finish_page_loading, finish_form_formatting
#
# Chosen.js Detection:
# The select_from_dropdown_field method automatically detects chosen.js via:
# - 'use-chosen' class (explicit declaration)
# - 'attached-chosen' class (added after JS initialization)
# - Presence of #{field_id}_chosen container element
#
# Big-Select Fields:
# - select_from_big_select_field: For standard big-select modal dialogs
# - select_from_grouped_big_select_field: For big-select with group_split_char grouping
#
# Usage Guidelines:
# - Always use helper methods instead of raw Capybara selectors
# - Helpers handle scrolling, visibility, and AJAX waits automatically
# - Modal interactions must happen outside Capybara `within` blocks
require './spec/support/feature_helper'
require './spec/support/user_actions_setup'
require './spec/support/codemirror_editor_support'
module FeatureSupport
  include FeatureHelper
  include UserActionsSetup
  include FeatureExpectations
  include CodemirrorEditorSupport

  ResultsMasterPanel = '.results-panel .master-panel'
  ResultsMasterExpander = '.master-expander'

  def js_console_log
    nil unless ENV['DEBUG_JS'] == 'true'

    # puts_debug_plain page.driver.browser.logs.get(:browser).select { |l| l.start_with?('console.') }.join("\n")
  end

  def login
    just_signed_in = false
    already_signed_in = false

    # Ensure @good_email and @good_password are set
    unless @good_email && @good_password
      # If not set, try to retrieve from the user
      raise 'Cannot login - no @user, @good_email, or @good_password set' unless @user

      @good_email ||= @user.email
      # We can't recover the password if it wasn't saved, but we can try to generate a new one
      unless @good_password
        puts_debug "ERROR: Cannot login - @good_password not set for user #{@user.id} (#{@user.email})"
        raise 'Cannot login - @good_password not set and cannot be recovered'
      end

    end

    puts_debug "→ login attempt with email=#{@good_email}, user_id=#{@user.id}, password_set=#{!!@good_password}"

    # NOTE: TwoFactorAuth can be disabled via ENV['FPHS_2FA_AUTH_DISABLED']
    # But we also need to ensure the user instance has 2FA disabled
    unless @user.two_factor_auth_disabled
      change_setting('TwoFactorAuthDisabledForUser', true)
      @user.otp_required_for_login = false
      @user.save!
      @user = User.find(@user.id) # Reload to get fresh state
      # Keep @good_email in sync - it should not have changed, but let's be safe
      @good_email = @user.email
    end

    # Reset any account lockout before attempting login
    if @user.access_locked?
      @user.unlock_access!
      @user = User.find(@user.id) # Reload to get fresh state
    end

    # Ensure the password is still valid
    unless @user.valid_password?(@good_password)
      # Password was corrupted - reload from database
      @user = User.find(@user.id)
    end

    expect(@user.two_factor_setup_required?).to be_falsey,
                                                "#{@user.two_factor_auth_disabled}, #{@user.otp_secret.present?}, #{@user.otp_required_for_login}"

    3.times do
      return if user_logged_in?

      visit '/users/sign_in'
      finish_page_loading
      finish_form_formatting
      have_css('#new_user')

      if all('#new_user').empty?
        # Avoid a weird race condition
        sleep 5
        return if user_logged_in?
      end
      expect(page).to have_css('#new_user')

      expect(@user.valid_password?(@good_password)).to be(true),
                                                       "Bad password (#{@good_password}) so can't login with email: #{@good_email}. #{@user}"
      expect(@user.email).to eq @good_email

      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      # Check if 2FA form appears (it shouldn't if we disabled it correctly)
      # Wait a bit to see if 2FA form shows up
      sleep 2
      if has_selector?('.login-2fa-block', visible: true, wait: 1)
        puts_debug 'WARNING: 2FA form appeared even though we disabled it!'
        # Handle it anyway
        within '#new_user' do
          fill_in 'Two-Factor Authentication Code', with: @user.current_otp
          click_button 'Log in'
        end
      end

      puts_debug "⚠️  Login error: #{alert_messages.join(' | ')}" if flashed_alert?('warning')
      already_signed_in = user_logged_in?
      break if already_signed_in

      fa = all('.flash .alert', wait: 0)[0]
      just_signed_in = (fa&.text == "×\nSigned in successfully.")

      # Debug output when login fails
      unless just_signed_in || already_signed_in
        puts_debug "Flash message: #{fa&.text.inspect}"
        puts_debug "Current URL: #{current_url}"
        puts_debug 'Login failed - checking page state...'
        puts_debug "  - Form present: #{has_css?('#new_user')}"
        puts_debug "  - Alert present: #{has_css?('.alert')}"
        puts_debug "  - User menu present: #{has_css?('.nav a[data-do-action=\"show-user-options\"]')}"
        # Save HTML for debugging
        begin
          File.write('/tmp/failed_login.html', page.html)
        rescue StandardError
          nil
        end
      end

      break if just_signed_in

      sleep 35 unless @user.two_factor_auth_disabled
      puts_debug 'Attempting another login'
    end

    puts_debug "⚠️  Login error: #{alert_messages.join(' | ')}" if flashed_alert?('warning')
    expect(just_signed_in || already_signed_in).to be true
    dismiss_all_alerts
    finish_page_loading
  end

  def logout
    finish_page_loading
    dismiss_modal
    dismiss_all_alerts
    sleep 1

    have_css('.navbar-right a[data-do-action="show-user-options"]')
    user_menu = find('.navbar-right a[data-do-action="show-user-options"]')
    page.execute_script('arguments[0].scrollIntoView(true);', user_menu)
    sleep 0.3
    user_menu.click

    have_css('.navbar-right li.dropdown.open .dropdown-menu')
    expect(page).to have_css('.dropdown-menu a[data-do-action="user-logout"]')

    logout_link = find('.dropdown-menu a[data-do-action="user-logout"]')
    page.execute_script('arguments[0].scrollIntoView(true);', logout_link)
    sleep 0.3
    logout_link.click
    finish_page_loading
    puts_alerts
    dismiss_all_alerts
  end

  def finish_form_formatting
    have_no_css('.formatting-block')
    have_no_css('.collapsing')
  end

  # Navigate to a master record by ID
  def navigate_to_master(master_id)
    expect(master_id).not_to be nil
    visit "/masters/search?nav_q_id=#{master_id}"
    finish_page_loading

    # Debug output
    puts_debug "Page title: #{page.title}"
    puts_debug "Page URL: #{page.current_url}"
    debug_process_status if respond_to?(:debug_process_status)

    unless page.has_css?('.master-result', wait: 15)
      # Capture page state before failing
      alerts = all('div.alert', visible: true, wait: 0)
      if alerts.any?
        puts_debug "ALERTS visible on page (#{alerts.count}):"
        alerts.each { |a| puts_debug "  Alert: #{a.text.strip.first(300)}" }
      end
      flash_msgs = all('.flash .alert', visible: true, wait: 0)
      if flash_msgs.any?
        puts_debug "FLASH messages (#{flash_msgs.count}):"
        flash_msgs.each { |f| puts_debug "  Flash: #{f.text.strip.first(300)}" }
      end
      puts_debug "Page body text (first 500 chars): #{page.text.first(500)}"
      raise "navigate_to_master: .master-result not found for master_id #{master_id}. Check alerts above."
    end

    # Expand the master record to see details
    expand_master_record(master_id: master_id)
    finish_page_loading
  end

  def finish_page_loading
    if all('body.status-compiled, body.sessions, body.confirmations, body.passwords, body.registrations').present?
      return
    end

    has_css?('body.status-compiled, body.sessions, body.confirmations, body.passwords, body.registrations', wait: 10)
    sleep 1
  end

  def dismiss_modal
    finish_page_loading
    finish_form_formatting
    if all('.modal.fade.in', wait: false).empty?
      # Places a javascript event handler on the modal to hide it automatically when it shows
      force_modal_hide
    else
      finish_form_formatting
      have_css('button[data-dismiss="modal"]')
      b = all('button[data-dismiss="modal"]', wait: false)
      b.first.click if b && !b.empty?
      # wait for the modal to fade out before continuing
      has_no_css?('.modal.fade.in')
      has_css?('.modal[style~="display: none"]')
    end
  end

  def dismiss_all_modals
    all('button[data-dismiss="modal"]', wait: false).each(&:click)
    # wait for the modal to fade out before continuing
    has_no_css?('.modal.fade.in')
    has_css?('.modal[style~="display: none"]')
  end

  def open_player_element(el, items)
    dismiss_modal
    have_css('.player-info-header')
    if items.length > 1 # it opens automatically if there is only one result
      el.find('.player-info-header').click
    else
      el = find('.master-expander')
      el.find('.player-info-header')
    end
    dismiss_modal
    h = el['data-target'].split('#').last
    # Wait for the master record to load

    expect(page).to have_css("##{h}.loaded-master-main")
    have_css("##{h}.collapse.in")
    find "##{h}.collapse.in"
    h
  end

  def expect_master_record
    expect(page).to have_css(ResultsMasterPanel)
  end

  def expect_master_to_have_expanded(master_id)
    expect(page).to have_css("#master-#{master_id}-main-container.collapse.in.loaded-master-main")
    expect(page).not_to have_css('.collapse.collapsing')
  end

  def expect_tracker_to_be_expanded(master_id)
    expect(page).to have_css "#trackers-#{master_id}.collapse.in"
  end

  def all_master_record_panels
    all(ResultsMasterPanel)
  end

  def all_master_record_expanders
    has_css?(ResultsMasterExpander)
    all(ResultsMasterExpander)
  end

  #
  # Expand a master record by its index in the results list (0-based)
  def expand_master(index)
    has_css?('.results-panel')
    finish_form_formatting
    els = all_master_record_expanders
    el = els[index]
    h = open_player_element el, els
    new_panel = find("##{h}")
    expect(new_panel).to have_css('.master-main-panel')
  end

  #
  # Expand a master record tab (such as "details", "external ids", "phone log", etc) by name
  # This avoids the need to explicitly get `a[data-panel-tab="<name>"]` and click it.
  # Expectations are also enforced to ensure the tab shows.
  def expand_master_record_tab(name)
    finish_form_formatting
    tab_link = all("ul.details-tabs li a[data-panel-tab='#{name.id_underscore}']").first
    expect(tab_link).not_to be nil
    tab_link.click if tab_link['aria-expanded'] != 'true'

    # Wait for the target panel to fully expand (Bootstrap collapse animation)
    target = tab_link['data-target']
    return unless target.present?

    target_selector = "#{target}.collapse.in"
    expect(page).to have_css(target_selector, wait: 15)
  end

  #
  # Expand a search tab by the name that appears on the button
  # Expectations are also enforced to ensure the search form shows.
  def expand_search_with_button(name)
    search_btn = all(".advanced-form-selections a[type='button']").select { |b| b.text == name }.first
    expect(search_btn).not_to be nil
    search_btn.click if search_btn[:class].include?('collapsed')

    form_id = search_btn['data-result-target']
    expect(page).to have_css(form_id)
  end

  def expand_tracker_panel
    # Tracker panel is possibly collapsed
    if all('.tracker-tree-results').empty?
      # Click the tab
      c = 'a[data-panel-tab="tracker"]'
      have_css(c)
      find(c).click
    end
    expect(page).to have_css '.tracker-tree-results'
  end

  # ===================================================================
  # Form Field Helper Methods
  # ===================================================================

  def id_for_field(field_name, is_report: false)
    if is_report
      find("[name='search_attrs[#{field_name}]']", visible: :all, wait: 2)[:id]
    else
      find("[data-attr-name='#{field_name}']", visible: :all, wait: 2)[:id]
    end
  rescue Capybara::ElementNotFound => e
    puts_debug "id_for_field #{field_name} not found: #{e}"
    puts_debug "available fields: #{current_form_field_names.join(', ')}"
    raise
  end

  # Get single element for a field
  def element_for_field(field_name, is_report: false)
    if is_report
      find("[name='search_attrs[#{field_name}]']", visible: :all, wait: 2)
    else
      # For big-select fields, there may be both a hidden select and an input element
      # Prefer the input element if it exists (big-select uses input)
      inputs = all("input[data-attr-name='#{field_name}']", visible: :all, wait: 2)
      return inputs.first if inputs.any?

      find("[data-attr-name='#{field_name}']", visible: :all, wait: 2)
    end
  rescue Capybara::ElementNotFound => e
    puts_debug "element_for_field #{field_name} not found: #{e}"
    puts_debug "available fields: #{current_form_field_names.join(', ')}"
    raise
  end

  # Get all matching elements for a field (e.g., radio buttons)
  def elements_for_field(field_name)
    all("[data-attr-name='#{field_name}']", visible: :all, wait: 2)
  rescue Capybara::ElementNotFound => e
    puts_debug "elements_for_field #{field_name} not found: #{e}"
    puts_debug "available fields: #{current_form_field_names.join(', ')}"
    raise
  end

  def set_checkbox_field(field_name, value)
    element = element_for_field(field_name)
    scroll_into_view(element)
    if value
      element.check
    else
      element.uncheck
    end
  end

  def edit_rich_text_editor_field(field_name, value)
    # Update the hidden textarea (this is what gets submitted)
    textarea = element_for_field(field_name)
    content_editor = find("[data-edit-field-name='#{field_name}'] .custom-editor", visible: :all)
    content_editor.click
    content_editor.send_keys(value)
    all('label, .caption-before').first.click # Move focus away to trigger update
    sleep 0.5 # Allow time for update
    expect(textarea.value).to eq(value)
  end

  def set_yes_no_field(field_name, value)
    # Just check it exists
    elements_for_field(field_name)
    # Now set the value
    radio_button = find("[data-attr-name='#{field_name}'][value='#{value}']", visible: :all)
    radio_button.click
  end

  def select_from_big_select_field(field_name, value)
    # Find the readonly input field that triggers the big-select popup
    big_select_field = element_for_field(field_name)
    scroll_into_view(big_select_field)

    field_id = big_select_field[:id]
    puts_debug "Big-select field ID: #{field_id}"

    # Click the field to open the modal
    big_select_field.click

    # Wait for modal to become visible
    expect(page).to have_css('#primary-modal.fade.in', wait: 5)
    expect(page).to have_css('#primary-modal .big-select-item', wait: 3)

    # Look for big-select-item elements within the modal (modal is outside form scope)
    all_items = page.all('#primary-modal .big-select-item')
    puts_debug " - Found #{all_items.count} big-select items in modal"

    # Debug: save HTML if no items found
    save_html_snapshot('/tmp/big_select_dialog.html') if all_items.empty?

    list_of_items = []
    list_of_texts = []
    got_item_key = nil
    all_items.each_with_index do |item, _i|
      item_text = item.text.strip
      item_key = item['data-bsi-key']
      list_of_items << item_key
      list_of_texts << item_text

      # Match by key OR by text
      next unless item_key == value || item_text.include?(value) || value.nil?

      item.click
      got_item_key = item_key
      break
    end

    page.has_css?('#primary-modal.fade', class: '!in')
    sleep 0.5

    # Verify the field value was actually set
    unless got_item_key
      puts_debug("big-select #{value} not in keys: #{list_of_items} or texts: #{list_of_texts}")
      save_html_snapshot('/tmp/big_select_dialog.html')
    end
    expect(got_item_key).not_to be nil

    sleep 0.5 # Allow time for field to update
    big_select_field_after = element_for_field(field_name)
    field_value = big_select_field_after.value
    expect(field_value).to eq(got_item_key), '⚠️  WARNING: Field value still empty after clicking item!'
  end

  # Select from a big-select field that has grouped items (uses group_split_char configuration)
  # @param [String] field_name - the field name (data-attr-name attribute)
  # @param [String] value - the value to select
  # @param [String|nil] group_name - optional group name to expand; if nil, searches all groups
  def select_from_grouped_big_select_field(field_name, value, group_name: nil)
    big_select_field = element_for_field(field_name)
    scroll_into_view(big_select_field)

    field_id = big_select_field[:id]

    # Open the big-select dialog
    big_select_field.click
    sleep 1

    # Check if modal opened
    modal_visible = page.has_css?('#primary-modal.fade.in', wait: 3)

    unless modal_visible
      # Try triggering focus directly via JS
      page.execute_script("$('##{field_id}').focus();")
      sleep 1
      modal_visible = page.has_css?('#primary-modal.fade.in', wait: 3)
    end

    unless modal_visible
      save_html_snapshot('/tmp/grouped_no_modal.html')
      raise "Modal did not open for grouped big-select field '#{field_name}'. HTML saved to /tmp/grouped_no_modal.html"
    end

    expect(page).to have_css('#primary-modal.fade.in', wait: 5)

    # Check if there are grouped items
    if page.has_css?('.big-select-group-head', wait: 2)
      group_headers = page.all('.big-select-group-head')

      if group_name
        # Find specific group and expand it
        target_group = group_headers.find { |h| h.text.include?(group_name) }
        unless target_group
          available_groups = group_headers.map(&:text)
          raise "Could not find group '#{group_name}' in big-select. Available: #{available_groups.inspect}"
        end

        within(target_group) do
          find('a[data-toggle="collapse"]').click
        end
        sleep 0.5
      else
        # Expand all groups to search for the item
        group_headers.each do |header|
          within(header) do
            collapse_link = find('a[data-toggle="collapse"]')
            collapse_link.click if collapse_link['aria-expanded'] != 'true'
          end
          sleep 0.3
        end
      end
    end

    # Wait for items and select the matching one (within modal scope)
    expect(page).to have_css('#primary-modal .big-select-item', wait: 3)
    all_items = page.all('#primary-modal .big-select-item', visible: true)

    # Find matching item by key or text
    got_item = nil
    all_items.each do |item|
      item_key = item['data-bsi-key']
      item_text = item.text.strip

      # Skip items without a valid key (group headers, clear option, etc.)
      next if item_key.nil? || item_key == '' || item_key == 'big-select-clear'

      # Match by key or by text
      if item_key == value || item_text.include?(value)
        got_item = item
        break
      end
    end

    unless got_item
      available = all_items.map { |i| "#{i['data-bsi-key']}: #{i.text[0..50]}" }
      raise "Could not find '#{value}' in grouped big-select. Available: #{available.take(10).inspect}"
    end

    puts_debug "Grouped big-select: clicking item with key='#{got_item['data-bsi-key']}', text='#{got_item.text[0..30]}'"
    expected_key = got_item['data-bsi-key'] # Store key BEFORE clicking (element becomes stale after)
    got_item.click

    expect(page).not_to have_css('#primary-modal.fade.in', wait: 3)
    sleep 0.5

    # Verify the field value was set
    big_select_field_after = element_for_field(field_name)
    field_value = big_select_field_after.value

    unless field_value == expected_key
      save_html_snapshot('/tmp/grouped_mismatch.html')
      puts_debug "Field value mismatch! Expected '#{expected_key}', got '#{field_value}'. HTML saved."
    end

    expect(field_value).to eq(expected_key),
                           "⚠️  WARNING: Field value '#{field_value}' doesn't match expected '#{expected_key}'"
  end

  # Clear the selection in a big-select field by clicking the (none) option
  # @param [String] field_name - the field name (data-attr-name attribute)
  def clear_big_select_field(field_name)
    big_select_field = element_for_field(field_name)
    scroll_into_view(big_select_field)

    big_select_field.click
    sleep 1

    expect(page).to have_css('#primary-modal.fade.in', wait: 5)
    expect(page).to have_css('#primary-modal .big-select-item', wait: 3)

    # Find the (none) / clear option within the modal
    clear_option = page.all('#primary-modal .big-select-item').find do |item|
      item['data-bsi-key'] == '' || item['id'] == 'big-select-item--big-select-clear' || item.text == '(none)'
    end

    raise 'Could not find (none) option in big-select dialog' unless clear_option

    clear_option.click

    expect(page).not_to have_css('#primary-modal.fade.in', wait: 3)
    sleep 0.5

    # Verify the field was cleared (value is set to 'big-select-clear' marker)
    big_select_field_after = element_for_field(field_name)
    expect(big_select_field_after.value).to eq('big-select-clear'),
                                            "⚠️  WARNING: Field was not cleared, value is '#{big_select_field_after.value}'"
  end

  def fill_in_field(field_name, value)
    field = element_for_field(field_name)
    expect(field[:class]).not_to(include('use-text-area-for-custom-editor'),
                                 "Can't fill in field #{field_name} - it is really a custom editor. Use edit_rich_text_editor_field instead")
    scroll_into_view(field)
    field.fill_in(with: value)
  end

  # Select a value from a dropdown field, automatically detecting chosen.js
  # Chosen can be attached via:
  # 1. `use-chosen` class on the element
  # 2. `attached-chosen` class added after chosen.js initialization
  # 3. Report criteria fields (always use chosen via .report-criteria-fields-block selector)
  def select_from_dropdown_field(field_name, value, is_report: false)
    element = element_for_field(field_name, is_report:)
    scroll_into_view(element)

    # Detect if chosen.js is attached via multiple fallback checks
    has_chosen = element['class'].include?('use-chosen') ||
                 element['class'].include?('attached-chosen') ||
                 is_report ||
                 page.has_css?("##{element[:id]}_chosen", visible: :all, wait: 0.5)

    if has_chosen
      select_from_chosen(field_name, value, is_report:)
    else
      element.select value
    end
  end

  def select_multiple_from_chosen(field_name, values, is_report: false)
    return unless values.present?

    is_multi = true
    values.each do |topic|
      select_from_chosen(field_name, topic, is_multi:, is_report:)
      is_multi = :already_open
    end

    # Close the multiple selections
    all('label, .caption-before').first.click
  end

  # Helper method to interact with chosen dropdowns (single or multi-select)
  # To function, this method must be called outside of any within blocks
  def select_from_chosen(field_name, value, is_multi: false, is_report: false)
    field_id = id_for_field(field_name, is_report:)
    chosen_id = "#{field_id}_chosen"

    expect(page).to have_css("##{chosen_id}", visible: :all, wait: 2)
    chosen_container = all("##{chosen_id}", match: :first).first
    scroll_into_view(chosen_container)
    sleep 0.2

    if is_multi == :already_open
      # Do nothing, assume already open
    elsif is_multi
      # For multi-select, click within the search field area
      search_field = chosen_container.find('ul.chosen-choices .search-field input', visible: :all)
      search_field.click
    else
      # For single select, click the container
      chosen_container.click
    end
    sleep 0.5

    # The dropdown appears absolutely positioned at body level
    results_selector = 'body > .chosen-container.chosen-with-drop .chosen-results li.active-result'
    expect(page).to have_css(results_selector, wait: 4),
                    "No dropdown results appeared for #{field_id} - NOTE - remove the method call from any within blocks to avoid scope issues"

    # Find matching result
    results = page.all(results_selector)
    matching = results.find { |r| r.text.downcase == value.downcase }
    expect(matching).not_to(be_nil,
                            "Could not find matching chosen option '#{value}' in field #{field_id} - #{results.map(&:text)}")

    matching.click
    sleep 0.3
    true
  rescue StandardError => e
    puts_debug " - WARNING: Error selecting from chosen #{field_id}: #{e.message}"
    raise
  end

  # ===================================================================
  # Section Expansion Methods
  # ===================================================================

  # Helper method for expanding embedded-add-item-button references
  # These are different from standard model references (mr-expander)
  def expand_embedded_reference(link_text, wait_time: 10)
    puts_debug "Expanding embedded reference: #{link_text}"

    # Find the embedded-add-item-button link specifically (not other links with same text)
    link = find('a.embedded-add-item-button', text: link_text, match: :first, wait: 5)
    target_selector = link['data-target']

    puts_debug "Target selector: #{target_selector}"

    # Click to trigger AJAX form creation
    scroll_into_view(link)
    sleep 0.5
    link.click
    puts_debug 'Clicked embedded-add-item-button'

    # Wait for form to appear in target element
    expect(page).to have_css(target_selector, wait: wait_time)
    puts_debug 'Form container appeared'

    finish_page_loading
    sleep 1

    # Find form within target element (use match: :first if multiple matches)
    target_element = find(target_selector, match: :first)

    # Wait for form to actually load inside the target
    expect(target_element).to have_css('form, .common-template-item-inner', wait: wait_time)
    puts_debug 'Form or view appeared inside target'

    form = target_element.find('form, .common-template-item-inner', match: :first)

    scroll_into_view(form)
    finish_form_formatting
    sleep 1

    puts_debug '✓ Expanded embedded reference form'
    form
  end

  def click_edit_button_within_target(target_element, optional: false)
    puts_debug 'Clicking Edit button to open form'
    edit_button = target_element.all('a.edit-entity', match: :first, wait: 10).first
    if optional && edit_button.nil?
      puts_debug 'No edit button found, but optional is true - skipping click'
      return target_element
    end

    scroll_into_view(edit_button)
    edit_button.click
    form = target_element.find('form', wait: 10)
    finish_form_formatting
    puts_alerts
    form
  end

  #
  # Expand a master record, by id or matching link text
  # @param [String, nil] text The text to match for the master-expander link
  def expand_master_record(text: nil, master_id: nil)
    finish_form_formatting
    if text
      link = all('a.master-expander', text: text, match: :first, wait: 5).first
    elsif master_id
      link = all("#master-#{master_id} a.master-expander", match: :first, wait: 5).first
    else
      raise 'Either text or master_id must be provided to expand_master_record'
    end
    unless link
      puts_debug "all master-expanders: #{all('a.master-expander').map(&:text).join(', ')}"
      save_html_snapshot('/tmp/no_master_expander.html')
    end
    expect(link).not_to(be_nil, "Could not find master-expander link for text: #{text}")
    sleep 1
    # The master record panel may be collapsed
    # Look for the master-expander link and click it to expand the master record details
    if link[:class].include?('collapsed')
      puts_debug 'Found collapsed master-expander, clicking to expand master record panel...'

      # Click on the player-info-header child element which has actual dimensions
      # The master-expander anchor itself may have zero size due to CSS styling
      player_header = link.all('.player-info-header').first
      if player_header
        scroll_into_view(player_header)
        player_header.click
      else
        scroll_into_view(link)
        link.click
      end
      finish_form_formatting
      sleep 2 # Extra wait for AJAX to load master record details
      # Check for alerts after expanding master record
      puts_alerts
      puts_debug 'Master record panel expanded'
    else
      puts_debug 'Master record panel already expanded or no master-expander found'
    end
  end

  #
  # Expand an mr-expander based on its label
  # @param [String] label The label of the model reference to expand
  # @return [Capybara::Node::Element] The form element within the expanded section
  def expand_model_reference(label)
    finish_page_loading
    finish_form_formatting
    label_element = find('.mr-item-label', text: label, wait: 5)
    label_element_id = label_element['id']
    caret = find(".mr-expander[data-label-for='#{label_element_id}']")
    caret_id = caret['id']
    caret_id_selector = "##{caret_id}"

    expect(page).to have_css(caret_id_selector)
    puts_debug "Found #{caret_id_selector}, expanding section..."
    expect(caret['id']).to eq(caret_id)
    puts_debug caret['class']
    puts_debug caret['data-label-for']
    scroll_to(caret_id_selector)
    if caret['class'].include?('caret-target-collapsed')
      puts_debug 'Expander is collapsed, clicking to expand...'
      caret.click
    end
    result_target_id = caret['data-result-target']
    finish_form_formatting
    form_selector = "#{result_target_id} form, #{result_target_id}.model-reference-result"
    expect(page).to have_css(form_selector, wait: 10)
    result_target = find(form_selector, match: :first)
    scroll_into_view(result_target)
    finish_form_formatting
    sleep 1
    puts_debug "Expanded section, found form in #{result_target_id}"
    result_target
  end

  def puts_debug(msg, force: false)
    puts "[FeatureSupport DEBUG] #{msg}" if ENV['FEATURE_DEBUG'] == 'true' || force
  end

  def puts_debug_plain(msg, force: false)
    puts msg if ENV['FEATURE_DEBUG'] == 'true' || force
  end

  def save_html_snapshot(filename)
    File.write(filename, page.html)
    puts_debug "Saved HTML snapshot to #{filename}"
  end

  #
  # Set up browser console log capture. Call this AFTER initial page load but BEFORE
  # navigating to the page you want to debug. Captures console.log, console.error,
  # console.warn, and CSP violation events.
  #
  # Usage:
  #   visit '/some/page'
  #   setup_browser_console_capture
  #   visit '/page/to/debug'  # Console capture active for this navigation
  #   finish_page_loading
  #   print_browser_console_logs('After visiting debug page')
  #
  def setup_browser_console_capture
    page.execute_script(<<~JS)
      window.browserLogs = [];
      window.cspViolations = [];
      if (!window._consoleIntercepted) {
        window._consoleIntercepted = true;
        var origLog = console.log;
        var origError = console.error;
        var origWarn = console.warn;
        console.log = function() {
          window.browserLogs.push('LOG: ' + Array.from(arguments).join(' '));
          origLog.apply(console, arguments);
        };
        console.error = function() {
          window.browserLogs.push('ERROR: ' + Array.from(arguments).join(' '));
          origError.apply(console, arguments);
        };
        console.warn = function() {
          window.browserLogs.push('WARN: ' + Array.from(arguments).join(' '));
          origWarn.apply(console, arguments);
        };

        // Listen for CSP violation events
        document.addEventListener('securitypolicyviolation', function(e) {
          var violation = {
            blockedURI: e.blockedURI,
            violatedDirective: e.violatedDirective,
            sourceFile: e.sourceFile,
            lineNumber: e.lineNumber,
            columnNumber: e.columnNumber,
            sample: e.sample
          };
          window.cspViolations.push(violation);
          window.browserLogs.push('CSP VIOLATION: ' + e.violatedDirective +
            ' - blocked: ' + e.blockedURI +
            ' at ' + e.sourceFile + ':' + e.lineNumber + ':' + e.columnNumber +
            ' sample: ' + e.sample);
        });
      }
    JS
  end

  #
  # Retrieve and print captured browser console logs. Call after setup_browser_console_capture
  # and after performing the actions you want to debug.
  #
  # @param context [String] Description of what was being tested (for output header)
  # @return [Hash] { logs: Array, csp_violations: Array }
  #
  def print_browser_console_logs(context = 'Browser Console')
    logs = page.evaluate_script('window.browserLogs || []')
    violations = page.evaluate_script('window.cspViolations || []')

    puts_debug "\n#{'=' * 80}"
    puts_debug "CONTEXT: #{context}"
    puts_debug '-' * 80
    puts_debug "BROWSER CONSOLE LOGS (#{logs.length} entries):"
    logs.each { |log| puts_debug "  #{log}" }

    if violations.any?
      puts_debug "\nCSP VIOLATIONS CAPTURED (#{violations.length}):"
      violations.each_with_index do |v, i|
        puts_debug "  Violation ##{i + 1}:"
        puts_debug "    Directive: #{v['violatedDirective']}"
        puts_debug "    Blocked URI: #{v['blockedURI']}"
        puts_debug "    Source: #{v['sourceFile']}:#{v['lineNumber']}:#{v['columnNumber']}"
        puts_debug "    Sample: #{v['sample']}"
      end
    else
      puts_debug "\nNo CSP violations captured"
    end
    puts_debug '=' * 80

    { logs:, csp_violations: violations }
  end

  #
  # Get captured browser console logs without printing.
  # @return [Hash] { logs: Array, csp_violations: Array }
  #
  def get_browser_console_logs
    logs = page.evaluate_script('window.browserLogs || []')
    violations = page.evaluate_script('window.cspViolations || []')
    { logs:, csp_violations: violations }
  end

  # Click a tab in the top report tabs bar
  def click_report_tab(tab_name)
    puts_debug "Clicking report tab: #{tab_name}"
    finish_page_loading
    dismiss_all_alerts
    available_report_tabs
    puts_alerts
    tab = find('.advanced-form-selections a', text: tab_name)
    # If the tab is already open, we may need to expand it again to refresh its contents
    redo_click = (tab['aria-expanded'] == 'true')

    tab.click
    finish_page_loading
    puts_alerts

    if redo_click
      sleep 1
      puts_debug "Tab #{tab_name} was already active, clicking again to refresh..."
      tab.click
      finish_page_loading
      puts_alerts
      sleep 1
    end
    sleep 0.5

    target = tab['data-target']
    find(target, wait: 10)
  end

  #
  # Within an activity log block that is "stacked" with model references within it to represent steps within a process.
  # get a full set of debug information about the current state of the process:
  # - alert messages showing
  # - visible user instruction placeholders
  # - available form fields
  # - available model reference expanders (the carets that are linked by #mr-expander-... ids)
  # - available submit buttons
  def debug_process_status
    puts_error_page
    puts_alerts
    available_report_tabs
    puts_modals
    current_activity_log = all('.activity-logs-generic-block.in', match: :first).first
    forms = all('form')
    if current_activity_log
      within current_activity_log do
        available_model_reference_expanders
        user_instructions_placeholders
        available_form_fields
        available_submit_fields
        available_embedded_model_reference_add_buttons
      end
    elsif !forms.empty?
      forms.each do |f|
        puts_debug "Form ##{f[:id]}:"
        within f do
          available_form_fields
          available_submit_fields
        end
      end
    end
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    puts_debug 'StaleElementReferenceError encountered in debug_process_status - skipping'
  end

  #
  # Display and return the currently visible placeholders that provide instructions to users
  # @return [Hash{String => String}] A hash mapping field names to their visible placeholder captions
  def user_instructions_placeholders
    placeholders = all('.placeholder-caption-before[data-cb-field-name]', visible: :all)
    puts_debug "Found #{placeholders.count} placeholder captions"
    results = {}
    placeholders.each do |ph|
      next unless ph.visible?

      field_name = ph['data-cb-field-name']
      puts_debug "Placeholder: #{field_name}"
      res_html = page.execute_script('return arguments[0].innerHTML;', ph)
      doc = Nokogiri::HTML.fragment(res_html)
      doc.css('a').each do |link|
        link.replace("<a href=\"#{link['href']}\">#{link.text}</a>")
      end
      res_html = doc.to_html
      res_html = res_html.gsub("\r", '').gsub(/\n\n+/, "\n")
      res_md = res_html.html_to_markdown
      puts_debug 'Caption for user:'
      puts_debug_plain '---'
      puts_debug_plain res_md
      puts_debug_plain '---'
      results[field_name] = res_md
    end
    results
  end

  def flashed_alert?(severity = nil)
    severity = ".alert-#{severity}" if severity
    page.has_css?("div.alert#{severity}", wait: 0.2)
  end

  def alert_messages
    page.all('div.alert', wait: 0.2).map { |a| { a['data-severity'] => a.text.strip } }
  end

  def available_report_tabs
    puts_debug 'Available report tabs:'

    results = []
    all('.advanced-form-selections a', wait: 0, visible: :all).each do |tab|
      res = {}
      res[:tab_name] = tab.text
      res[:resource_name] = tab['data-report-resource-name']
      res[:visible] = tab.visible?
      res[:is_active] = (tab['aria-expanded'] == 'true')
      results << res
    end
    puts_debug_plain String.yaml_dump(results)
    puts_debug_plain '---'
    results
  end

  def available_form_fields
    puts_debug 'Available form fields:'

    results = []
    all('[data-attr-name]', wait: 0, visible: :all).each do |f|
      res = {}
      res[:field_name] = f['data-attr-name']
      res[:tag_name] = f.tag_name
      res[:type] = f[:type] if f[:type]
      res[:visible] = f.visible?
      res[:value] = f.value
      res[:is_chosen] = f[:class].include?('use-chosen')
      res[:is_big_select] = f[:class].include?('use-big-select')
      res[:is_custom_editor] = f[:class].include?('use-text-area-for-custom-editor')

      if f.tag_name == 'select'
        res[:options] = f.all('option', wait: 0).map do |opt|
          { text: opt.text, value: opt[:value], selected: opt.selected? }
        end
      end
      results << res
    end

    all('.result-field-container[data-field-name]', wait: 0, visible: :all).each do |f|
      res = {}
      res[:field_name] = f['data-field-name']
      res[:visible] = f.visible?
      res[:value] = f['data-field-val']
      res[:is_basic_field] = true
      res[:is_in_show_mode] = true
      results << res
    end
    all('.result-notes-container[data-field-name]', wait: 0, visible: :all).each do |f|
      res = {}
      res[:field_name] = f['data-field-name']
      res[:visible] = f.visible?
      res[:value] = f.text
      res[:is_rich_text] = true
      res[:is_in_show_mode] = true
      results << res
    end
    puts_debug_plain String.yaml_dump(results)
    puts_debug_plain '---'
    results
  end

  def available_submit_fields
    puts_debug 'Available submit buttons:'

    results = []
    all('input[type="submit"], button[type="submit"]', visible: :all, wait: 0).each do |f|
      res = {}
      res[:tag_name] = f.tag_name
      res[:text] = f.text
      res[:value] = f.value
      res[:visible] = f.visible?
      results << res
    end
    puts_debug_plain String.yaml_dump(results)
    puts_debug_plain '---'
    results
  end

  def available_embedded_model_reference_add_buttons
    puts_debug 'Available embedded model reference add buttons:'
    all_mrs = all('a.embedded-add-item-button', visible: :all, wait: 0)
    results = []
    all_mrs.each do |mr_action|
      next unless mr_action

      res = {}
      res[:label] = mr_action.text
      res[:href] = mr_action[:href]
      res[:data_target] = mr_action['data-target']
      results << res
    end
    puts_debug_plain String.yaml_dump(results)
    puts_debug_plain '---'
    results
  end

  def available_model_reference_expanders
    puts_debug 'Available model reference expanders:'
    all_mrs = all('.in-item-model-references', visible: :all, wait: 0)
    results = []
    all_mrs.each do |mr|
      res = {}
      mr_class = mr[:class]
      next unless mr_class # Skip if class attribute is nil

      if mr_class.include?('rr-mr')
        res[:type] = 'mr-expander'
        res[:label] = mr['data-mr-name']
        mr_inner = mr.all('.mr-item-label', visible: :all, wait: 0).first
        res[:id] = mr_inner[:id]
        res[:mr_expander_id] = "mr-expander-#{mr_inner[:id]}"
        res[:visible] = mr_inner.visible?
      else
        res[:type] = 'mr-create'
        mr_action = mr.all('a.embedded-add-item-button', visible: :all, wait: 0).first
        res[:label] = mr_action.text
        res[:href] = mr_action[:href]
      end
      results << res
    end
    puts_debug_plain String.yaml_dump(results)
    puts_debug_plain '---'
    results
  end

  def puts_form_validation_errors
    results = []
    # Show which fields failed validation
    if page.has_css?('.has-error', wait: 0.3)
      results += all('.has-error .error-help')
                 .select { |lbl| lbl.text.strip.present? }
                 .map do |lbl|
                   key = lbl['data-error-key'].presence || lbl[:class]
                   { key => lbl.text.strip }
                 end
    end

    if results.present?
      puts_debug '⚠️  Form validation errors:'
      puts_debug_plain String.yaml_dump(results)
      puts_debug_plain '---'
    else
      puts_debug 'Form validation errors: none'
    end
  end

  def current_form_field_names
    all('[data-attr-name]', wait: 0).map { |f| f['data-attr-name'] }
  end

  def puts_highlighted(text)
    puts_debug_plain "\n#{'=' * 80}"
    puts_debug_plain text
    puts_debug_plain "#{'=' * 80}\n"
  end

  def puts_error_page
    epb = all('.error-page-block', wait: 0).first
    if epb.nil?
      puts_debug 'No error page block found'
      return
    end
    puts_debug '⚠️  Error page message:'
    puts_debug_plain epb.html.html_to_markdown
    puts_debug_plain '---'
  end

  def puts_alerts
    puts_debug "⚠️  Alert messages: #{alert_messages.join(' | ')}" if flashed_alert?
  end

  def puts_modals
    puts_debug 'Modals visible:'
    results = []
    all('.modal.in', visible: true, wait: 0).each do |m|
      res = {}
      res[:id] = m[:id]
      res[:title] = m.all('.modal-title').first&.text
      res[:body] = m.all('.modal-body').first&.text
      results << res
    end
    puts_debug_plain String.yaml_dump(results)
    puts_debug_plain '---'
    results
  end

  def dismiss_all_alerts
    finish_page_loading

    all('div.alert button.close', wait: 0).each(&:click)
    sleep 0.5
  end

  def take_screenshot(name = nil, description = nil, force: false)
    return unless ENV['TAKE_SCREENSHOTS'] || force

    name ||= 'screenshot'
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "#{self.class&.name&.underscore}_#{name}_#{timestamp}.png"
    filepath = Rails.root.join('tmp', 'screenshots', filename)

    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(filepath))

    # Take screenshot
    page.save_screenshot(filepath)

    # Log the screenshot
    puts_debug_plain "[Screenshot] #{name}: #{filepath}"
    puts_debug_plain "[Screenshot] #{description}" if description

    # Return relative path for documentation
    filepath.to_s
  end

  def debug_state(name = nil, description = nil, force: false)
    name ||= 'debug_state'
    original_debug = ENV['FEATURE_DEBUG']
    ENV['FEATURE_DEBUG'] = 'true' if force
    puts_debug("DEBUG STATE: #{name} - #{description}")
    begin
      filename = "#{self.class&.name&.underscore}_#{name}.html"
      filepath = File.join('/tmp', filename)
      save_html_snapshot(filepath)
    rescue Exception
      puts_debug '  - Failed to save HTML snapshot'
    end
    begin
      debug_process_status
    rescue Exception
      puts_debug '  - Failed to debug process status'
    end
    begin
      take_screenshot(name.underscore, description, force:)
    rescue Exception
      puts_debug '  - Failed to take screenshot', force:
    end

    ENV['FEATURE_DEBUG'] = original_debug
  end
end
