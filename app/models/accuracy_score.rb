class AccuracyScore < ActiveRecord::Base
  include AdminHandler
  include SelectorCache
  
  default_scope {order  :value}
  
  before_validation :prevent_value_change,  on: :update  
  validates :name, presence: true
  validates :value, presence: true

  protected
    def prevent_value_change 
      if value_changed? && self.persisted?
        errors.add(:value, "change not allowed!")
      end
    end
end
