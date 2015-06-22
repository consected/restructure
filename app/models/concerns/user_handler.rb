module UserHandler

  extend ActiveSupport::Concern
  
  included do
    # This validation ensures that the user ID has been set in the master object 
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validates :user_id, presence: true
    belongs_to :master, inverse_of: self.to_s.underscore.pluralize.to_sym
    belongs_to :user
    
    
    has_many :item_flags, as: :item
    
    # Ensure the user id is saved
    before_save :user_id_will_change!
    before_save :downcase_attributes
  end
  
  def user_id= cu
    @user_id = cu
    if respond_to? :master
      self.master.current_user = cu
    end
  end
  
  def user_id
    
    if respond_to?(:master) && master
      current_user = master.current_user
      logger.info "Getting current user #{current_user} from #{master}"
      current_user
    else
      nil
    end
  end
  
  def downcase_attributes    
    self.attributes.each do |k, v|
      
      logger.info "Downcasing attribute (#{k})"
      self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
    end
    true
  end
  
  def as_json extras={}
    extras[:include] ||= {}
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
    super(extras)    
  end
  
end
