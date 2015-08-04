class College < ActiveRecord::Base

  include AdminHandler
  include SelectorCache
  belongs_to :user
  
  default_scope -> {order  "colleges.updated_at DESC nulls last"}
  validates :name, presence: true, uniqueness: true
  before_validation :prevent_name_change,  on: :update
  before_validation :check_synonym
  
  def self.all
    Rails.cache.fetch gen_cache_key do
      super
    end
  end
  
  def self.exists? name
    res = all.exists? name: name    
    logger.debug "College #{name} exists? #{res}"
    res
  end
  
  def self.create_if_new name, user
    logger.debug "Check if we should add new college to list: #{name}"
    return if exists? name
    logger.info "Adding new college to list: #{name}"
    c = College.new 
    c.name = name
    c.user = user
    c.save
    c
  end
  
  def user_name
    return nil unless user
    user.email
  end
  
  def synonym_for_name
    return nil unless synonym_for_id
    c = College.find_by_id(synonym_for_id)
    return nil unless c
    c.name
    
  end
  

  private
  
    def prevent_name_change 
      if name_changed? && self.persisted?
        errors.add(:name, "change not allowed!")
      end
    end

    def ensure_admin_set
      # Override the standard test for admin being set, since users can create (but not update) colleges
      errors.add(:admin, "has not been set") unless !self.persisted? || admin_set?
    end
    
    
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
end
