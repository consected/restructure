module ActivityLogHandler

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to :master, inverse_of: assoc_inverse
    # It is necessary to force the class name of the parent, since
    # the association will attempt to use the class within the ActivityLog module otherwise
    # which effectively refers the implementation back to itself
    belongs_to parent_type, class_name: "::#{parent_class.name}"
    has_many :item_flags, as: :item, inverse_of: :item

    after_initialize :set_action_when
    after_initialize :format_sync_fields

    before_save :sync_item_data
    before_save :set_related_fields
    before_save :set_allow_tracker_sync
    # don't validate the association with the parent item_data
    # blank activity logs do not have one
    # validates parent_type, presence: true

    validates :master_id, presence: true

    after_save :sync_set_related_fields

    after_save :sync_tracker

    after_save :check_status
    after_save :track_record_update

    after_commit :check_for_notification_records, on: :create
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
        res = self.view_attribute_list.clone
      else
        res = admin_activity_log.view_blank_log_attribute_list.map(&:to_s) + ['tracker_history_id']
      end
      res.map(&:to_sym)
    end

    # The user relevant data attributes in the parent class
    def parent_data_names
      parent_class.attribute_names  - ['id', 'master_id', 'disabled', 'user_id', 'admin_id', 'created_at', 'updated_at', "rank", "rec_type"]
    end

    # Default attribute name for the 'completed when' field
    def action_when_attribute
      :completed_when
    end

    def uses_item_flags? user
      ItemFlagName.enabled_for? self.name.ns_underscore, user
    end

    def extra_log_type_config_names
      admin_activity_log.extra_log_type_configs.map(&:name)
    end

    def extra_log_type_configs
      admin_activity_log.extra_log_type_configs
    end

    def extra_log_type_config_for name
      extra_log_type_configs.select{|s| s.name.underscore == name.underscore}.first
    end
  end


  def to_s
    data
  end

  def data
    if defined? super
      super()
    else
      "#{self.class.admin_activity_log.name}: #{id}"
    end
  end

  def extra_log_type_config

    elt  = self.extra_log_type
    if elt.blank?
      elt = self.item ? 'primary' : 'blank'
    end
    res = self.class.extra_log_type_config_for elt
    logger.warn "No extra log type configuration exists for #{elt} in #{self.class.name}" unless res
    res
  end

  # default record updates tracking is not performed, since we sync tracker separately
  def no_track
    false
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

  def model_references
    res = []
    return res unless extra_log_type_config && extra_log_type_config.references
    extra_log_type_config.references.each do |ref_type, ref_config|
      f = ref_config['from']
      if f == 'this'
        res += ModelReference.find_references self, to_record_type: ref_type
      elsif f == 'master'
        res += ModelReference.find_references self.master, to_record_type: ref_type
      end
    end
    res
  end

  def creatable_model_references
    res = {}

    return res unless extra_log_type_config && extra_log_type_config.references
    extra_log_type_config.references.each do |ref_type, ref_config|
      a = ref_config['add']
      if a == 'many'
        l = ref_config['limit']
        under_limit = true
        if l && l.is_a?(Integer)
          under_limit = (ModelReference.find_references(self.master, to_record_type: ref_type).length < l)
        end

        res[ref_type] = a if under_limit
      elsif a == 'one_to_master'
        if ModelReference.find_references(self.master, to_record_type: ref_type).length == 0
          res[ref_type] = a
        end
      elsif a == 'one_to_this'
        if ModelReference.find_references(self, to_record_type: ref_type).length == 0
          res[ref_type] = a
        end
      end
    end
    res
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
    if self.attribute_names.include? 'sub_process_id'
      sub_process_id = self.sub_process_id
      sub_process = SubProcess.find(sub_process_id)
    else
      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      sub_process = protocol.sub_processes.where(name: ActivityLog.sub_process_name).first
      sub_process_id = sub_process.id
    end
    # if we are not already passing through protocol_event based on a user selection then
    # then use the protocol event name matching the admin activity log definition for this model
    if self.attribute_names.include? 'protocol_event_id'
      protocol_event_id = self.protocol_event_id
    elsif sub_process
      raise "activity_log_name not set for #{self.class}. Can't get the protocol event without it" unless self.class.activity_log_name
      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      pe = sub_process.protocol_events.where(name: self.class.activity_log_name).first
      if pe
        protocol_event_id = pe.id
      else
        raise "Could not find a protocol event for sub process #{sub_process_id} in sync_tracker (#{self.class}). There are these: #{sub_process.protocol_events.map(&:name).join(', ')}."
      end
    end

    # be sure about the user being set, to avoid hidden errors
    raise "no user set when syncing tracker" unless self.master.current_user

    t = self.master.trackers.create(protocol_id: protocol_id, sub_process_id: sub_process_id, protocol_event_id: protocol_event_id,
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


  def format_sync_fields
    return unless parent_class
    fields_to_sync.each do |f|
      formatter = "format_#{f}"
      if parent_class.respond_to? formatter
        if self.respond_to? :rec_type
          self[f] = parent_class.send("format_#{f}", self[f], self.rec_type)
        else
          self[f] = parent_class.send("format_#{f}", self[f])
        end
      end
    end
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

        if relitem_name.blank?
          raise FphsException.new "The field #{field_name} does not correspond to one of #{relitem_list}"
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

      if !new_val.blank? && curr_val != new_val
        s[:item].send("#{s[:field]}=", new_val)
        # Do not set master - this should already be set, and setting it again breaks
        # secondary_key matched saves
        s[:item].master = self.master unless s[:item].master
        s[:item].master.current_user = self.master_user || self.user unless s[:item].master_user
        res = s[:item].save
        raise "Failed to save related item. #{s[:item].errors.full_messages.join("; ")}" unless res
      end
    end
    return true
  end

  # Store the result of allowing a tracker sync to happen before save, when we
  # would lose access to the required change information.
  def set_allow_tracker_sync
    @allow_tracker_sync = true if !self.persisted? || (self.respond_to?(:protocol_id) && self.protocol_id_changed?)
  end


  def track_record_update
    # Don't do this if we have the configuration set to avoid tracking, or
    # if the record was not created or updated
    return if no_track || !(@was_updated || @was_created)
    @update_action = true
    Tracker.track_record_update self
  end

  def can_edit?

    res = master.current_user.has_access_to? :edit, :activity_log_type, extra_log_type_config.resource_name
    Rails.logger.info "Can not edit activity_log_type #{extra_log_type_config.resource_name} due to lack of access" unless res
    return unless res

    latest_item = master.send(self.class.assoc_inverse).unscope(:order).order(id: :desc).limit(1).first

    res = (self.user_id == master.current_user.id && latest_item.id == self.id)

    res && super()
  end

  def can_create?

    res = master.current_user.has_access_to? :create, :activity_log_type, extra_log_type_config.resource_name

    Rails.logger.info "Can not create activity_log_type #{extra_log_type_config.resource_name} due to lack of access" unless res

    res && super()
  end

  def can_access?

    res = master.current_user.has_access_to? :access, :activity_log_type, extra_log_type_config.resource_name

    Rails.logger.info "Can not access activity_log_type #{extra_log_type_config.resource_name} due to lack of access" unless res

    res && super()
  end

  # Extend the standard access check with a check on the extra_log_type resource
  def allows_current_user_access_to? perform, with_options=nil
    raise FphsException.new "no master.current_user in activity_log_handler allows_current_user_access_to?" unless master.current_user
    if extra_log_type_config && extra_log_type_config.resource_name
      res = master.current_user.has_access_to? perform, :activity_log_type, extra_log_type_config.resource_name
    end
    res && super(perform, with_options)
  end

  # An app specific DB trigger may have have created a message notification record.
  # Check for new records, and work from there.
  def check_for_notification_records
    MessageNotification.handle_notification_records self
  end

end
