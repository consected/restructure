module ActivityLogHandler

  extend ActiveSupport::Concern

  included do
    belongs_to parent_type
    validates parent_type, presence: true
    
  end

  class_methods do


    def use_with_class_names
      [parent_type.to_s]
    end

    def assoc_inverse
      # The plural model name
      name.gsub('::','_').underscore.pluralize.to_sym      
    end


    def parent_class
      parent_type.to_s.camelize.constantize
    end

    def view_attribute_list
      attribute_names + [parent_type] - ['id', 'master_id', 'disabled',"#{parent_type}_id", 'user_id', 'created_at', 'updated_at', 'rank', 'source']
    end

    def parent_data_names
      parent_class.attribute_names  - ['id', 'master_id', 'disabled', 'user_id', 'created_at', 'updated_at', 'rank', 'source']
    end
  end

  def as_json extras={}
    extras[:include] ||=[]
    extras[:include] << self.class.parent_type
    super(extras)
  end

  def multiple_results
    nil
  end

  def has_multiple_results
    @multiple_results && @multiple_results.length > 0
  end

  def item
    @item ||= send(self.class.parent_type)
  end

  def item_id
    item.id
  end

  def item_id= i
    send("#{self.class.parent_type}_id=",i)
  end



  
end