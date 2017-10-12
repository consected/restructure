class ItemFlagName < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  validates :name, presence: true
  validates :item_type, presence: true
  validate :item_type_valid?
  validate :name_and_item_type_unique
  after_validation  :update_tracker_events

  default_scope -> {order  "item_flag_names.updated_at DESC nulls last"}

  def self.enabled_for? item_type
    logger.debug "Checking we're enabled for #{item_type}"
    l = selector_array item_type: item_type
    l.length > 0
  end

  def self.item_types
    selector_array(nil, :item_type).uniq
  end

  def self.use_with_class_names
    ItemFlag.use_with_class_names
  end

  private

    def name_and_item_type_unique
      if !self.persisted? && ItemFlagName.enabled.where(item_type: self.item_type, name: self.name).length > 0
        errors.add :name, "has already been used for this item type"
      end
    end

    def item_type_valid?
      return unless item_type
      cns = ItemFlag.use_with_class_names
      unless  cns.include? item_type.ns_underscore
          errors.add(:item_type, "is attempting to use invalid item type #{item_type}. Valid items are #{cns}")
      end
    end


    def update_tracker_events
      return unless item_type
      Tracker.add_record_update_entries item_type, current_admin, 'flag'
    end
end
