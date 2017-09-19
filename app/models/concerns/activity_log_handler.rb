module ActivityLogHandler  

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to parent_type
    
    after_initialize :set_action_when
    validates parent_type, presence: true
    
    after_validation :sync_item_data
    after_save :sync_tracker

    after_save :check_status
  end

  class_methods do

    # get the attributes that are common between the parent item and the new logged item
    def fields_to_sync
      self.attribute_names & parent_class.attribute_names - ["id", "master_id", "user_id", "created_at", "updated_at", "item_id"]
    end


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
      attribute_names - ['id', 'master_id', 'disabled',parent_type ,"#{parent_type}_id", 'user_id', 'created_at', 'updated_at', 'rank', 'source'] + ['tracker_history_id']
    end

    def parent_data_names
      parent_class.attribute_names  - ['id', 'master_id', 'disabled', 'user_id', 'created_at', 'updated_at', "rank", "rec_type"]
    end

    def action_when_attribute
      :completed_when
    end
  end

  def no_track
    true
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
    if self.action_when.blank?
      self.action_when = DateTime.now
    end
    self.action_when
  end

  def action_when
    action = self.class.action_when_attribute
    self.send(action)
  end

  def action_when= d
    action = self.class.action_when_attribute
    self.send("#{action}=", d)
  end

  def sync_tracker

    return if protocol_id.blank? 

    raise "no user set when syncing tracker" unless self.master.current_user

    t = self.master.trackers.create(protocol_id: protocol_id, sub_process_id: sub_process_id, protocol_event_id: protocol_event_id,
                  item_id: self.id, item_type: self.class.name, event_date: self.action_when)
    
    unless t && t.valid?
      raise FphsException.new("could not create tracker record: #{t.errors.full_messages.join('; ')}")
    end
    t
  end

  def tracker_history
    TrackerHistory.where(item_id: self.id, item_type: self.class.name).order(id: :desc).first
  end

  def tracker_history_id
    th = tracker_history

    #raise "tracker_history record not found" unless th && th.id
    return unless th && th.id
    th.id

  end

  def fields_to_sync
    self.class.fields_to_sync
  end

  # sync the attributes that are common between the parent item and the new logged item,
  # to ensure that there is a true record of the original data (in case something is changed
  # in the parent item subsequently)
  def sync_item_data

    fields_to_sync.each do |f|
      self.send("#{f}=", item.send(f))
    end
    true
  end


  def update_action
    @was_created || @was_updated
  end
end