module AdminHandler
  extend ActiveSupport::Concern
  
  
  
  included do
    belongs_to :admin
    scope :active, -> {where "disabled <> true"}
    
    before_validation :ensure_admin_set
  end
  
  def admin_name
    return unless admin
    admin.email
  end
  
  
  def admin= new_admin
    
    raise "Bad Admin" unless new_admin.is_a?(Admin) && new_admin.id && !new_admin.disabled
    
    @admin_set = true
    write_attribute(:admin_id, new_admin.id)
  end
  
  def admin_set?
    !!@admin_set
  end
  
  def ensure_admin_set
    errors.add(:admin, "has not been set") unless admin_set?
  end

end
