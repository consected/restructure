class Admin < ActiveRecord::Base
  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  
  def timeout_in
    5.minutes
  end
  
end
