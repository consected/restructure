module PlayerContactSupport
  include MasterSupport
  
  def list_valid_attribs
    [
      {
        data: "brian@test.com",
        source: 'nflpa',
        rank: opt(rand(10)),
        active: true,
        rec_type: 'email'
      },
      {
        data: "(516)262-1289",
        source: 'nfl',
        rank: opt(rand(10)),
        active: true,
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
      }
    ]
  end
  
  
  def new_attribs
    @new_attribs = {
      data: '(615)661-8983 ext 1364',
      rec_type: 'phone',
      active: false,
      rank: -1
      
    }
  end
    
  def create_item att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    @player_contact = master.player_contacts.create! att
  end
  
end
