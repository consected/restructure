module AddressSupport
  include MasterSupport

  def get_a_rank
    res = Classification::GeneralSelection.where(item_type: 'player_addresses_rank').enabled.all
    res[rand res.length].value
  end

  def list_valid_attribs
    res = []

    (1..5).each do |_l|
      res << {
        street: "#{rand(10_000)} Main St",
        street2: "Apt ##{rand 100}",
        street3: (pick_one ? '(rear of building)' : nil).to_s,
        city: 'Portland',
        state: 'OR',
        zip: rand(99_999).to_s.rjust(5, '0').to_s,
        rank: 0,
        rec_type: 'home',
        source: 'nflpa'
      }
    end
    res
  end

  def list_invalid_attribs
    [
      {
        zip: '071'
      },
      {
        source: 'sss',
        zip: '01234',
        rank: 10
      }
    ]
  end

  def new_attribs
    @new_attribs = {
      street: "#{rand(10_000)} Main St",
      street2: "Apt ##{rand 100}",
      street3: (pick_one ? '(rear of building)' : nil).to_s,
      city: 'Newhaven',
      state: 'CT',
      zip: rand(99_999).to_s.rjust(5, '0').to_s,
      rank: 5,
      rec_type: 'business'
    }
  end

  def create_item(att = nil, master = nil)
    att ||= valid_attribs
    master ||= create_master
    create_sources 'addresses'
    @address = master.addresses.create! att
  end
end
