# frozen_string_literal: true

module ActivityLogHandler
  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    belongs_to :master, inverse_of: assoc_inverse
    # It is necessary to force the class name of the parent, since
    # the association will attempt to use the class within the ActivityLog module otherwise
    # which effectively refers the implementation back to itself
    belongs_to parent_type, class_name: "::#{parent_class.name}", optional: true
    has_many :item_flags, as: :item, inverse_of: :item

    after_initialize :set_action_when
    after_initialize :format_sync_fields

    # Ensure that referenced items have also saved
    before_save :handle_before_save_triggers

    before_save :sync_item_data
    before_save :set_related_fields
    before_save :set_allow_tracker_sync
    # don't validate the association with the parent item_data
    # blank activity logs do not have one
    # validates parent_type, presence: true

    validates :master_id, presence: true

    after_save :sync_set_related_fields

    after_save :sync_tracker

    # Ensure that referenced items have also saved
    after_commit :handle_save_triggers

    attr_writer :alt_order
    attr_accessor :action_name
    # after_commit :check_for_notification_records, on: :create
  end

  class_methods do
    def final_setup
      Rails.logger.debug "Running final setup for #{name}"
      default_scope -> { order id: :desc }
    end

    def is_activity_log
      true
    end

    # get the attributes that are common between the parent item and the new logged item
    def fields_to_sync
      attribute_names & parent_class.attribute_names - %w[id master_id user_id created_at updated_at item_id]
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
      al = definition
      if al.field_list.blank?
        res = attribute_names - ['id', 'master_id', 'disabled', parent_type, "#{parent_type}_id", 'user_id', 'created_at', 'updated_at', 'rank', 'source'] + ['tracker_history_id']
      else
        res = al.view_attribute_list + ['tracker_history_id']
      end
      res = res.map(&:to_sym)
      res
    end

    # List of attributes to be used in blank log template views
    # Use the defined blank_log_field_list if it is not blank
    # Otherwise use the view_attribute_list
    def view_blank_log_attribute_list
      al = definition
      res = if al.blank_log_field_list.blank?
              view_attribute_list.clone
            else
              definition.view_blank_log_attribute_list.map(&:to_s) + ['tracker_history_id']
            end
      res.map(&:to_sym)
    end

    # resource_name used by user access controls
    # This is the resource name for the total process
    # The method #resource_name represents the resource_name for the extra_log_type
    def resource_name
      definition.resource_name
    end

    # The user relevant data attributes in the parent class
    def parent_data_names
      parent_class.attribute_names - %w[id master_id disabled user_id admin_id created_at updated_at rank rec_type]
    end

    # Default attribute name for the 'completed when' field
    def action_when_attribute
      :completed_when
    end

    def uses_item_flags?(user)
      Classification::ItemFlagName.enabled_for? name.ns_underscore, user
    end

    def human_name_for(extra_log_type)
      extra_log_type.to_s.humanize
    end

    def parent_type
      @parent_type = definition.item_type.to_sym
    end

    def parent_rec_type
      @parent_rec_type = definition.rec_type.to_sym
    end

    def action_when_attribute
      @action_when_attribute = definition.action_when_attribute.to_sym
    end

    def activity_log_name
      @activity_log_name = definition.name
    end

    def permitted_params
      fts = fields_to_sync.map(&:to_sym)
      attribute_names.map(&:to_sym) - [:disabled, :user_id, :created_at, :updated_at, "#{parent_type}_id".to_sym, parent_type, :tracker_id] + [:item_id] - fts
    end
  end

  def model_data_type
    :activity_log
  end

  # resource_name used by user access controls
  # This method represents the resource_name for the extra_log_type
  # The resource name for the total process is the class method {resource_name}
  def resource_name
    extra_log_type_config.resource_name
  end

  def human_name
    return extra_log_type_config.label if extra_log_type_config.label.present?

    extra_log_type.to_s.humanize
  end

  def to_s
    data
  end

  def alt_order
    if extra_log_type_config&.view_options
      da = extra_log_type_config.view_options[:alt_order]
      da = [da] unless da.is_a? Array
      res = ''
      # collect potential date / time pairs from adjacent fields
      dtp = nil
      da.each do |n|
        v = attributes[n]
        if v.is_a? Date
          # Set the date portion of the date / time pair, but don't store it yet
          dtp = DateTime.new(v.year, v.month, v.day, 0, 0, 0, Time.current.send(:zone))
        elsif v.is_a? Time
          if dtp
            # A date portion of a date / time pair is present, so add the time and store to the result
            res = DateTime.new(dtp.year, dtp.month, dtp.day, v.hour, v.min, 0, v.send(:zone))
            # Clear the date / time pair now we are done with it
            dtp = nil
          else
            # Since no date portion was already available, just store the time (this is based on 2001-01-01 date)
            res += v.to_i.to_s
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

      res
    end
  end

  def no_master_association
    false
  end

  #
  # Override the standard extra_log_type attribute to handle
  # primary and blank activity log types.
  # Since this form of activity log definition is not recommended
  # this override should eventually be deprecated
  # @return [Symbol] extra log type name
  def extra_log_type
    elt = super()
    if elt.blank?
      elt = item ? :primary : :blank_log
    end

    elt.to_sym
  end

  def option_type
    extra_log_type
  end

  def extra_log_type_config
    option_type_config
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
    item&.id
  end

  # set the association
  def item_id=(i)
    send("#{self.class.parent_type}_id=", i)
  end

  # set the action_when attribute to the current date time, if it is not already set
  def set_action_when
    self.action_when = DateTime.now if action_when.blank?
    action_when
  end

  # action_when represents the date or timestamp attribute that is used to order results
  # Often this will be the created_at attribute value, although it may represent an alternative value
  # the action_when attribute may vary from one activity log model to another. Get the value
  def action_when
    action = self.class.action_when_attribute
    res = send(action)
    res
  end

  def action_when=(d)
    action = self.class.action_when_attribute
    send("#{action}=", d)
  end

  def save_action
    extra_log_type_config.calc_save_action_if self
  end

  # List of activity log types that can be created or not, based on user access controls and creatable_if rules
  def creatables
    current_user = master.current_user
    def_class = current_definition
    res = {}

    # Make a creatable actions, based on standard user access controls and extra log type creatable_if rules
    def_class.option_configs.each do |c|
      result = current_user.has_access_to?(:create, :activity_log_type, c.resource_name) && c.calc_creatable_if(self)
      res[c.name] = result ? c.resource_name : nil
    end

    res
  end

  def reset_model_references
    @model_references = {}
  end

  # Get model references of the current instance
  # NOTE: only model references specified in the references configuration will be returned,
  # independent of the entries in the model_references table. If you do not get back the results
  # you expect, check the references definition to ensure it includes the appropriate
  # add_with and filter_by entries.
  def model_references(reference_type: :references, active_only: false, ref_order: nil)
    mr_key = { reference_type: reference_type, active_only: active_only, ref_order: ref_order }
    @model_references ||= {}
    return @model_references[mr_key] unless @model_references[mr_key].nil?

    res = []
    if reference_type == :references
      refs = extra_log_type_config.references
    elsif reference_type == :e_sign
      refs = extra_log_type_config.e_sign && extra_log_type_config.e_sign[:document_reference]
    end
    @model_references[mr_key] = res

    return res unless extra_log_type_config && refs

    refs.each do |_ref_key, refitem|
      refitem.each do |ref_type, ref_config|
        f = ref_config[:from]
        without_reference = (ref_config[:without_reference] == true)
        got = if f == 'this'
                ModelReference.find_references self,
                                               to_record_type: ref_type,
                                               filter_by: ref_config[:filter_by],
                                               without_reference: without_reference,
                                               ref_order: ref_order,
                                               active: active_only
              elsif f == 'master'
                ModelReference.find_references master,
                                               to_record_type: ref_type,
                                               filter_by: ref_config[:filter_by],
                                               without_reference: without_reference,
                                               ref_order: ref_order,
                                               active: active_only
              elsif f == 'any'
                ModelReference.find_references master,
                                               to_record_type: ref_type,
                                               filter_by: ref_config[:filter_by],
                                               without_reference: true,
                                               ref_order: ref_order,
                                               active: active_only
              else
                Rails.logger.warn "Find references attempted without known :from key: #{f}"
                raise FphsException, "Find references attempted without known :from key: #{f}" if Rails.env.development?

                nil
              end

        next unless got

        res += got
      end
    end
    @model_references[mr_key] = res
  end

  def creatable_model_references(only_creatables: false)
    # Check for a memoized result
    memokey = "only_creatables_#{only_creatables}"
    if @creatable_model_references
      memores = @creatable_model_references[memokey]
      return memores if memores
    else
      @creatable_model_references = {}
    end

    cre_res = {}
    return cre_res unless extra_log_type_config&.references

    extra_log_type_config.references.each do |ref_key, refitem|
      refitem.each do |ref_type, ref_config|
        res = {}
        ires = nil

        # Check if creatable_if has been defined on the reference configuration
        # and if it evaluates to true

        ci_res = extra_log_type_config.calc_reference_creatable_if ref_config, self
        fb = ref_config[:filter_by]

        if ci_res
          a = ref_config[:add]
          without_reference = (ref_config[:without_reference] == true)
          if a == 'many'
            l = ref_config[:limit]
            under_limit = true

            if l&.is_a?(Integer)
              under_limit = (ModelReference.find_references(master,
                                                            to_record_type: ref_type,
                                                            filter_by: fb,
                                                            active: true,
                                                            without_reference: without_reference).length < l)
            end

            ires = a if under_limit
          elsif a == 'one_to_master'
            if ModelReference.find_references(master,
                                              to_record_type: ref_type,
                                              filter_by: fb,
                                              active: true,
                                              without_reference: without_reference).empty?
              ires = a
            end
          elsif a == 'one_to_this'
            if ModelReference.find_references(self,
                                              to_record_type: ref_type,
                                              filter_by: fb,
                                              active: true,
                                              without_reference: without_reference).empty?
              ires = a
            end
          elsif a.present?
            raise FphsException, "Unknown add type for creatable_model_references: #{a}"
          end

          if ires
            # Check if the user has access to create the item

            mrc = ModelReference.to_record_class_for_type(ref_type)
            raise FphsException, "Reference type is invalid: #{ref_type}" if mrc.nil?

            if mrc.parent == ActivityLog
              elt = ref_config[:add_with] && ref_config[:add_with][:extra_log_type]
              o = mrc.new(extra_log_type: elt, master: master)
            else
              attrs = {}

              if mrc.no_master_association
                attrs[:current_user] = master_user
              else
                attrs[:master] = master
              end
              o = mrc.new attrs
            end

            i = o.allows_current_user_access_to? :create
            res = { ref_type: ref_type, many: ires, ref_config: ref_config } if ires && i

          end

        end

        cre_res[ref_key] = { ref_type => res } if res[:ref_type] || !only_creatables
      end
    end
    @creatable_model_references[memokey] = cre_res
  end

  # Use a provided creatable model reference to make a new item
  # Initialize attributes with any filter_by configurations, to ensure the
  # item is set up correctly to be picked up again later
  def build_model_reference(creatable_model_ref, optional_params: {})
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
    return unless respond_to?(:protocol_id) && protocol_id

    return unless @allow_tracker_sync

    protocol = Classification::Protocol.find(protocol_id)

    # if we are not already passing through sub_process based on a user selection then
    # look up what the Activity name is for protocol sub processes
    if attribute_names.include? 'sub_process_id'
      sub_process_id = self.sub_process_id
      sub_process = Classification::SubProcess.find(sub_process_id)
    else
      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      sub_process = protocol.sub_processes.where(name: ActivityLog.sub_process_name).first
      sub_process_id = sub_process.id
    end
    # if we are not already passing through protocol_event based on a user selection then
    # then use the protocol event name matching the admin activity log definition for this model
    if attribute_names.include? 'protocol_event_id'
      protocol_event_id = self.protocol_event_id
    elsif sub_process
      unless self.class.activity_log_name
        raise "activity_log_name not set for #{self.class}. Can't get the protocol event without it"
      end

      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      pe = sub_process.protocol_events.where(name: self.class.activity_log_name).first
      if pe
        protocol_event_id = pe.id
      else
        raise "Could not find a protocol event for sub process #{sub_process_id} in sync_tracker (#{self.class}). There are these: #{sub_process.protocol_events.map(&:name).join(', ')}."
      end
    end

    # be sure about the user being set, to avoid hidden errors
    raise 'no user set when syncing tracker' unless master.current_user

    t = master.trackers.create(protocol_id: protocol_id,
                               sub_process_id: sub_process_id,
                               protocol_event_id: protocol_event_id,
                               item_id: id,
                               item_type: self.class.name,
                               event_date: action_when,
                               notes: data)

    # check and raise error that is usable by a user if there was a problem (for example, a required field not set)
    raise FphsException, "could not create tracker record: #{t.errors.full_messages.join('; ')}" unless t&.valid?

    t
  end

  def fields_to_sync
    self.class.fields_to_sync
  end

  def format_sync_fields
    return unless parent_class

    fields_to_sync.each do |f|
      formatter = "format_#{f}"
      next unless parent_class.respond_to? formatter

      self[f] = if respond_to? :rec_type
                  parent_class.send("format_#{f}", self[f], rec_type)
                else
                  parent_class.send("format_#{f}", self[f])
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
      send("#{f}=", item.send(f))
    end
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

    attribute_names.each do |field_name|
      next unless field_name.to_s.start_with?('set_related_')

      # get the model name of the related model and its field by
      # getting rid of the set_related_prefix_ then looking for associated model
      # to find one with a matching name
      relitem_field = ''
      relitem_name = ''
      relitem_name_and_field = field_name.to_s.gsub('set_related_', '')
      relitem_list = self.class.reflect_on_all_associations(:belongs_to).map(&:name)

      relitem_list.each do |r|
        next unless relitem_name_and_field.start_with?(r.to_s)

        relitem_field = relitem_name_and_field.gsub("#{r}_", '')
        relitem_name = r.to_s
        # remake the model_field name with the pluralized model name, since this is
        # how the field is referred to in normal field naming and general selections
        relitem_name_and_field = "#{relitem_name.pluralize}_#{relitem_field}"
        break
      end

      if relitem_name.blank?
        raise FphsException, "The field #{field_name} does not correspond to one of #{relitem_list}"
      end

      # get the underlying related item and the value of the field
      relitem = send(relitem_name)

      # handle the situation where a blank item is not using the related items
      next unless relitem

      relitem_field_val = relitem.send(relitem_field)

      curr_val = send(field_name)
      # don't set the value if it is already set, since this indicates we have
      # already configured the model
      send("#{field_name}=", relitem_field_val) unless curr_val

      srfs[field_name.to_sym] = {
        item: relitem,
        name_and_field: relitem_name_and_field.to_sym,
        field: relitem_field.to_sym,
        value: relitem_field_val
      }
    end
    srfs
  end

  # set the fields that are marked as set_related in the current model, back
  # into the related model
  def sync_set_related_fields
    return true unless set_related_fields

    set_related_fields.each do |k, s|
      new_val = send(k)

      curr_val = s[:item].send(s[:field])

      next unless !new_val.blank? && curr_val != new_val

      s[:item].send("#{s[:field]}=", new_val)
      # Do not set master - this should already be set, and setting it again breaks
      # secondary_key matched saves
      s[:item].master = master unless s[:item].master
      s[:item].master.current_user = master_user || user unless s[:item].master_user
      res = s[:item].save
      raise "Failed to save related item. #{s[:item].errors.full_messages.join('; ')}" unless res
    end
    true
  end

  # Store the result of allowing a tracker sync to happen before save, when we
  # would lose access to the required change information.
  def set_allow_tracker_sync
    @allow_tracker_sync = true if !persisted? || (respond_to?(:protocol_id) && protocol_id_changed?)
  end

  def can_edit?
    return @can_edit unless @can_edit.nil?

    @can_edit = false
    resname = extra_log_type_config.resource_name

    # First, check if the user can actually access this type of activity log to edit it
    res = master.current_user.has_access_to? :edit, :activity_log_type, resname
    unless res
      Rails.logger.info "Can not edit activity_log_type #{resname} due to lack of access"
      return
    end

    # either use the editable_if configuration if there is one,
    # or only allow the latest item to be used otherwise
    res = calc_can :edit
    if res == false
      Rails.logger.info "Can not edit activity_log_type #{resname} due to editable_if calculation"
      return

    elsif res.nil?
      @latest_item ||= master.send(self.class.assoc_inverse).unscope(:order).order(id: :desc).limit(1).first
      res = (user_id == master.current_user.id && @latest_item.id == id)
      unless res
        Rails.logger.info "Can not edit activity_log_type #{resname} since it has been overridden by a later item"
        return
      end
    end

    # Finally continue with the standard checks if none of the previous have failed
    @can_edit = super()
  end

  def can_create?
    return @can_create unless @can_create.nil?

    @can_create = false
    res = master.current_user.has_access_to? :create, :activity_log_type, extra_log_type_config.resource_name

    unless res
      Rails.logger.info "Can not create activity_log_type #{extra_log_type_config.resource_name} due to lack of access"
    end

    @can_create = !!(res && super())
  end

  def can_access?
    return @can_access unless @can_access.nil?

    @can_access = false
    res = master.current_user.has_access_to? :access, :activity_log_type, extra_log_type_config.resource_name

    unless res
      Rails.logger.info "Can not access activity_log_type #{extra_log_type_config.resource_name} due to lack of access"
    end

    @can_access = !!(res && super())
  end

  # Extend the standard access check with a check on the extra_log_type resource
  def allows_current_user_access_to?(perform, with_options = nil)
    unless master.current_user
      raise FphsException, 'no master.current_user in activity_log_handler allows_current_user_access_to?'
    end

    if extra_log_type_config&.resource_name
      res = master.current_user.has_access_to? perform, :activity_log_type, extra_log_type_config.resource_name
    end
    res && super(perform, with_options)
  end

  def current_user
    master.current_user
  end

  def current_user=(cu)
    master.current_user = cu
  end

  # An app specific DB trigger may have have created a message notification record.
  # Check for new records, and work from there.
  def check_for_notification_records
    Messaging::MessageNotification.handle_notification_records self
  end

  def handle_save_triggers
    extra_log_type_config.calc_save_trigger_if self
    true
  end

  def handle_before_save_triggers
    extra_log_type_config.calc_save_trigger_if self, alt_on: :before_save
    true
  end

  # Get the container referenced from this activity log
  # @return [NfsStore::Manage::Container | nil]
  def container
    mr = model_references.select { |mra| mra.to_record_type == 'NfsStore::Manage::Container' }.first
    return unless mr

    mr.to_record
  end

  # A referring record is either set based on the the specific record that the controller say is being viewed
  # when an action is performed, or
  # if there is only one model reference we use that instead.
  def referring_record
    return @referring_record == :nil ? nil : @referring_record unless @referring_record.nil?

    res = referenced_from
    @referring_record = res.first&.from_record
    return @referring_record if @referring_record && res.length == 1

    @referring_record = :nil
    nil
  end

  # Top referring record is the top record in the reference hierarchy
  def top_referring_record
    return @top_referring_record == :nil ? nil : @top_referring_record unless @top_referring_record.nil?

    @top_referring_record = next_up = referring_record
    while next_up
      next_up = next_up.referring_record
      @top_referring_record = next_up if next_up
    end

    return @top_referring_record if @top_referring_record

    @top_referring_record = :nil
    nil
  end

  def latest_reference
    return @latest_reference == :nil ? nil : @latest_reference unless @latest_reference.nil?

    @latest_reference = model_references(ref_order: { id: :desc }).first&.to_record

    return @latest_reference if @latest_reference

    @latest_reference = :nil
    nil
  end

  def embedded_item
    return @embedded_item == :nil ? nil : @embedded_item unless @embedded_item.nil?

    action_name = self.action_name || 'index'

    oi = self

    not_embedded_options = %w[not_embedded select_or_add]

    mrs = oi.model_references

    cmrs = oi.creatable_model_references only_creatables: true

    always_embed_reference = oi.extra_log_type_config.view_options[:always_embed_reference]
    always_embed_creatable = oi.extra_log_type_config.view_options[:always_embed_creatable_reference]

    if always_embed_reference
      always_embed_item = mrs.select { |m| m.to_record_type == always_embed_reference.ns_camelize }.first
    end

    if always_embed_item
      # Always embed if instructed to do so by the options config
      @embedded_item = always_embed_item.to_record
    end

    if always_embed_item && @embedded_item
      # Do nothing
    elsif action_name.in?(%w[new create]) && always_embed_creatable
      # If creatable has been specified as always embedded, use this, unless the embeddable item is an activity log.
      cmr_view_as = begin
                      cmrs.first.last.first.last[:ref_config][:view_as]
                    rescue StandardError
                      nil
                    end
      @embedded_item = oi.build_model_reference [always_embed_creatable.to_sym, cmrs[always_embed_creatable.to_sym]]
      if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
        @embedded_item = nil
      end
    elsif action_name.in?(%w[new create]) && cmrs.length == 1
      # If exactly one item is creatable, use this, unless the embeddable item is an activity log.
      cmr_view_as = begin
                      cmrs.first.last.first.last[:ref_config][:view_as]
                    rescue StandardError
                      nil
                    end
      @embedded_item = oi.build_model_reference cmrs.first
      if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
        @embedded_item = nil
      end
    elsif action_name.in?(%w[new create]) && cmrs.length > 1
      # If more than one item is creatable, don't use it
      @embedded_item = nil
    elsif action_name.in?(%w[new create]) && cmrs.empty? && mrs.length == 1
      # Nothing is creatable, but one has been created. Use the existing one.
      @embedded_item = mrs.first.to_record
    elsif action_name.in?(%w[edit update show index]) && mrs.empty?
      # If nothing has been embedded, there is nothing to show
      @embedded_item = nil
    elsif action_name.in?(%w[edit update]) && mrs.length == 1
      # A referenced record exists - the form expects this to be embedded
      # Therefore just use this existing item
      @embedded_item = mrs.first.to_record
      mr_view_as = begin
                     mrs.first.to_record_options_config[:view_as]
                   rescue StandardError
                     nil
                   end
      @embedded_item = nil if mr_view_as && mr_view_as[:edit].in?(not_embedded_options)

    elsif action_name.in?(%w[show index]) && mrs.length == 1 && cmrs.empty?
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

    res = @embedded_item
    @embedded_item ||= :nil
    res
  end
end
