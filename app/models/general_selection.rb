class GeneralSelection < ActiveRecord::Base
  include SelectorCache
  
  ItemTypes = [:player_contacts_type, :addresses_type, :addresses_source, :scantron_source, :tracker_contact_method ]
  
  
  
end
