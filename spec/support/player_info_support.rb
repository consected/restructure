module PlayerInfoSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      bd = (Date.today - (rand(50)+30).years)
      bd = opt(bd)

      dd = nil    
      if bd      
        dd = opt(Date.today - (rand(10).years) )
      end

      start_year = nil
      start_year = opt(bd.year + rand(10) + 19 ) if bd

      rank = rand(999)
      rank = PlayerInfo::FollowUpScore if !bd
      
      res << {
        first_name: pick_from(first_names).downcase,
        last_name: pick_from(last_names).downcase,
        middle_name: pick_from(first_names).downcase,
        nick_name: pick_from(other_names).downcase,
        birth_date: bd,
        death_date: dd,
        rank: rank,
        start_year: start_year,
        end_year: opt(start_year ? start_year + rand(12) : nil),
        notes: 'kjsad hfkshfk jskjfhksa!jdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsa,hdg jsgadfjgsajdf?gsf gsgf sdgj sa fj'
      }
    end
    
    res
  end
  
  def list_invalid_attribs
    [{
      birth_date:  Date.today + 1.day,
      death_date:  Date.today + 1.day
    },    
    {
      birth_date: Date.today - 100.days,
      death_date: Date.today - 101.days
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
  
  def create_item  att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    @player_info = master.player_infos.create! att
  end
  
end
