class College < ActiveRecord::Base

  include AdminHandler
  include SelectorCache
  belongs_to :user
  
  default_scope -> {order  "colleges.updated_at DESC nulls last"}
  
  before_validation :downcase_name
  before_validation :prevent_name_change,  on: :update
  before_validation :check_synonym
  before_validation :either_admin_or_user, on: :create
  validates :name, presence: true, uniqueness: true
  
  # Override standard #all method to pull from cache if available
  def self.all
    Rails.cache.fetch gen_cache_key do
      super      
    end
  end
  
  # Check if the college with 'name' exists. If so, return truthy value
  def self.exists? name
    res = all.exists? name: name.downcase    
    res
  end
  
  # Create a new named college (working as the specified user) if the college does not exist already
  def self.create_if_new name, user    
    return if exists? name
    logger.info "Adding new college to list: #{name}"
    c = College.new 
    c.name = name.downcase
    c.current_user = user
    c.save!
    c
  end
  
  # Required to get user email address for admin view of who created the college record
  def user_name
    return nil unless user
    user.email
  end
  
  def current_user= new_user    
    raise "bad user set" unless new_user.is_a? User
    @user_set = true 
    self.user = new_user
  end
  
  def user_set?
    return nil unless defined? @user_set
    !!@user_set
  end
  
  # Lookup the name of the record this is a synonym for
  def synonym_name
    return nil unless synonym_for_id
    c = College.find_by_id(synonym_for_id)
    return nil unless c
    c.name
    
  end
  

  protected
  
    def prevent_name_change
        errors.add(:name, "change not allowed!") if name_changed? && self.persisted? && !admin_set?      
    end

    def ensure_admin_set
      # Override the standard test for admin being set, since users can create (but not update) colleges
      errors.add(:admin, "has not been set") if self.persisted? && !admin_set?
    end
    
    
    #Validate that the college this record is being set as a synonym for actually exists
    def check_synonym
      if synonym_for_id 
        sc = College.find_by_id(synonym_for_id)
        if !sc || sc.disabled
          errors.add :synonym, "does not exist as a college already"
          return false
        end
      end
      
      true
    end
    
    def either_admin_or_user
      errors.add(:user, "has not been set when not acting as admin") unless user_set? || admin_set?
    end
    
    def downcase_name
      return unless self.name
      self.name = self.name.downcase
    end
end
