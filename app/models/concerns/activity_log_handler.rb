module ActivityLogHandler

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to :master, inverse_of: assoc_inverse
    belongs_to parent_type
    has_many :item_flags, as: :item, inverse_of: :item

    after_initialize :set_action_when
#    before_create :set_related_fields_edit
    before_save :set_related_fields
    before_save :set_allow_tracker_sync
    # don't validate the association with the parent item_data
    # blank activity logs do not have one
    # validates parent_type, presence: true

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


    # gets the class names that this activity log model can be used with, from the admin definition
    def use_with_class_names
      ActivityLog.use_with_class_names
    end

    def assoc_inverse
      # The plural model name
      name.ns_underscore.pluralize.to_sym
    end


    def parent_class
      parent_type.to_s.camelize.constantize
    end

    # Find the record in the admin activity log that defines this activity log
    def admin_activity_log
      res = ActivityLog.active.select{|s| s.table_name == self.table_name}
      raise "Found incorrect number (#{res.length}) of admin activity logs for table name #{self.table_name} from possible list of #{ActivityLog.active.length}" if res.length != 1
      res.first
    end

    # List of attributes to be used in common template views
    # Use the defined field_list if it is not blank
    # Otherwise use attribute names from the model, removing common junk
    def view_attribute_list
      al = admin_activity_log
      unless al.field_list.blank?
        res = al.view_attribute_list + ['tracker_history_id']
      else
        res = self.attribute_names - ['id', 'master_id', 'disabled', parent_type ,"#{parent_type}_id", 'user_id', 'created_at', 'updated_at', 'rank', 'source'] + ['tracker_history_id']
      end
      res = res.map(&:to_sym)
      return res
    end

    # List of attributes to be used in blank log template views
    # Use the defined blank_log_field_list if it is not blank
    # Otherwise use the view_attribute_list
    def view_blank_log_attribute_list
      al = admin_activity_log
      if al.blank_log_field_list.blank?
        self.view_attribute_list.clone
      else
        admin_activity_log.view_blank_log_attribute_list.map(&:to_sym)
      end
    end

    # The user relevant data attributes in the parent class
    def parent_data_names
      parent_class.attribute_names  - ['id', 'master_id', 'disabled', 'user_id', 'created_at', 'updated_at', "rank", "rec_type"]
    end

    # Default attribute name for the 'completed when' field
    def action_when_attribute
      :completed_when
    end

    def uses_item_flags?
      ItemFlagName.enabled_for? self.name.ns_underscore
    end

  end

  # default record updates tracking is not performed, since we sync tracker separately
  def no_track
    true
  end


  # these models belong to an item from the perspective of user interaction, rather than master
  # although equally there is a master association
  def belongs_directly_to
    item
  end

  # simple way of getting the item from the actual parent association
  def item
    @item ||= send(self.class.parent_type)
  end

  def item_id
    item.id if item
  end

  # set the association
  def item_id= i
    send("#{self.class.parent_type}_id=",i)
  end

  # set the action_when attribute to the current date time, if it is not already set
  def set_action_when
    if self.action_when.blank?
      self.action_when = DateTime.now
    end
    self.action_when
  end

  # the action_when attribute may vary from one activity log model to another. Get the value
  def action_when
    action = self.class.action_when_attribute
    self.send(action)
  end

  def action_when= d
    action = self.class.action_when_attribute
    self.send("#{action}=", d)
  end


  # Sync the tracker by adding a record to the protocol if it is set
  # This should only happen one time, since in the case of edit / update, a duplicate
  # item could be created otherwise.
  def sync_tracker

    return unless self.respond_to?(:protocol_id) && self.protocol_id

    return unless @allow_tracker_sync

    protocol = Protocol.find(protocol_id)

    # if we are not already passing through sub_process based on a user selection then
    # look up what the Activity name is for protocol sub processes
    unless self.attribute_names.include? 'sub_process_id'
      sub_process = protocol.sub_processes.where(name: ActivityLog::SubProcessName).first
    end
    # if we are not already passing through protocol_event based on a user selection then
    # then use the protocol event name matching the admin activity log definition for this model
    unless self.attribute_names.include? 'protocol_event'
      protocol_event = sub_process.protocol_events.enabled.where(name: self.class.activity_log_name).first
    end

    # be sure about the user being set, to avoid hidden errors
    raise "no user set when syncing tracker" unless self.master.current_user

    t = self.master.trackers.create(protocol_id: protocol_id, sub_process_id: sub_process.id, protocol_event_id: protocol_event.id,
                  item_id: self.id, item_type: self.class.name, event_date: self.action_when)

    # check and raise error that is usable by a user if there was a problem (for example, a required field not set)
    unless t && t.valid?
      raise FphsException.new("could not create tracker record: #{t.errors.full_messages.join('; ')}")
    end
    t
  end


  def fields_to_sync
    self.class.fields_to_sync
  end

  # sync the attributes that are common between the parent item and the new logged item,
  # to ensure that there is a true record of the original data (in case something is changed
  # in the parent item subsequently)
  # Skip this if the item is not set (for a blank activity log)
  def sync_item_data
    return true unless item
    fields_to_sync.each do |f|
      self.send("#{f}=", item.send(f))
    end
    true
  end


  def update_action
    @was_created || @was_updated
  end


  def set_related_fields
    @set_related_fields ||= setup_set_related_fields
  end


  # handle fields that start with set_related_
  # these fields allow a field in a related model to be updated
  # for example, this allows a rank in a phone number to be set when displaying
  # a form for a phone activity log
  # the full field name in this case would be set_related_player_contact_rank
  def setup_set_related_fields

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

        # handle the situation where a blank item is not using the related items
        if relitem

          relitem_field_val = relitem.send(relitem_field)

          curr_val = self.send(field_name)
          # don't set the value if it is already set, since this indicates we have
          # already configured the model
          self.send("#{field_name}=", relitem_field_val) unless curr_val

          srfs[field_name.to_sym] = {
            item: relitem,
            name_and_field: relitem_name_and_field.to_sym,
            field: relitem_field.to_sym,
            value: relitem_field_val
          }
        end

      end
    end
    return srfs
  end



  # set the fields that are marked as set_related in the current model, back
  # into the related model
  def sync_set_related_fields
    return true unless set_related_fields

    set_related_fields.each do |k,s|
      new_val = self.send(k)

      curr_val = s[:item].send(s[:field])

      if curr_val != new_val
        s[:item].send("#{s[:field]}=", new_val)
        s[:item].master = self.master
        res = s[:item].save

        raise "Failed to save related item. #{s[:item].errors.full_messages.join("; ")}" unless res
      end
    end
    return true
  end

  # Store the result of allowing a tracker sync to happen before save, when we
  # would lose access to the required change information.
  def set_allow_tracker_sync
    @allow_tracker_sync = true if !self.persisted? || self.protocol_id_changed?
  end

end
