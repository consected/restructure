module SelectorCache
  
  extend ActiveSupport::Concern
  

  included do
    
    before_save :invalidate_cache
    before_create :invalidate_cache
    
    scope :enabled, -> { where "disabled is null OR disabled = FALSE" }
  end
  
  class_methods do
    
    def gen_cache_key
      self.to_s
    end
    
    def array_cache_key 
      logger.debug "Getting #{self.to_s} array cache key"
      "#{self.to_s}_array"      
    end
    def array_pair_cache_key 
      "#{self.to_s}_hash"
    end
    def collection_cache_key
      logger.debug "Getting #{self.to_s} collection cache key"
      "#{self.to_s}_collection"
    end
    def nv_pair_cache_key 
      "#{self.to_s}_nameval"
    end
    def attributes_cache_key
      "#{self.to_s}_attributes"      
    end
    
    def selector_array conditions=nil
      ckey="#{array_cache_key}#{conditions}"
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect {|c| c.name }
      }    
    end
    
    def selector_array_pair conditions=nil
      ckey="#{array_pair_cache_key}#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect {|c| [c.name, c.id] }
      }
    end
    
    def selector_name_value_pair conditions=nil
      ckey="#{nv_pair_cache_key}#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect {|c| [c.name, c.value] }
      }
    end
    
    def selector_attributes attributes, conditions=nil
      ckey="#{attributes_cache_key}#{attributes}#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect {|c| [c.send(attributes.first), c.send(attributes.last)] }
      }
    end
    
    def selector_collection conditions=nil
      
      ckey="#{collection_cache_key}#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions)
      }
    end
    

  end

  def invalidate_cache

    logger.info "College added or updated. Invalidating cache."
    # Unfortunately we have no way to clear pattern matched keys with memcached so we just clear the whole cache
    Rails.cache.clear

  end
end
