module PlayerContactSupport
  include MasterSupport

  def get_a_rank
    res = Classification::GeneralSelection.where(item_type: 'player_contacts_rank').enabled.all
    r = res[rand res.length].value

    r
  end

  def list_valid_attribs
    [
      {
        data: "brian@test.com",
        source: 'nflpa',
        rank: (get_a_rank),
        rec_type: 'email'
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


  def list_invalid_attribs
    [
      {
        data:  'brian@hgasdhgf',
        rec_type: 'email'
      },
      {
        data: '(615)661-898a',
        rec_type: 'phone'
      },
      {
        data: nil,
        rec_type: 'phone'
      },
      {
        rank: nil
      }
    ]
  end


  def new_attribs
    @new_attribs = {
      data: '(615)661-8983 ext 1364',
      rec_type: 'phone',
      rank: -1

    }
  end

  def create_item att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    create_sources 'player_contacts'

    att[:rec_type] ||= :phone
    @player_contact = master.player_contacts.create! att
  end

end
