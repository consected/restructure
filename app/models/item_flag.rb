  class ItemFlag < ActiveRecord::Base

  include WorksWithItem
  
  belongs_to :item, polymorphic: true, inverse_of: :item_flags
  belongs_to :item_flag_name  
  
  before_validation :prevent_item_change,  on: :update
  
  # We must have a user set to save a record
  # Since we don't include the UserHandler module, it is necessary for users of this class
  # to explicitly set the user.
  # In future we can consider incorporating this into the UserHandler structure, but currently
  # all UserHandler classes belong directly to a master, and flags only belong to a master indirectly
  # through an item.
  # Since an item_flag entry is only created or deleted (not updated), setting the user explicitly on 
  # create is reasonable.

  validates :item_flag_name_id, presence: true
  validates :item_flag_name, presence: true  
  
  
  # Create and remove flags for the underlying item.
  # Returns true if flags were added or removed
  def self.set_flags flag_list, item, current_user
    
    current_flags = item.item_flags.map {|f| f.item_flag_name_id}.uniq
    added_flags = flag_list - current_flags
    removed_flags =  current_flags - flag_list
    
    logger.info "Current flags #{current_flags} in #{item}"    
    logger.info "Removing flags #{removed_flags} from #{item}"
    logger.info "Adding flags #{added_flags} to #{item}"
    
    item.item_flags.where(item_flag_name_id: removed_flags).each do |i|
        i.disabled = true
        i.save!
    end
        
    added_flags.each do |f|
      unless f.blank?
        i = item.item_flags.build item_flag_name_id: f, user: current_user
        logger.info "Added flag #{f} to #{item}"
        i.save!
      end
    end
    
    # Reload the association to have it register the changes    
    item.item_flags.reload        
    item.master.current_user = current_user      
    
    logger.info "Remaining flags in #{item} for #{item.master_user}: #{item.item_flags.map {|f| f.id}}"
    if added_flags.length > 0 || removed_flags.length > 0
      ItemFlag.track_flag_updates item, added_flags, removed_flags
      update_action = true
    end
    
    return update_action
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
    
    def prevent_item_change
      errors.add :item_flag_name_id, "can not be changed" if item_flag_name_id_changed?
    end
  
end
