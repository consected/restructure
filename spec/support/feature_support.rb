# frozen_string_literal: true

require './spec/support/feature_helper'
require './spec/support/user_actions_setup'
module FeatureSupport
  include FeatureHelper
  include UserActionsSetup

  ResultsMasterPanel = '.results-panel .master-panel'
  ResultsMasterExpander = '.master-expander'

  def login
    just_signed_in = false
    already_signed_in = false
    change_setting('TwoFactorAuthDisabledForUser', false)
    # !two_factor_auth_disabled && !(otp_secret.present? && otp_required_for_login)
    expect(@user.two_factor_setup_required?).to be_falsey, "#{@user.two_factor_auth_disabled}, #{@user.otp_secret.present?}, #{@user.otp_required_for_login}"

    3.times do
      return if user_logged_in?

      visit '/users/sign_in'
      have_css('#new_user')

      if all('#new_user').empty?
        # Avoid a weird race condition
        sleep 5
        return if user_logged_in?
      end
      expect(page).to have_css('#new_user')

      if @user.email != @good_email
        puts "in login @user does not match @good_email: #{@user} does not match #{@good_email}"
        @user = User.active.where(email: @good_email).first
      end

      expect(@user.valid_password?(@good_password)).to be(true), "Bad password (#{@good_password}) so can't login with email: #{@good_email}. #{@user}"
      expect(@user.email).to eq @good_email

      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).to have_selector('#new_user', visible: true)
      expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Log in'
      end

      already_signed_in = user_logged_in?
      next if already_signed_in

      have_css '.flash .alert'

      fa = all('.flash .alert')[0]
      if fa
        just_signed_in = (fa.text == "×\nSigned in successfully.")
        puts fa.text unless just_signed_in
      end

      break if just_signed_in

      sleep 35
      # puts "Attempting another login"
      # has_css?(".flash .alert", text: "× Invalid email, password or two-factor authentication code.")
    end

    expect(just_signed_in || already_signed_in).to be true
    finish_page_loading
  end

  def logout
    dismiss_modal
    sleep 1
    have_css('.navbar-right a[data-do-action="show-user-options"]')
    find('.navbar-right a[data-do-action="show-user-options"]').click
    have_css('.navbar-right li.dropdown.open .dropdown-menu')
    expect(page).to have_css('.dropdown-menu a[data-do-action="user-logout"]')
    click_link 'logout'
  end

  def finish_form_formatting
    have_no_css('.formatting-block')
    have_no_css('.collapsing')
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
    if !all('.modal.fade.in', wait: false).empty?
      finish_form_formatting
      have_css('button[data-dismiss="modal"]')
      b = all('button[data-dismiss="modal"]', wait: false)
      b.first.click if b && !b.empty?
      # wait for the modal to fade out before continuing
      has_no_css?('.modal.fade.in')
      has_css?('.modal[style~="display: none"]')
    else
      # Places a javascript event handler on the modal to hide it automatically when it shows
      force_modal_hide
    end
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

  def expand_master(index)
    has_css?('.results-panel')
    finish_form_formatting
    els = all_master_record_expanders
    el = els[index]
    h = open_player_element el, els
    new_panel = find("##{h}")
    expect(new_panel).to have_css('.master-main-panel')
  end

  def expand_master_record_tab(name)
    finish_form_formatting
    tab_link = all("ul.details-tabs li a[data-panel-tab='#{name.id_underscore}']").first
    expect(tab_link).not_to be nil
    all('ul.details-tabs').first.click_link name if tab_link['aria-expanded'] != 'true'
  end

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
end
