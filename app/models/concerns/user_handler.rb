module UserHandler

  extend ActiveSupport::Concern
  
  included do

    # Standard associations
    Rails.logger.debug "Associating master as inverse of #{self.to_s.underscore.pluralize.to_sym}"
    belongs_to :master, inverse_of: self.to_s.underscore.pluralize.to_sym
    belongs_to :user
    has_many :item_flags, as: :item
    
    # Ensure the user id is saved
    before_validation :force_write_user    
#    before_save :user_id_will_change!
    #before_save :user_will_change!
    before_validation :downcase_attributes
    
    # This validation ensures that the user ID has been set in the master object 
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validates :user, presence: true
    
    after_save :track_record_update
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
  
  
  def as_json extras={}
    extras[:include] ||= {}
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
    extras[:methods] ||= []
    extras[:methods] << :user_name
    super(extras)    
  end
  
  
  protected
    def downcase_attributes    
      self.attributes.each do |k, v|

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
       Tracker.track_record_update self
    end
  
end
