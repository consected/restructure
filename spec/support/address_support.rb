module AddressSupport
  include MasterSupport
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
        rank: 1,
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
      rank: 2,
      rec_type: 'business'
    }
  end
  
  
  
  def create_item att=nil
    att ||= valid_attribs
    
    create_sources
    @address = create_master.addresses.create! att
  end
  
end
