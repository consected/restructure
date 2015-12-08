class GeneralSelection < ActiveRecord::Base

  # Handle general selection functionality, typically for looking up drop-down values from cache
  
  include AdminHandler
  include SelectorCache
  BasicItemTypes = [:player_infos_source, :player_contacts_type, :player_contacts_source, :addresses_type, :addresses_source, :addresses_rank, :player_contacts_rank]
  
  default_scope {order  item_type: :asc, disabled: :asc, position: :asc}
  
  before_validation :prevent_value_change,  on: :update
  validates :name, presence: true
  validates :value, presence: true
  

  def self.item_types
    BasicItemTypes + Report.item_types
  end
  
  # Format the item type source string for looking up different selection types from the general_selections table  
  def self.item_type_source_for record, type=:source
    if record.respond_to?(:class) && record.class != Class
      klass = record.class
    else
      klass = record
    end      
    "#{klass.name.pluralize.underscore}_#{type}"
  end
  
  # Get an array of name value pairs for a particular record, and the type of attribute it corresponds to
  def self.item_type_name_value_pair record, type=:source
    src = item_type_source_for record, type  
    selector_name_value_pair(item_type: src)       
  end
  
  # Quickly lookup the name for a general_selection record with a specific value, corresponding to a 'record', 
  # with the type of attribute it corresponds to 
  def self.name_for record, value, type=:source
    res = item_type_name_value_pair record, type
    
    resn = res.select {|l| l.last.to_s == value.to_s}
    if resn.length == 1
      return resn.first.first
    end
    return        
  end

  protected
  
    def prevent_value_change 
      if value_changed? && self.persisted?
        errors.add(:value, "change not allowed!")
      end
      if item_type_changed? && self.persisted?
        errors.add(:item_type, "change not allowed!")
      end
    end
  
end
