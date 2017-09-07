module ActivityLogHandler  

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to parent_type
    belongs_to :protocol
    after_initialize :set_action_when
    validates parent_type, presence: true
    after_save :check_status
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
      attribute_names - ['id', 'master_id', 'disabled',parent_type ,"#{parent_type}_id", 'user_id', 'created_at', 'updated_at', 'rank', 'source']
    end

    def parent_data_names
      parent_class.attribute_names  - ['id', 'master_id', 'disabled', 'user_id', 'created_at', 'updated_at', "rank", "rec_type"]
    end

    def action_when_attribute
      :completed_when
    end
  end

  def belongs_directly_to
    item
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

  def set_action_when
    action = self.class.action_when_attribute
    if self.send(action).blank?
      self.send("#{action}=", DateTime.now)
    end
  end

  
end