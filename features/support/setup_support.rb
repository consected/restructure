module UserSetup

  include MasterDataSupport
  include ModelSupport

  def setup_database
    seed_database
    create_data_set

    PlayerInfo.all.each do |p|
      create_player_phone p.master
    end
  end

  def user_login
    @user, @good_password  = create_user
    @good_email  = @user.email
    login
  end

  def user_logout
    logout
  end

  def user_logged_in?
    !!have_css('.nav a[data-do-action="show-user-options"]')
  end
end

module PlayerSetup
  
  def select_player

    player = pick_one_from PlayerInfo.all
    expect(player).to be_a(PlayerInfo)
    have_link("Research")
    click_link "Research"
    have_css("#master-search-simple-form")
    within '#master-search-simple-form' do
      fill_in 'Last name', with: player.last_name
      fill_in 'First or nick name', with: player.first_name
      click_button 'search'
    end

    player
  end

end

module PhoneSetup

  def get_a_rank
    10
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

  def phone_ranks
    # probably should retrieve this from the DB, but this is sufficient for now
    ['10', '5', '1', '0', '-1']
  end

end

World(UserSetup, PlayerSetup, PhoneSetup)