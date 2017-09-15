module FeatureSupport


  def login
    visit "/users/sign_in"
    have_css('#new_user')
    expect(page).to have_css('#new_user')
    within '#new_user' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end
    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"
  end
  
  def logout
    find('.navbar-right a[data-do-action="show-user-options"]').click
    expect(page).to have_css('a[data-do-action="user-logout"]')
    click_link 'logout'

  end

  def dismiss_modal

    if all('.modal.fade.in').length > 0
      have_css('button[data-dismiss="modal"]')
      b = all('button[data-dismiss="modal"]')
      b.first.click if b && b.length > 0
      #wait for the modal to fade out before continuing
      has_no_css('.modal.fade.in')
    end
  end

  def open_player_element el, items
    dismiss_modal
    have_css('.player-info-header')
    el.find('.player-info-header').click      if items.length > 1 # it opens automatically if there is only one result
    dismiss_modal
    h = el[:href].split('#').last
    find "##{h}.collapse.in", wait: 5
    h
  end

end
