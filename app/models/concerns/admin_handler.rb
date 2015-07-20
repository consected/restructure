module AdminHandler
  extend ActiveSupport::Concern
  
  
  
  included do
    belongs_to :admin
    scope :active, -> {where "disabled <> true"}
  end
  
  def admin_name
    return unless admin
    admin.email
  end

end
