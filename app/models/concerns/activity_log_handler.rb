module ActivityLogHandler  

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to parent_type
    
    after_initialize :set_action_when
    before_save :set_related_fields_save

    validates parent_type, presence: true
    
    after_validation :sync_item_data
    after_validation :sync_set_related_fields
    
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

    return if !self.respond_to?(:protocol_id) || !self.respond_to?(:sub_process_id) || protocol_id.blank?

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


  def set_related_fields_edit
    @set_related_fields ||= setup_set_related_fields(false)
  end


  def set_related_fields_save
    @set_related_fields ||= setup_set_related_fields(true)
  end


  # handle fields that start with set_related_
  # these fields allow a field in a related model to be updated
  # for example, this allows a rank in a phone number to be set when displaying
  # a form for a phone activity log
  # the full field name in this case would be set_related_player_contact_rank
  # The saving attribute indicates that the model should not retrieve the related value
  # and prevent storing it in this model's set_related... field, which would overwrite
  # any entries just made by a user
  def setup_set_related_fields saving

    srfs = {}

    self.attribute_names.each do |field_name|
      if field_name.to_s.start_with?('set_related_')
        # get the model name of the related model and its field by
        # getting rid of the set_related_prefix_ then looking for associated model
        # to find one with a matching name
        relitem_field = ''
        relitem_name = ''
        relitem_name_and_field = field_name.to_s.gsub('set_related_', '')
        relitem_list = self.class.reflect_on_all_associations(:belongs_to).map(&:name)

        relitem_list.each do |r|
          if relitem_name_and_field.start_with?(r.to_s)
            relitem_field = relitem_name_and_field.gsub("#{r.to_s}_", '')
            relitem_name = r.to_s
            # remake the model_field name with the pluralized model name, since this is
            # how the field is referred to in normal field naming and general selections
            relitem_name_and_field = "#{relitem_name.pluralize}_#{relitem_field}"
            break
          end
        end

        # get the underlying related item and the value of the field
        relitem = self.send(relitem_name)
        relitem_field_val = relitem.send(relitem_field)

        self.send("#{field_name}=", relitem_field_val) unless saving

        srfs[field_name.to_sym] = {
          item: relitem,
          name_and_field: relitem_name_and_field.to_sym,
          field: relitem_field.to_sym,
          value: relitem_field_val
        }


      end
    end
    return srfs
  end


  def sync_set_related_fields
    return true unless set_related_fields_save
    
    set_related_fields_save.each do |k,s|
      new_val = self.send(k)
      
      curr_val = s[:item].send(s[:field])
      
      if curr_val != new_val
        s[:item].send("#{s[:field]}=", new_val)
        s[:item].master = self.master
        res = s[:item].save

        raise "failed to save related item" unless res
      end
    end
    return true
  end

end