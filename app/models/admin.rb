class Admin < ActiveRecord::Base

  include ActionLogging

  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  
  def timeout_in
    return 5.minutes if Rails.env.production?
    
    30.minutes
  end
  
end
