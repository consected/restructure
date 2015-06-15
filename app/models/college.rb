class College < ActiveRecord::Base

  CacheKey = "college_array-2".freeze
  
  def self.array
    Rails.cache.fetch(CacheKey){
      College.all.collect {|c| c.name }
    }    
  end
  
  def self.add name
    College.create name: name
    Rails.cache.delete(CacheKey)
  end
  
  
end
