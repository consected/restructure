class ItemFlagName < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  validates :name, presence: true, uniqueness: true
  
  default_scope -> {order  "item_flag_names.updated_at DESC nulls last"}

  private
    def prevent_item_type_change 
      if item_type_changed? && self.persisted?
        errors.add(:item_type, "change not allowed!")
      end
    end
end
