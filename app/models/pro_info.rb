class ProInfo < ActiveRecord::Base
  include UserHandler
  
  has_one :player_info
  
end
