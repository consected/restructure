class ItemFlag < ActiveRecord::Base
  belongs_to :item, polymorphic: true
  belongs_to :item_flag_name
  
  
#  belongs_to :user
#  before_validation :force_write_user    
# 
#  validates :user, presence: true
#  after_save :track_record_update
#  
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

protected
  
  
  def self.track_flag_updates item, added_flags, removed_flags
    logger.info "Track record update for added item_flags #{added_flags} and removed #{removed_flags}"
    Tracker.track_flag_update item, added_flags, removed_flags
  end
  
  
end
