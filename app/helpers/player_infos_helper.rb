module PlayerInfosHelper
  
  
  def player_info_rank_array_pair
    AccuracyScore.selector_name_value_pair.map {|a| ["#{a.last} - #{a.first}", a.last]}
  end
  
end
