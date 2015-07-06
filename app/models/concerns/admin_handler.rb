module AdminHandler
  extend ActiveSupport::Concern
  
  included do
    belongs_to :admin

  end
  
  def admin_name
    return unless admin
    admin.email
  end

end
