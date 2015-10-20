module AdminHandler
  extend ActiveSupport::Concern
  
  included do
    belongs_to :admin
    scope :active, -> {where "disabled <> true"}
    
    before_validation :ensure_admin_set
    before_create :setup_values
  end
  
  def setup_values    
    disabled = false if disabled.nil?    
    true
  end
  
  def enabled?
    !disabled
  end
   
  def admin_name
    return unless admin
    admin.email
  end
  
  def admin= new_admin
    raise "can not change admin"
  end
  
  def admin_id= new_admin
    raise "can not change admin id"
  end
  
  def current_admin= new_admin    
    raise "Bad Admin" unless new_admin.is_a?(Admin) && new_admin.id && !new_admin.disabled    
    @admin_set = true
    @current_admin = new_admin
    write_attribute(:admin_id, new_admin.id)
  end
  
  def current_admin
    return nil unless @admin_set
    @current_admin
  end
  
  # use this to check whether a current admin user has been assigned to act on this record  
  def admin_set?
    !!@admin_set
  end
  
  def ensure_admin_set
    errors.add(:admin, "has not been set") unless admin_set?
  end

end
