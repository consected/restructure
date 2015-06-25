class ItemFlag < ActiveRecord::Base
  belongs_to :item, polymorphic: true
  belongs_to :item_flag_name
  
  
  def method_id 
    self.item.master_id
  end
  
  def item_type_us
    self.item_type.underscore
  end
  
  
  def as_json options={}
    options[:methods] ||= []
    options[:methods] += [:method_id, :item_type_us]
    options[:include] ||=[]
    options[:include] << :item_flag_name
    options[:done] = true
    super(options)
    
    
  end
  
end
