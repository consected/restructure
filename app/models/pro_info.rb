class ProInfo < ActiveRecord::Base
  include UserHandler
  
  before_update :prevent_save
  
  #has_one :player_info, inverse_of: :pro_info
  attr_accessor :enable_updates
  
  protected
    def prevent_save
      return false unless @enable_updates
      return true
    end
end
