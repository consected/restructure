class GeneralSelection < ActiveRecord::Base
  
  include AdminHandler
  include SelectorCache
  ItemTypes = [:player_contacts_type, :player_contacts_source, :addresses_type, :addresses_source, :addresses_rank, :player_contacts_rank, :tracker_contact_method ]
  validates :name, presence: true
  validates :value, presence: true
  before_validation :prevent_value_change,  on: :update
  
  
  def prevent_value_change 
    if value_changed? && self.persisted?
      errors.add(:value, "change not allowed!")
    end
    if item_type_changed? && self.persisted?
      errors.add(:item_type, "change not allowed!")
    end
  end
  
  
  def self.item_type_source_for record, type=:source
    if record.respond_to? :class
      klass = record.class
    else
      klass = record
    end      
    "#{klass.name.pluralize.underscore}_#{type}"
  end
  
  def self.item_type_name_value_pair record, type=:source
    src = item_type_source_for record, type
    selector_name_value_pair(item_type: src)       
  end
  
end
