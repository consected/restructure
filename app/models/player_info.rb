class PlayerInfo < ActiveRecord::Base
  
  include UserHandler
  
  
  # This is here to link the player_info record to the matched pro_info record from the master list
  # Although the player_info does not formally belong to the pro_info, the pro_info_id foreign 
  # key is on the player_info table, and therefore requires a belongs_to association
  belongs_to :pro_info, inverse_of: :player_info
 
  # Allow simple search to function
  attr_accessor :contact_data
  
  before_save :check_college

  def accuracy_rank
    if rank >= 20  
      return rank * -1 
    else 
      return rank 
    end
  end
 
  def as_json extras={}
    extras[:include] ||= {}
    extras[:include].merge!({pro_info: {}})
    super(extras)
  end

private

  def check_college
    College.create_if_new college
  end
  
end
