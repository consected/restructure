module UserHandler

  extend ActiveSupport::Concern
  
  included do

    # Standard associations
    Rails.logger.debug "Associating master as inverse of #{self.to_s.underscore.pluralize.to_sym}"
    belongs_to :master, inverse_of: self.to_s.underscore.pluralize.to_sym
    belongs_to :user
    
    has_many :item_flags, as: :item
    has_many :trackers, as: :item if self != Tracker && self != TrackerHistory
    
    # Ensure the user id is saved
    before_validation :force_write_user    

    before_validation :downcase_attributes
    
    # This validation ensures that the user ID has been set in the master object 
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validates :user, presence: true

    after_save :check_status
    after_save :track_record_update
  end
  
  class_methods do
    def get_rank_name value
      GeneralSelection.name_for self, value, :rank    
    end
    def get_source_name value
      GeneralSelection.name_for self, value, :source
    end
  end  
  
  def master_user
    
    if respond_to?(:master) && master      
      current_user = master.current_user
      logger.debug "Getting current user #{current_user} from #{master} in #{self}"
      current_user 
    else
      logger.debug "Getting user_id in #{self} - no master!"
      nil
    end
  end
  
  def user_name
    logger.debug "Getting username for #{self.user}"
    return nil unless self.user
    self.user.email
  end
  
  def rank_name
    return nil unless respond_to? :rank
    
    self.class.get_rank_name self.rank
  end
  
  def source_name
    return nil unless respond_to? :source
    
    self.class.get_source_name self.source
  end
  
  
  def update_action
    @update_action
  end
  
  def multiple_results
    @multiple_results ||= []
  end
  
  def has_multiple_results
    @multiple_results && @multiple_results.length > 0
  end
  
  def item_type
    self.class.name.singularize.underscore
  end
  
  def check_status
    @was_created = id_changed? ? 'created' : false
    @was_updated = updated_at_changed? ? 'updated' : false
  end
  
  def _created
    @was_created
  end
  
  def _updated
    @was_updated
  end
  
  def as_json extras={}
    extras[:include] ||= {}
    # Re-enable the following line if there is a need to incorporate item flags back into all
    # objects attached to a master
    # Only player_info is using it currently, therefore it is included only within that class
    #extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
    extras[:methods] ||= []
    extras[:methods] << :user_name
    # update_action can be used by requestor to identify whether the record was just updated (saved) or not
    extras[:methods] << :update_action
    extras[:methods] << :item_type
    extras[:methods] << :_created
    extras[:methods] << :_updated
    
    extras[:methods] << :rank_name if respond_to? :rank        
    extras[:methods] << :state_name if respond_to? :state
    extras[:methods] << :country_name if respond_to? :country
    extras[:methods] << :source_name if respond_to? :source
    
    super(extras)    
  end
  
  
  protected
    def downcase_attributes    
      
      ignore = ['item_type']
      
      self.attributes.reject {|k,v| ignore.include? k}.each do |k, v|

        logger.info "Downcasing attribute (#{k})"
        self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
      end
      true
    end


    def force_write_user
      logger.debug "Forcing self.user = #{master_user}"
      self.user = master_user
    end

    def track_record_update
      @update_action = true
       Tracker.track_record_update self
    end
  
end
