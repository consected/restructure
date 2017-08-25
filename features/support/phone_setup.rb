module PhoneSetup

  def get_a_rank
    10
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
        rank: (get_a_rank),
        rec_type: 'phone'
      },
      {
        data: "(516)262-1289",
        source: 'nfl',
        rank: (get_a_rank),
        rec_type: 'phone'
      },
      {
        data: "(516)262-1289 ext 2342",
        source: 'nfl',
        rank: (get_a_rank),
        rec_type: 'phone'
      }
    ]
  end

  def create_player_phone master
    master.current_user = @user
    master.player_contacts.create! pick_one_from(phone_attribs)
  end

  def top_ranked_phone

    expect(page).to have_css(".player-contact-item.phone-type")

    top_ranked = nil
    phone_ranks.each do |rank|
      phone_block_css = ".player-contact-item.phone-type .list-group[data-item-rank='#{rank}']"
      if have_css(phone_block_css)
        top_ranked = all(phone_block_css).first
        break
      end
    end
    top_ranked
  end

  def show_top_ranked_phone_log
    expect(top_ranked_phone).to have_link('Phone log')
    within top_ranked_phone do
      @player_phone_num = find('.player-contact-data strong').text.downcase
      click_link 'Phone log'
    end
  end

  def make_call_to_selected_phone
    click_link "make call to player"
  end


end

World(PhoneSetup)
