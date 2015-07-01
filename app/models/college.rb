class College < ActiveRecord::Base

  include SelectorCache
  
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
  
  def self.create_if_new name
    logger.debug "Check if we should add new college to list: #{name}"
    return if exists? name
    logger.info "Adding new college to list: #{name}"
    c = College.new 
    c.name = name
    c.save
  end
  
  
end
