module PlayerInfoSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      bd = (DateTime.now - (rand(50)+20).years)
      bd = opt(bd)

      dd = nil    
      if bd      
        dd = opt(DateTime.now - (rand(10).years) )
      end

      start_year = opt(rand(10)+1980)

      res << {
        first_name: "Brian",
        last_name: "Adams-Fuller",
        middle_name: "Davido",
        nick_name: "Kendrick",
        birth_date: bd,
        death_date: dd,
        rank: rand(999),
        start_year: start_year,
        end_year: opt(start_year ? start_year + rand(12) : nil)
      }
    end
    
    res
  end
  
  def list_invalid_attribs
    [{
      birth_date:  DateTime.now + 1.day,
      death_date:  DateTime.now + 1.day
    },    
    {
      birth_date: DateTime.now - 100.days,
      death_date: DateTime.now - 101.days
    }]
  end

    
  def new_attribs
    @new_attribs = {
      first_name: "Carl",
      last_name: "Jameson",
      middle_name: nil,
      nick_name: nil,
      birth_date: nil,
      death_date: nil,
      rank: rand(10),
      start_year: rand(10)+1980,
      end_year: rand(10)+1990
    }
  end
  
  def create_item att=nil
    att ||= valid_attribs
    @player_info = create_master.player_infos.create! att
  end
  
end
