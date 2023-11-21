module PhoneSetup
  def player_contact_phone_block_css(with_rank = nil)
    check_rank = ''
    check_rank = "='#{with_rank}'" if with_rank
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
        data: '(761)897-8144',
        source: 'nflpa',
        rank: get_a_phone_rank,
        rec_type: 'phone'
      },
      {
        data: '(516)262-1290',
        source: 'nfl',
        rank: get_a_phone_rank,
        rec_type: 'phone'
      },
      {
        data: '(516)262-1289 ext 2342',
        source: 'nfl',
        rank: get_a_phone_rank,
        rec_type: 'phone'
      }
    ]
  end

  def create_player_phone(master, num = 1)
    master.current_user = @user
    let_user_create :player_contacts

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

    raise 'phone does not have a rank!' unless phone_ranks.include?(res.last.rank.to_s)

    res
  end
end
