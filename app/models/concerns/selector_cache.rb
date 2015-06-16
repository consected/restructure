module SelectorCache
  
  extend ActiveSupport::Concern
  
  ArrayCacheKey = "#{self.to_s}_array".freeze
  ArrayPairCacheKey = "#{self.to_s}_hash".freeze

  include do
    before_create :invalidate_cache
  end
  
  class_methods do
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

    def invalidate_cache
      Rails.cache.delete(ArrayCacheKey)
      Rails.cache.delete(ArrayPairCacheKey)
    end
  end
    
end
