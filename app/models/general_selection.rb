class GeneralSelection < ActiveRecord::Base
  
  include AdminHandler
  include SelectorCache
  
  ItemTypes = [:player_contacts_type, :addresses_type, :addresses_source, :scantron_source, :tracker_contact_method ]
  
  
  
end
