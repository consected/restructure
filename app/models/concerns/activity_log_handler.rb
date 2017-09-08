module ActivityLogHandler  

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to parent_type

    after_initialize :set_action_when
    validates parent_type, presence: true
    after_validation :sync_tracker
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

  def sync_tracker

    return if protocol_id.blank? || sub_process_id.blank?

    m = master if respond_to? :master
    m ||= item.master if item.respond_to? :master

    t = m.trackers.build(protocol_id: protocol_id, sub_process_id: sub_process_id, protocol_event_id: protocol_event_id,
                  item_id: item_id, item_type: item.class.name, event_date: called_when)
    t.save!

    self.tracker_id = t.id  if respond_to? :tracker

  end


  def update_action
    @was_created || @was_updated
  end
end