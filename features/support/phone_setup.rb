module PhoneSetup

  OpenPhoneLogLinkCss = "a[title='open Phone log']"
  PlayerContactPhoneNumberCss = '.player-contact-data strong'
  PhoneLogBlockCss ='.activity-logs-player-contact-phone-type-block.in'


  def player_contact_phone_block_css with_rank=nil
    check_rank = ''
    if with_rank
      check_rank = "='#{with_rank}'"
    end
    ".player-contact-item.phone-type .list-group[data-item-rank#{check_rank}]"
  end
  
  def get_a_phone_rank
    phone_ranks[rand(2).to_i]
  end

  def phone_ranks
    # probably should retrieve this from the DB, but this is sufficient for now
    ['10', '5', '1', '0', '-1']
  end


  def phone_attribs
    [
      {
        data: "(761)897-8144",
        source: 'nflpa',
        rank: (get_a_phone_rank),
        rec_type: 'phone'
      },
      {
        data: "(516)262-1289",
        source: 'nfl',
        rank: (get_a_phone_rank),
        rec_type: 'phone'
      },
      {
        data: "(516)262-1289 ext 2342",
        source: 'nfl',
        rank: (get_a_phone_rank),
        rec_type: 'phone'
      }
    ]
  end

  def create_player_phone master, num=1
    master.current_user = @user
    res = []
    if num == 1
      attr = pick_one_from(phone_attribs)
      pc = master.player_contacts.create! attr
      res << pc
    else
      num.times do |i|
        attr = phone_attribs[i]
        pc = master.player_contacts.create! attr
        res << pc
      end
    end
    res
  end

  def top_ranked_phone
    finish_form_formatting
    expect(page).to have_css(player_contact_phone_block_css)

    top_ranked = nil
    phone_ranks.each do |rank|
      phone_block_css = player_contact_phone_block_css(rank)
      scroll_to phone_block_css, check_it: false      
      if have_css(phone_block_css)
        top_ranked = all(phone_block_css).first
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
    expect(page).to have_css(PhoneLogBlockCss)
    finish_form_formatting
    
    have_css(PhoneLogBlockCss)
  end

  def show_top_ranked_phone_log
    finish_form_formatting
    
    expect(top_ranked_phone).to have_link_to_open_phone_log
    within top_ranked_phone do
      @player_phone_num = find(PlayerContactPhoneNumberCss).text.downcase
      find(OpenPhoneLogLinkCss).click
    end

    expect(page).to have_loaded_phone_log
  end



end

World(PhoneSetup)
