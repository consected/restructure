module UserHandler

  extend ActiveSupport::Concern
  
  included do
    # This validation ensures that the user ID has been set in the master object 
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validates :user_id, presence: true
    belongs_to :master, inverse_of: self.to_s.underscore.pluralize.to_sym
    belongs_to :user
  
  end
  
  def user_id= cu
    if respond_to? :master
      self.master.current_user = cu
    end
  end
  
  def user_id
    
    if respond_to? :master
      current_user = master.current_user
      logger.info "Getting current user #{current_user} from #{master}"
      current_user
    else
      nil
    end
  end
  
  
end
