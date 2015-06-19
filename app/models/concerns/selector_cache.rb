module SelectorCache
  
  extend ActiveSupport::Concern
  

  include do
    
    before_save :invalidate_cache
    
  end
  
  class_methods do
    
    ArrayCacheKey = "#{self.to_s}_array".freeze
    ArrayPairCacheKey = "#{self.to_s}_hash".freeze
    CollectionCacheKey = "#{self.to_s}_collection".freeze
    
    def selector_array
      Rails.cache.fetch(ArrayCacheKey){
        all.collect {|c| c.name }
      }    
    end
    
    def selector_array_pair
      Rails.cache.fetch(ArrayPairCacheKey){
        all.collect {|c| [c.name, c.id] }
      }
    end
    
    def selector_collection
      Rails.cache.fetch(CollectionCacheKey){
        all
      }
    end
    
    def invalidate_cache
      Rails.cache.delete(ArrayCacheKey)
      Rails.cache.delete(ArrayPairCacheKey)
      Rails.cache.delete(CollectionCacheKey)
    end
  end
    
end
