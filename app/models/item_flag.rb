class ItemFlag < ActiveRecord::Base
  belongs_to :item, polymorphic: true
  belongs_to :item_flag_name
  
  def as_json options={}
    
    o = self.dup
    o[:item_id] = self.item_id
    o[:item_type] = self.item_type.underscore
    o[:master_id] = self.item.master_id
    o.as_json(options)
    
    
  end
  
end
