class Admin::ItemFlagName < ActiveRecord::Base

  self.table_name = 'item_flag_names'
  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  validates :name, presence: true
  validates :item_type, presence: true
  validate :item_type_valid?
  validate :name_and_item_type_unique
  after_save :enable_configuration
  after_save :update_tracker_events

  default_scope -> {order  "item_flag_names.updated_at DESC nulls last"}

  def self.enabled_for? item_type, user
    logger.debug "Checking we're enabled for #{item_type} with user #{user.id}"
    l = selector_array item_type: item_type
    res = l.length > 0
    # Exit immediately if we already know this is not enabled
    return false unless res

    user.has_access_to? :access, :table, "#{item_type.pluralize}_item_flags".to_sym
  end

  def self.item_types
    selector_array(nil, :item_type).uniq
  end

  def self.use_with_class_names
    ItemFlag.use_with_class_names
  end

  private

    def name_and_item_type_unique
      if !self.persisted? && Admin::ItemFlagName.enabled.where(item_type: self.item_type, name: self.name).length > 0
        errors.add :name, "has already been used for this item type"
      end
    end

    def item_type_valid?
      return unless item_type && !disabled
      cns = ItemFlag.use_with_class_names
      unless  cns.include? item_type.ns_underscore
          errors.add(:item_type, "is attempting to use invalid item type #{item_type}. Valid items are #{cns}")
      end
    end

    def enable_configuration
      ifc = item_type
      return if self.disabled
      ItemFlag.add_master_association ifc
    end

    def update_tracker_events
      return unless item_type && !disabled
      Tracker.add_record_update_entries item_type, current_admin, 'flag'
    end
end
