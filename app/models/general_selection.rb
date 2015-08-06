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
    if record.respond_to?(:class) && record.class != Class
      klass = record.class
    else
      klass = record
    end      
    "#{klass.name.pluralize.underscore}_#{type}"
  end
  
  def self.item_type_name_value_pair record, type=:source
    src = item_type_source_for record, type
    logger.debug "getting #{src}"
    selector_name_value_pair(item_type: src)       
  end
  
  def self.name_for record, value, type=:source
    res = item_type_name_value_pair record, type
    
    logger.debug "Requesting value #{value} in #{res}"
    
    resn = res.select {|l| l.last.to_s == value.to_s}
    if resn.length == 1
      return resn.first.first
    end
    return        
  end
  
end
