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
        first_name: pick_from(first_names).downcase,
        last_name: pick_from(last_names).downcase,
        middle_name: pick_from(first_names).downcase,
        nick_name: pick_from(other_names).downcase,
        birth_date: bd,
        death_date: dd,
        rank: rand(999),
        start_year: start_year,
        end_year: opt(start_year ? start_year + rand(12) : nil),
        notes: 'kjsad hfkshfk jskjfhksajdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsahdg jsgadfjgsajdfgsf gsgf sdgj sa fj'
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
      first_name:  pick_from(first_names).downcase,
      last_name:  pick_from(last_names).downcase,
      middle_name: nil,
      nick_name: nil,
      birth_date: nil,
      death_date: nil,
      rank: rand(10),
      start_year: rand(10)+1980,
      end_year: rand(10)+1990,
      notes: 'kjsad hfkshfk jskjfhksajdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsahdg <script>window.location.href="https://google.com";</script>jsgadfjgsajdfgsf gsgf sdgj sa fj'
    }
  end
  
  def create_item att=nil
    att ||= valid_attribs
    @player_info = create_master.player_infos.create! att
  end
  
end
