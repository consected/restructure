class AccuracyScore < ActiveRecord::Base
  belongs_to :admin
  include SelectorCache
  
  def admin_name
    return unless admin
    admin.email
  end
end
