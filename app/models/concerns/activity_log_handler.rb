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

    # Ensure that referenced items have also saved
    after_commit :handle_save_triggers

    attr_writer :alt_order
    attr_accessor :action_name
    # after_commit :check_for_notification_records, on: :create
  end

  class_methods do

    def is_activity_log
      true
    end

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



    # # Find the record in the admin activity log that defines this activity log
    # def admin_activity_log
    #   res = ActivityLog.active.select{|s| s.table_name == self.table_name}
    #   raise "Found incorrect number (#{res.length}) of admin activity logs for table name #{self.table_name} from possible list of #{ActivityLog.active.length}" if res.length != 1
    #   res.first
    # end

    # List of attributes to be used in common template views
    # Use the defined field_list if it is not blank
    # Otherwise use attribute names from the model, removing common junk
    def view_attribute_list
      al = self.definition
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
      al = self.definition
      if al.blank_log_field_list.blank?
        res = self.view_attribute_list.clone
      else
        res = self.definition.view_blank_log_attribute_list.map(&:to_s) + ['tracker_history_id']
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
      Classification::ItemFlagName.enabled_for? self.name.ns_underscore, user
    end

    def extra_log_type_config_names
      self.definition.extra_log_type_configs.map(&:name)
    end

    def extra_log_type_configs
      self.definition.extra_log_type_configs
    end

    # Select the extra log type configuration by name, or use the first item if nothing matches
    # The default allows viewing of data in the case that a configuration has changed and removed an item
    # that an extra_log_type field value still refers to
    def extra_log_type_config_for name
      extra_log_type_configs.select{|s| s.name == name.to_s.underscore.to_sym}.first || extra_log_type_configs.first
    end

    def human_name_for extra_log_type
      extra_log_type.to_s.humanize
    end
  end


  def human_name
    return extra_log_type_config.label if extra_log_type_config.label.present?
    return extra_log_type.to_s.humanize
  end


  def to_s
    data
  end


  def alt_order

    if self.extra_log_type_config && self.extra_log_type_config.view_options
      da = self.extra_log_type_config.view_options[:alt_order]
      da = [da] unless da.is_a? Array
      res = ''
      # collect potential date / time pairs from adjacent fields
      dtp = nil
      da.each do |n|
        v = self.attributes[n]
        if v.is_a? Date
          # Set the date portion of the date / time pair, but don't store it yet
          dtp =  DateTime.new(v.year, v.month, v.day, 0, 0, 0, v.send(:zone))
        elsif v.is_a? Time
          if dtp
            # A date portion of a date / time pair is present, so add the time and store to the result
            res =  DateTime.new(dtp.year, dtp.month, dtp.day, v.hour, v.min, 0, v.send(:zone))
            # Clear the date / time pair now we are done with it
            dtp = nil
          else
            # Since no date portion was already available, just store the time (this is based on 2001-01-01 date)
            res += "#{v.to_i}"
          end
        else
          # If a date / time pair is set, but was not yet stored, then a date portion was provided, but no time.
          # Store that date to the result from the previous iteration, before storing the value for the current attribute.
          # Remember to clear the date / time pair after storing
          res += dtp.to_s if dtp
          dtp = nil
          res += v if v
        end
      end

      return res
    end
  end

  def data
    if defined? super
      super()
    else
      if self.extra_log_type_config && self.extra_log_type_config.view_options
        da = self.extra_log_type_config.view_options[:data_attribute]
      end

      if da
        return self.class.format_data_attribute da, self
      else
        n = extra_log_type_config.label || extra_log_type.to_s.humanize
        return "#{n}"
      end
    end
  end


  def no_master_association
    false
  end

  def extra_log_type
    elt  = super()
    if elt.blank?
      elt = self.item ? :primary : :blank_log
    end

    elt.to_sym
  end

  def option_type
    extra_log_type
  end

  def option_type_config
    extra_log_type_config
  end


  def extra_log_type_config

    elt  = self.extra_log_type

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

  # action_when represents the date or timestamp attribute that is used to order results
  # Often this will be the created_at attribute value, although it may represent an alternative value
  # the action_when attribute may vary from one activity log model to another. Get the value
  def action_when
    action = self.class.action_when_attribute
    res = self.send(action)
    res
  end

  def action_when= d
    action = self.class.action_when_attribute
    self.send("#{action}=", d)
  end

  def save_action
    extra_log_type_config.calc_save_action_if self
  end

  # List of activity log types that can be created or not, based on user access controls and creatable_if rules
  def creatables

    current_user = master.current_user
    implementation_class = self.class
    res = {}

    # Make a creatable actions, based on standard user access controls and extra log type creatable_if rules
    implementation_class.extra_log_type_configs.each do |c|
      result = current_user.has_access_to?(:create, :activity_log_type, c.resource_name) && c.calc_creatable_if(self)
      res[c.name] = result ? c.resource_name : nil
    end

    res
  end

  def model_references reference_type: :references, active_only: false
    res = []
    if reference_type == :references
      refs = extra_log_type_config.references
    elsif reference_type == :e_sign
      refs = extra_log_type_config.e_sign && extra_log_type_config.e_sign[:document_reference]
    end

    return res unless extra_log_type_config && refs
    refs.each do |ref_key, refitem|
      refitem.each do |ref_type, ref_config|
        f = ref_config[:from]
        if f == 'this'
          got = ModelReference.find_references self, to_record_type: ref_type, filter_by: ref_config[:filter_by]
        elsif f == 'master'
          got = ModelReference.find_references self.master, to_record_type: ref_type, filter_by: ref_config[:filter_by]
        elsif f == 'any'
          got = ModelReference.find_references self.master, to_record_type: ref_type, filter_by: ref_config[:filter_by], without_reference: true
        else
          got = nil
        end

        if got
          got = got.select {|r| !r.disabled} if active_only
          res += got
        end
      end
    end
    res
  end

  def creatable_model_references only_creatables: false
    cre_res = {}
    return cre_res unless extra_log_type_config && extra_log_type_config.references
    extra_log_type_config.references.each do |ref_key, refitem|
      refitem.each do |ref_type, ref_config|

        res = {}
        ires = nil
        ci_res = true
        # Check if creatable_if has been defined on the reference configuration
        # and if it evaluates to true

        ci_res = extra_log_type_config.calc_reference_creatable_if ref_config, self
        fb = ref_config[:filter_by]

        if ci_res
          a = ref_config[:add]
          if a == 'many'
            l = ref_config[:limit]
            under_limit = true

            if l && l.is_a?(Integer)
              under_limit = (ModelReference.find_references(self.master, to_record_type: ref_type, filter_by: fb, active: true).length < l)
            end

            ires = a if under_limit
          elsif a == 'one_to_master'
            if ModelReference.find_references(self.master, to_record_type: ref_type, filter_by: fb, active: true).length == 0
              ires = a
            end
          elsif a == 'one_to_this'
            if ModelReference.find_references(self, to_record_type: ref_type, filter_by: fb, active: true).length == 0
              ires = a
            end
          elsif a.present?
            raise FphsException.new "Unknown add type for creatable_model_references: #{a}"
          end

          if ires
            # Check if the user has access to create the item

            mrc = ModelReference.to_record_class_for_type(ref_type)
            raise FphsException.new "Reference type is invalid: #{ref_type}" if mrc.nil?
            if mrc.parent == ActivityLog
              elt = ref_config[:add_with] && ref_config[:add_with][:extra_log_type]
              o = mrc.new(extra_log_type: elt, master: master)
            else
              attrs = {}

              unless mrc.no_master_association
                attrs[:master] = master
              else
                attrs[:current_user] = self.master_user
              end
              o = mrc.new attrs
            end



            i = o.allows_current_user_access_to? :create
            res = {ref_type: ref_type, many: ires, ref_config: ref_config}  if ires && i

          end

        end

        if res[:ref_type] || !only_creatables
          cre_res[ref_key] = {ref_type => res}
        end
      end
    end
    cre_res
  end

  # Use a provided creatable model reference to make a new item
  # Initialize attributes with any filter_by configurations, to ensure the
  # item is set up correctly to be picked up again later
  def build_model_reference creatable_model_ref, optional_params: {}

    cmrdef = creatable_model_ref.last.first.last
    cmrdef.with_indifferent_access

    ref_config = cmrdef[:ref_config].with_indifferent_access

    # Ensure that the filter_by attributes are used to generate the referenced item,
    # otherwise the filter will not work correctly after creation (since the fields won't be set)
    # Also include additional add_with items if provided
    fb = ref_config[:filter_by] || {}
    aw = ref_config[:add_with] || {}
    tot = fb.merge(aw)

    optional_params.merge!(tot)

    cmrdef[:ref_type].ns_camelize.constantize.new optional_params

  end

  # Sync the tracker by adding a record to the protocol if it is set
  # This should only happen one time, since in the case of edit / update, a duplicate
  # item could be created otherwise.
  def sync_tracker

    return unless self.respond_to?(:protocol_id) && self.protocol_id

    return unless @allow_tracker_sync

    protocol = Classification::Protocol.find(protocol_id)

    # if we are not already passing through sub_process based on a user selection then
    # look up what the Activity name is for protocol sub processes
    if self.attribute_names.include? 'sub_process_id'
      sub_process_id = self.sub_process_id
      sub_process = Classification::SubProcess.find(sub_process_id)
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
    # First, check if the user can actually access this type of activity log to edit it
    res = master.current_user.has_access_to? :edit, :activity_log_type, extra_log_type_config.resource_name
    unless res
      Rails.logger.info "Can not edit activity_log_type #{extra_log_type_config.resource_name} due to lack of access"
      return
    end

    # either use the editable_if configuration if there is one,
    # or only allow the latest item to be used otherwise
    eltc = self.extra_log_type_config

    if eltc.editable_if.is_a?(Hash) && eltc.editable_if.first

      # Generate an old version of the object prior to changes
      old_obj = self.dup
      self.changes.each do |k,v|
        if k.to_s != 'user_id'
          old_obj.send("#{k}=", v.first)
        end
      end

      # Ensure the duplicate old_obj references the real master, ensuring current user can
      # be referenced correctly in conditional calculations
      old_obj.master = self.master

      res = eltc.calc_editable_if(old_obj)
      unless res
        Rails.logger.info "Can not edit activity_log_type #{extra_log_type_config.resource_name} due to editable_if calculation"
        return
      end
    else
      @latest_item ||= master.send(self.class.assoc_inverse).unscope(:order).order(id: :desc).limit(1).first
      res = (self.user_id == master.current_user.id && @latest_item.id == self.id)
      unless res
        Rails.logger.info "Can not edit activity_log_type #{extra_log_type_config.resource_name} since it has been overridden by a later item"
        return
      end
    end

    # Finally continue with the standard checks if none of the previous have failed
    super()
  end

  # @return [Boolean | nil] returns true or false based on the result of a conditional calculation,
  #    or nil if there is no `add_reference_if` configuration
  def can_add_reference?
    eltc = self.extra_log_type_config
    if eltc.add_reference_if.is_a?(Hash) && eltc.add_reference_if.first
      res = eltc.calc_add_reference_if(self)
      return !!res
    end
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

  def current_user
    master.current_user
  end

  def current_user= cu
    master.current_user = cu
  end

  # An app specific DB trigger may have have created a message notification record.
  # Check for new records, and work from there.
  def check_for_notification_records
    Messaging::MessageNotification.handle_notification_records self
  end


  def handle_save_triggers
    self.extra_log_type_config.calc_save_trigger_if self
    true
  end

  # Get the container referenced from this activity log
  # @return [NfsStore::Manage::Container | nil]
  def container
    mr = self.model_references.select {|mra| mra.to_record_type == "NfsStore::Manage::Container"}.first
    return unless mr
    mr.to_record
  end

  # A referring record is either set based on the the specific record that the controller say is being viewed
  # when an action is performed, or
  # if there is only one model reference we use that instead.
  def referring_record
    return @referring_record if @referring_record

    res = self.referenced_from
    @referring_record = res.first&.from_record
    return @referring_record if @referring_record && res.length == 1
    nil
  end


  def embedded_item

    return @embedded_item if @embedded_item

    action_name = self.action_name || 'index'

    oi = self

    not_embedded_options = ['not_embedded', 'select_or_add']

    mrs = oi.model_references

    cmrs = oi.creatable_model_references only_creatables: true

    always_embed_reference = oi.extra_log_type_config.view_options[:always_embed_reference]
    always_embed_creatable = oi.extra_log_type_config.view_options[:always_embed_creatable_reference]

    always_embed_item = mrs.select{|m| m.to_record_type == always_embed_reference.ns_camelize}.first if always_embed_reference

    if always_embed_item
      # Always embed if instructed to do so by the options config
      @embedded_item = always_embed_item.to_record
    end

    if always_embed_item && @embedded_item
      # Do nothing
    elsif action_name.in?(['new', 'create']) && always_embed_creatable
      # If creatable has been specified as always embedded, use this, unless the embeddable item is an activity log.
      cmr_view_as = cmrs.first.last.first.last[:ref_config][:view_as] rescue nil
      @embedded_item = oi.build_model_reference [always_embed_creatable.to_sym, cmrs[always_embed_creatable.to_sym]]
      @embedded_item = nil if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
    elsif action_name.in?(['new', 'create']) && cmrs.length == 1
      # If exactly one item is creatable, use this, unless the embeddable item is an activity log.
      cmr_view_as = cmrs.first.last.first.last[:ref_config][:view_as] rescue nil
      @embedded_item = oi.build_model_reference cmrs.first
      @embedded_item = nil if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
    elsif action_name.in?( ['new', 'create']) && cmrs.length > 1
      # If more than one item is creatable, don't use it
      @embedded_item = nil
    elsif action_name.in?( ['new', 'create']) && cmrs.length == 0 && mrs.length == 1
      # Nothing is creatable, but one has been created. Use the existing one.
      @embedded_item = mrs.first.to_record
    elsif action_name.in?(['edit', 'update', 'show', 'index']) && mrs.length == 0
      # If nothing has been embedded, there is nothing to show
      @embedded_item = nil
    elsif action_name.in?(['edit', 'update']) && mrs.length == 1
      # A referenced record exists - the form expects this to be embedded
      # Therefore just use this existing item
      @embedded_item = mrs.first.to_record
      mr_view_as = mrs.first.to_record_options_config[:view_as] rescue nil
      @embedded_item = nil if mr_view_as && mr_view_as[:edit].in?(not_embedded_options)

    elsif action_name.in?(['show', 'index']) && mrs.length == 1 && cmrs.length == 0
      # A referenced record exists and no more are creatable
      # Therefore just use this existing item
      @embedded_item = mrs.first.to_record

    end

    if @embedded_item
      if @embedded_item.class.no_master_association
        @embedded_item.current_user ||= oi.master_user
      else
        @embedded_item.master ||= oi.master
        @embedded_item.master.current_user ||= oi.master_user
      end
    end

    @embedded_item

  end

end
