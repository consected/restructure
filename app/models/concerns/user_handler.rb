module UserHandler

  extend ActiveSupport::Concern
  
  included do
    attr_accessor :no_track
    # Standard associations
    Rails.logger.debug "Associating master as inverse of #{assoc_inverse}"

    after_initialize :init_vars_user_handler

    belongs_to :master, assoc_rules
    belongs_to :user
    
    has_many :item_flags, as: :item
    has_many :activity_logs, as: :item
    has_many :trackers, as: :item if self != Tracker && self != TrackerHistory

    # Ensure the user id is saved
    before_validation :force_write_user    

    before_validation :downcase_attributes
    
    # This validation ensures that the user ID has been set in the master object 
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validate :user_set
    
    validate :source_correct
    validate :rank_correct

    after_save :check_status
    after_save :track_record_update
  end
  
  class_methods do

    def uses_item_flags?      
      ItemFlagName.enabled_for? self.name.underscore
    end      

    def foreign_key_name
      @foreign_key_name = :master_id
    end
    
    def primary_key_name
      @primary_key_name = :id
    end
    
    def assoc_rules
      r = {inverse_of: assoc_inverse}      
      r[:foreign_key] = self.foreign_key_name if self.foreign_key_name && self.foreign_key_name != :master_id
      r[:primary_key] = self.primary_key_name if self.primary_key_name && self.primary_key_name != :id
      r
      
    end
    
    def assoc_inverse
      # The plural model name
      self.to_s.underscore.pluralize.to_sym
    end

    def get_rank_name value
      GeneralSelection.name_for self, value, :rank    
    end
    def get_source_name value
      GeneralSelection.name_for self, value, :source
    end
  end  


  def is_admin?
    if respond_to?(:master) && master      
      master.is_admin?
    else
      nil
    end
  end
  
  def master_user
    
    if respond_to?(:master) && master      
      current_user = master.current_user      
      current_user 
    else      
      nil
    end
  end
  
  def user_name
    logger.debug "Getting username for #{self.user}"
    return nil unless self.user
    self.user.email
  end
  
  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records
  def user= u
    raise "can not set user="
  end
  
  def user_id= u
    raise "can not set user_id="
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
  
  def multiple_results=mr
    @multiple_results = mr
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
    
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]} if self.class.uses_item_flags?
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
    extras[:methods] << :accuracy_score_name if respond_to? :accuracy_score
    super(extras)    
  end
  
  
  protected

    def init_vars_user_handler
      instance_var_init :was_created
      instance_var_init :updated_with
      instance_var_init :was_updated
      instance_var_init :update_action
      instance_var_init :multiple_results
    end

    def creatable_without_user
      false
    end
      
    def downcase_attributes    
      
      ignore = ['item_type']
      
      self.attributes.reject {|k,v| ignore.include? k}.each do |k, v|

        logger.info "Downcasing attribute (#{k})"
        self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
      end
      true
    end

    def user_set 
      return true if creatable_without_user && !persisted?

      unless self.user
        errors.add :user, "must be authenticated and set"
      end
    end
    def force_write_user
      return true if creatable_without_user && !persisted?
      
      raise "bad user being pulled from master_user" unless master_user.is_a?(User) && master_user.persisted?
      
      write_attribute :user_id, master_user.id
    end

    def track_record_update
      return if no_track
      @update_action = true
      Tracker.track_record_update self 
    end
  
    def source_correct      
      if respond_to?(:source) && self.source
        unless source_name
          logger.info "Requested source of #{self.source}. This is not a valid value."
          errors.add :source, "(#{self.source}) not a valid value"
        end
      end      
    end
    
    
    def rank_correct      
      if respond_to?(:rank) && self.rank
        errors.add :rank, "(#{self.rank}) not a valid value" unless rank_name
      end      
    end
end
