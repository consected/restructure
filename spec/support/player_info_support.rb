module PlayerInfoSupport
  include MasterSupport

  def get_a_rank
    ranks = Classification::AccuracyScore.enabled
    ranks[rand(ranks.length)].value
  end

  def list_valid_attribs
    res = []

    (1..5).each do |_l|
      bd = (Date.today - rand(30..79).years)
      bd = opt(bd)

      dd = nil
      dd = opt(Date.today - rand(10).years) if bd

      start_year = nil
      start_year = opt(bd.year + rand(10) + 19) if bd
      end_year = opt(start_year ? [start_year + rand(7), Date.today.year].max : nil)

      rank = get_a_rank
      rank = PlayerInfo::FollowUpScore unless bd

      res << {
        first_name: pick_from(first_names).downcase,
        last_name: pick_from(last_names).downcase,
        middle_name: pick_from(first_names).downcase,
        nick_name: pick_from(other_names).downcase,
        birth_date: bd,
        death_date: dd,
        rank: rank,
        source: 'nflpa',
        start_year: start_year,
        end_year: end_year,
        notes: 'kjsad hfkshfk jskjfhksa!jdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsa,hdg jsgadfjgsajdf?gsf gsgf sdgj sa fj'
      }
    end

    res
  end

  def list_invalid_attribs
    [{
      birth_date: Date.today + 1.day,
      death_date: Date.today + 1.day
    },
     {
       birth_date: Date.today - 100.days,
       death_date: Date.today - 101.days
     },
     {
       source: nil,
       rank: 881

     }]
  end

  def new_attribs
    @new_attribs = {
      first_name: pick_from(first_names).downcase,
      last_name: pick_from(last_names).downcase,
      middle_name: nil,
      nick_name: nil,
      birth_date: nil,
      death_date: nil,
      rank: 881,
      start_year: rand(1980..1989),
      end_year: rand(1990..1999),
      notes: 'kjsad hfkshfk jskjfhksajdhf sadf js dfjk sdkjf sdkjf\njg fjdhsag fjsahdg <script>window.location.href="https://google.com";</script>jsgadfjgsajdfgsf gsgf sdgj sa fj'
    }

    @new_attribs
  end

  def create_item(att = nil, master = nil, no_access_change: false)
    att ||= valid_attribs
    master ||= create_master
    create_sources 'player_infos'
    setup_access :player_infos unless no_access_change
    @player_info = master.player_infos.create! att
  end
end
