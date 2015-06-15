class ProInfo < ActiveRecord::Base
  include UserHandler
  
  has_one :player_info, inverse_of: :pro_info
  
end
