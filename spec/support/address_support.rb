module AddressSupport
  include MasterSupport

  def get_a_rank
    res = Classification::GeneralSelection.where(item_type: 'player_addresses_rank').enabled.all
    r = res[rand res.length].value

    r
  end

  def list_valid_attribs
    res = []

    (1..5).each do |l|
      res << {
        street: "#{rand(10000)} Main St",
        street2: "Apt ##{rand 100}",
        street3: "#{pick_one ? '(rear of building)' : nil}",
        city: "Portland",
        state: "OR",
        zip: "#{rand(99999).to_s.rjust(5, "0")}",
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
        source: 'sss'
      }
    ]
  end

  def new_attribs
    @new_attribs = {
      street: "#{rand(10000)} Main St",
      street2: "Apt ##{rand 100}",
      street3: "#{pick_one ? '(rear of building)' : nil}",
      city: "Newhaven",
      state: "CT",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
      rank: 5,
      rec_type: 'business'
    }
  end



  def create_item att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    create_sources 'addresses'
    @address = master.addresses.create! att
  end

end
