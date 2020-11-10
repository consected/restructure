module PlayerSetup

  def select_player

    player = pick_one_from @test_player_infos
    expect(player).to be_a(PlayerInfo)
    have_link("Research")
    click_link "Research"
    have_css("#master-search-simple-form")
    within '#master-search-simple-form' do
      fill_in 'Last name', with: player.last_name
      fill_in 'First or nick name', with: player.first_name
      click_button 'search'
    end

    dismiss_modal
    finish_form_formatting
    dismiss_modal
    player
  end


  def edit_player_info_record
    expect(@master.id).not_to be nil

    player_info_css = "#details-#{@master.id} .player-info-item"
    expect(page).to have_selector(player_info_css, visible: true)
    within player_info_css do |block|
      all('a.edit-player-info').first.click
      expect(page).to have_css('form.edit_player_info')
      click_link 'cancel'
    end
    finish_form_formatting
  end
end
