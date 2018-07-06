require './spec/support/feature_helper.rb'
module FeatureSupport

  include FeatureHelper

  ResultsMasterPanel = '.results-panel .master-panel'
  ResultsMasterExpander = '.master-expander'

  def login
    visit "/users/sign_in"
    have_css('#new_user')
    expect(page).to have_css('#new_user')
    within '#new_user' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end
    already_signed_in = user_logged_in?
    just_signed_in = has_css? ".flash .alert", text: "× Signed in successfully" unless already_signed_in
    expect(just_signed_in || already_signed_in).to be true
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


  def dismiss_modal

    finish_form_formatting
    if all('.modal.fade.in').length > 0
      finish_form_formatting
      have_css('button[data-dismiss="modal"]')
      b = all('button[data-dismiss="modal"]')
      b.first.click if b && b.length > 0
      #wait for the modal to fade out before continuing
      has_no_css?('.modal.fade.in')
      has_css?('.modal[style~="display: none"]')
    else
      # Places a javascript event handler on the modal to hide it automatically when it shows
      force_modal_hide
    end
  end

  def open_player_element el, items
    dismiss_modal
    have_css('.player-info-header')
    if items.length > 1 # it opens automatically if there is only one result
      el.find('.player-info-header').click
    else
      el = find('.master-expander')
      el.find('.player-info-header')
    end

    dismiss_modal
    h = el[:href].split('#').last
    find "##{h}.collapse.in", wait: 5
    h
  end

  def expect_master_record
    expect(page).to have_css(ResultsMasterPanel)
  end

  def all_master_record_panels
    all(ResultsMasterPanel)
  end

  def all_master_record_expanders
    has_css?(ResultsMasterExpander)
    all(ResultsMasterExpander)
  end

  def expand_master index
    has_css?('.results-panel')
    finish_form_formatting
    els = all_master_record_expanders
    el = els[index]
    h = open_player_element el, els
    new_panel = find("##{h}")
    expect(new_panel).to have_css('.master-main-panel')
  end

  def expand_master_record_tab name
    finish_form_formatting
    tab_link = all("ul.details-tabs li a[data-panel-tab='#{name.id_underscore}']").first
    expect(tab_link).not_to be nil
    if tab_link['aria-expanded'] != 'true'
      all('ul.details-tabs').first.click_link name
    end
  end

  def expand_search_with_button name
    search_btn = all(".advanced-form-selections a[type='button']").select {|b| b.text == name}.first
    expect(search_btn).not_to be nil
    if search_btn[:class].include?('collapsed')
      search_btn.click
    end

    form_id = search_btn['data-result-target']
    expect(page).to have_css(form_id)
  end

end
