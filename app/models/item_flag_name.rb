class ItemFlagName < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  validates :name, presence: true, uniqueness: true
  before_validation :prevent_name_change,  on: :update
  before_validation :prevent_item_type_change,  on: :update
  default_scope -> {order  "item_flag_names.updated_at DESC nulls last"}

  private
    def prevent_name_change 
      if name_changed? && self.persisted?
        errors.add(:name, "change not allowed!")
      end
    end
    def prevent_item_type_change 
      if item_type_changed? && self.persisted?
        errors.add(:item_type, "change not allowed!")
      end
    end
end
