module SelectorCache
  
  extend ActiveSupport::Concern
  

  included do
    
    before_save :invalidate_cache
    before_create :invalidate_cache
    
    scope :enabled, -> { where "disabled is null OR disabled = FALSE" }    
  end
  
  class_methods do
    
    def selector_cache?
      true
    end
    
    def downcase_if_string val
      if val.is_a? String
        val.downcase
      else
        val
      end
    end
    
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
    def nv_all_cache_key 
      "#{self.to_s}_namevalall"
    end
    def attributes_cache_key
      "#{self.to_s}_attributes"      
    end
    
    def selector_array conditions=nil, attribute=:name
      ckey="#{array_cache_key}#{conditions}:#{attribute}"
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect {|c| c.send(attribute) }
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
        enabled.where(conditions).collect {|c| [c.name, downcase_if_string(c.value)] }
      }
    end
    
    def selector_name_value_pair_no_downcase conditions=nil
      ckey="#{nv_pair_cache_key}-nd-#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect {|c| [c.name, c.value] }
      }
    end    
    
    def selector_attributes attributes, conditions=nil
      ckey="#{attributes_cache_key}#{attributes}#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions).collect do |c|
          a = [] 
          attributes.each do |att|
            a << c.send(att)
          end
          a
        end
      }
    end
    
    def selector_collection conditions=nil
      
      ckey="#{collection_cache_key}#{conditions}"
      
      Rails.cache.fetch(ckey){
        enabled.where(conditions)
      }
    end

    def all_name_value_enable_flagged conditions=nil
      ckey="#{nv_all_cache_key}#{conditions}"
      
      Rails.cache.fetch(ckey){
        all.where(conditions).collect {|c| 
          name = ''
          if c.respond_to?(:parent_name)
            v = c.id
            vlabel = "(#{c.parent_name}) "
            name = c.name
          elsif c.respond_to?(:value)             
            v =  c.value
            name = c.name
          else 
            v = c.id     
            name = c.name
          end
          
          if c.respond_to?(:full_label)
            name =  c.full_label              
          end
          
          ["#{vlabel}#{name} #{c.disabled ? '[disabled]' : ''}", downcase_if_string(v)] }.sort
      }
    end
    
    
    def name_for value
      res = selector_name_value_pair.select{|p| p.last == value}    
      res.length == 1 ? res.first.first : nil
    end
    
    
  end

  def invalidate_cache

    logger.info "College added or updated. Invalidating cache."
    # Unfortunately we have no way to clear pattern matched keys with memcached so we just clear the whole cache
    Rails.cache.clear    

  end
end
