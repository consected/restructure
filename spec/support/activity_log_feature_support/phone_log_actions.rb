module PhoneLogActions

  OpenPhoneLogLinkCss = "a[title='open phone log']"
  PlayerContactPhoneNumberCss = 'h4.list-group-item-heading'
  PhoneLogBlockCss ='.activity-log--player-contact-phones-block.in'


  def show_top_ranked_phone_log
    finish_form_formatting

    expect(top_ranked_phone).to have_link_to_open_phone_log
    within top_ranked_phone do
      has_css?(OpenPhoneLogLinkCss)
      @player_phone_num = find(PlayerContactPhoneNumberCss).text.downcase
      find(OpenPhoneLogLinkCss).click
    end

    expect(@player_phone_num).not_to be nil
    expect(page).to have_loaded_phone_log
  end

  def top_ranked_phone
    finish_form_formatting
    expect(page).to have_css(player_contact_phone_block_css)

    top_ranked = nil
    phone_ranks.each do |rank|
      phone_block_css = player_contact_phone_block_css(rank)
      scroll_to phone_block_css, check_it: false
      sleep 1
      top_ranked = all(phone_block_css).first
      if top_ranked
        break
      end
    end

    if !top_ranked
      res = all(player_contact_phone_block_css)
      m = res.map {|a| a['data-item-rank'] }.join(', ')
      puts "Exiting top_ranked_phone without finding a phone record. Tried ranks #{phone_ranks.join(', ')}. But #{res.length} phone type blocks were found with ranks #{m}"
    end

    top_ranked
  end

  def have_link_to_open_phone_log
    have_css(OpenPhoneLogLinkCss)
  end

  def have_loaded_phone_log
    dismiss_modal
    finish_form_formatting

    expect(page).to have_css(PhoneLogBlockCss)
    finish_form_formatting

    have_css(PhoneLogBlockCss)
  end


end
