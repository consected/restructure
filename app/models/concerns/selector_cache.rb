module SelectorCache
  
  extend ActiveSupport::Concern
  

  include do
    
    before_save :invalidate_cache
    
  end
  
  class_methods do
    
    ArrayCacheKey = "#{self.to_s}_array".freeze
    ArrayPairCacheKey = "#{self.to_s}_hash".freeze
    CollectionCacheKey = "#{self.to_s}_collection".freeze
    NameValuePairCacheKey = "#{self.to_s}_nameval".freeze
    
    def selector_array conditions=nil
      ckey="#{ArrayCacheKey}#{conditions}"
      Rails.cache.fetch(ckey){
        where(conditions).collect {|c| c.name }
      }    
    end
    
    def selector_array_pair conditions=nil
      ckey="#{ArrayPairCacheKey}#{conditions}"
      
      Rails.cache.fetch(ckey){
        where(conditions).collect {|c| [c.name, c.id] }
      }
    end
    
    def selector_name_value_pair conditions=nil
      ckey="#{NameValuePairCacheKey}#{conditions}"
      
      Rails.cache.fetch(ckey){
        where(conditions).collect {|c| [c.name, c.value] }
      }
    end
    
    def selector_collection conditions=nil
      
      ckey="#{CollectionCacheKey}#{conditions}"
      
      Rails.cache.fetch(ckey){
        where(conditions)
      }
    end
    
    def invalidate_cache
      Rails.cache.delete(ArrayCacheKey)
      Rails.cache.delete(ArrayPairCacheKey)
      Rails.cache.delete(CollectionCacheKey)
    end
  end
    
end
