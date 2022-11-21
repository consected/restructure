# frozen_string_literal: true

# Handle the setting of users and master records, and checking of permissions
module HandlesUserBase
  extend ActiveSupport::Concern

  included do
    belongs_to :user, optional: true

    # If this model should be associated with a master, check it
    before_validation :check_crosswalk, unless: :allows_nil_master?

    # Ensure the user id is saved
    before_validation :force_write_user

    before_validation :downcase_attributes

    before_create :write_created_by_user

    # Check we can save, unless force_save flag has been set
    # for example, to handle model reference triggers forcing referred records to be save
    before_save :check_can_save, unless: -> { force_save? }

    # This validation ensures that the user ID has been set in the master object
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validate :user_set

    # Validate the record is valid, based on a valid_if configuration
    validate :configurable_valid_if

    # Check the embedded item is valid, and if not pull its error into this object
    validate :valid_embedded_item

    # Create a referring record, if it has been set up
    after_save :create_referring_record

    # If records have the `disabled` column (or a method that wants to pretend this),
    # trigger a handler if the record was disabled
    after_save :handle_disabled, if: -> { respond_to?(:disabled?) && disabled? }

    # Attribute prevents the configured valid_if being evaluated.
    # Doesn't appear to be used anywhere at the moment
    attr_accessor :ignore_configurable_valid_if

    # The #reference is used to identify the current to_record when iterating model references
    # to check the ability to access the record being pointed to from this one.
    # Used primarily by #model_references to calculate ConditionalAction#calc_reference_if
    attr_accessor :reference, :embedded_item

    # Setup alternative id field methods
    Master.setup_resource_alternative_id_fields self unless no_master_association

    add_model_to_list
  end

  class_methods do
    def all_subclasses
      # Subsclasses may be subclassed further - go to the next level if needed.
      UserBase.subclasses.map { |s| s.subclasses || s }.flatten
    end

    def class_from_name(class_name)
      all_subclasses.select { |s| s.name == class_name }.first
    end

    def class_from_table_name(table_name)
      UserBase.descendants.reject(&:abstract_class).select { |c| c.table_name == table_name.to_s }.first
    end

    # Ensure that a provided table_name is clean and can be used safely without SQL injection warnings
    def clean_table_name(table_name)
      class_from_table_name(table_name)&.table_name
    end

    def is_external_identifier?
      false
    end

    #
    # Most models have a master association. Dynamic models may be defined without this,
    # allowing views onto generic tables. This method may be overridden to handle these
    # configurations
    def no_master_association
      false
    end

    #
    # Method to override with an array of Symbol field names to ignore
    # in the crosswalk check before validation
    # For example [:pro_info_id]
    # @return [Array{Symbol | nil}]
    def prevent_crosswalk_check
      nil
    end

    #
    # Provide a simple human friendly name for this type of model, based on the class name.
    # Typically overridden and obtained by configurations, but this fallback remains
    def human_name
      cn = name

      if respond_to?(:is_dynamic_model) && is_dynamic_model || respond_to?(:is_activity_log) && is_activity_log
        cn = cn.split('::').last
      end

      cn.underscore.humanize.captionize
    end

    #
    # Check if a user is allowed some kind of access to this type of model,
    # based on the user access controls 'table' resource type
    # @param [User] user
    # @param [Symbol] perform - such as :access, :edit, :update, :create
    # @param [Hash] with_options -  usage is vague and should be avoided
    # @return [Boolean] result
    def allows_user_access_to?(user, perform, with_options = nil)
      raise FphsException, 'no user in allows_user_access_to?' unless user

      # Check at a table level that the user can access the resource
      named = if respond_to? :definition
                definition.resource_name
              elsif respond_to? :resource_name
                resource_name
              else
                name.ns_underscore.pluralize
              end
      !!user.has_access_to?(perform, :table, named, with_options)
    end

    #
    # Resource name used to identify models in user access controls and elsewhere.
    # May be overridden by dynamic types.
    # @return [String]
    def resource_name
      name.ns_underscore.pluralize
    end

    # Resource name for a single instance of the model
    def resource_item_name
      resource_name.to_s.singularize.to_sym
    end

    # Returns the full model name, namespaced like 'module__class' if there is a namespace.
    # otherwise it returns just the basic name
    def item_type
      name.singularize.ns_underscore
    end

    #
    # Permitted parameters for strong param whitelist are generated based on
    # configured attributes, minus some standard fields
    # Ensure that database columns that are defined as array type can receive
    # arrays in the permitted params by checking the actual column definition
    # and changing the permitted param to an array if necessary
    # @param [Array] param_list - the standard list of params to allow
    # @return [Array] the refined resulting permitted params definition
    def refine_permitted_params(param_list)
      res = param_list.dup

      ms_keys = res.select { |a| columns_hash[a.to_s]&.array }
      ms_keys.each do |k|
        res.delete(k)
        res << { k => [] }
      end

      res
    end

    #
    # Permitted parameters for strong param whitelist are generated based on
    # configured attributes, minus some standard fields. They are then refined
    # to access arrays if needed
    def permitted_params
      res = attribute_names.map(&:to_sym) - %i[disabled user_id created_at updated_at tracker_id tracker_history_id
                                               admin_id]
      refine_permitted_params res
    end

    #
    # An overridable method for dynamic definitions
    def default_options; end

    #
    # Save this model in the resources list
    def add_model_to_list
      Resources::Models.add self unless abstract_class || instance_methods.include?(:add_model_to_list)
    end

    # The base string for route
    # For example "player_infos"
    # Dynamic configurations will override this
    def base_route_segments
      table_name.to_s
    end

    # The base string for route names
    # For example `send("new_#{base_route_name}_path")` returns the path
    # to the "new" controller action
    def base_route_name
      base_route_segments.singularize.gsub('/', '_')
    end

    # Hyphenated name, typically used in HTML markup for referencing target blocks and panels
    def hyphenated_name
      resource_name.ns_hyphenate
    end

    # Hyphenated item name, typically used in HTML markup for referencing individual results
    def hyphenated_item_name
      hyphenated_name.singularize
    end
  end

  #
  # Resource name used to identify models in user access controls and elsewhere.
  # May be overridden by dynamic types.
  # @return [String]
  def resource_name
    self.class.name.ns_underscore.pluralize
  end

  # Resource name for a single instance of the model
  def resource_item_name
    resource_name.to_s.singularize.to_sym
  end

  #
  # Most record types require the master to be set when persisted.
  # External identifiers allow a nil for master_id initially, until assigned to a master record.
  # This method may be overridden in subclasses
  def allows_nil_master?
    false
  end

  #
  # Most record types require the user to be set when persisted.
  # External identifiers allow a nil for user_id initially, until assigned to a master record.
  # This method may be overridden in subclasses
  def creatable_without_user
    false
  end

  #
  # Simply check if an object can be edited based on the user access controls *table* settings
  # This model may be overridden by dynamic definitions
  def can_edit?
    allows_current_user_access_to? :edit
  end

  #
  # Simply check if an object prevents editing, as the inverse of #can_edit?
  def prevent_edit
    !can_edit?
  end

  #
  # Overridable method in dynamic definitions to check if this model can be added as a
  # to-model reference
  # The overrides check if `add_reference_if` is specified, and use it if it is
  def can_add_reference?
    true
  end

  #
  # Prevent add reference buttons appearing on results blocks
  # Otherwise fall back to can_edit?
  def prevent_add_reference
    res = can_add_reference?
    !(res.nil? ? can_edit? : res)
  end

  #
  # Check if this type of model can be created based on user access controls
  # Overridden in dynamic definitions
  def can_create?
    allows_current_user_access_to? :create
  end

  #
  # Check if this type of model can be accessed based on user access controls
  # Overridden in dynamic definitions
  def can_access?
    allows_current_user_access_to? :access
  end

  #
  # Simple wrapper around #valid? that ensures certain validation methods avoid running and breaking outside of
  # the time we actually need them to run (save and create).
  def check_valid?
    self.validating = true

    begin
      res = !marked_invalid? && valid?
    rescue StandardError => e
      errors.add 'unexpected error', e.message
      res = false
    end
    self.validating = false
    res
  end

  #
  # Items can be marked invalid through a soft validation test
  # when an attribute is actually set, rather than at save
  def marked_invalid?
    @marked_invalid
  end

  def mark_invalid=(val)
    @marked_invalid = val
  end

  #
  # We allow a record to be marked as "validating", so that
  # the #check_valid? method only runs when needed.
  def validating?
    @validating
  end

  def validating=(val)
    @validating = val
  end

  # Provide a modified human name for an instance
  def human_name
    if respond_to?(:rec_type) && rec_type
      rec_type.underscore.humanize.captionize
    else
      self.class.human_name
    end
  end

  # Default to allow generalization
  def option_type; end

  # Default to allow generalization
  def option_type_config; end

  # Default to allow generalization
  def creatables(include_references: nil); end

  # Default to allow generalization
  def save_action; end

  # Default to allow generalization
  def def_version; end

  def master_user
    return current_user if self.class.no_master_association

    if respond_to?(:master) && master
      master.current_user

    elsif respond_to?(:item) && item.respond_to?(:master) && item.master
      item.master.current_user

    else
      raise "master is nil and can't be used to get the current user" unless validating?

      nil
    end
  end

  # Returns the full model name, namespaced like 'module__class' if there is a namespace.
  # otherwise it returns just the basic name
  def item_type
    self.class.name.singularize.ns_underscore
  end

  # Returns the full model name pluralized, namespaced like 'module/class' if there is a namespace.
  # otherwise it returns just the basic name
  # works great for generating routes
  def item_type_path
    self.class.name.pluralize.underscore
  end

  def item_type_us
    item_type.ns_underscore
  end

  #
  # A record item is a polymorphic reference to a persisted record, directly
  # from the current instance. This allows a single item to be referenced directly
  # without the need to have an intermediate model reference record.
  # The referenced record is referenced through the attribute pair
  # *record_id* and *record_type*.
  # Unless the argument *no_exception* is true, the user must have access authorization
  # to the target record, otherwise an exception will be raised.
  # @param [true | false] no_exception
  # @return [UserBase]
  def record_item(no_exception: false)
    unless respond_to?(:record_type) && respond_to?(:record_id)
      raise FphsException, 'Does not have a record_type or record_id attribute'
    end

    rc = ModelReference.to_record_class_for_type record_type
    r = rc.find(record_id)
    unless no_exception || r.can_access?
      raise FphsException, "User does not have access to record of type #{record_type}"
    end

    r
  end

  def allows_current_user_access_to?(perform, _with_options = nil)
    no_ma = self.class.no_master_association
    curr_user = if no_ma
                  current_user
                else
                  master_user
                end
    unless curr_user
      raise FphsException,
            "no current_user in allows_current_user_access_to? (no master? #{no_ma})"
    end

    res = self.class.allows_user_access_to? curr_user, perform
    return false unless res

    # Since there is no master association, there is no master to block the access
    return true if no_ma

    if respond_to?(:master) && master
      m = master
    elsif respond_to?(:item) && item.respond_to?(:master) && item.master
      m = item.master
    end

    !!m.allows_user_access
  end

  #
  # Return all the objects that refer to this item through model references
  # @return [Array{UserBase}]
  def referenced_from
    return @referenced_from if @referenced_from

    @referenced_from = ModelReference.find_where_referenced_from self
  end

  # A referring record is either set based on the the specific record that the controller say is being viewed
  # when an action is performed, or
  # if there is only one model reference we use that instead.
  def referring_record
    return @referring_record == :nil ? nil : @referring_record unless @referring_record.nil?

    res = referenced_from
    if res.length == 1
      @referring_record = res.first&.from_record
      return @referring_record if @referring_record
    end

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

  #
  # Model references can set an option to also disable the record they point to if
  # the reference is disabled. This method handles that if called from the model reference
  # and calls back to the save triggers if needed
  def model_reference_disable
    if respond_to? :disabled
      disable! force_save: true
    else
      @was_disabled = 'disabled'
      handle_save_triggers if respond_to? :handle_save_triggers
    end
  end

  #
  # An embedded item is a model reference that has been assessed at runtime to appear embedded
  # in another item (an activity log) as a seamless form.
  # This is that embedded item - a regular UserBase instance
  def embedded_item
    @embedded_item
  end

  def embedded_item=(obj)
    if obj.is_a? UserBase
      @embedded_item = obj
    elsif obj.is_a?(Hash) && embedded_item
      embedded_item.master.current_user ||= master_user
      embedded_item.update obj
      touch(time: embedded_item.updated_at) if embedded_item.updated_at_previously_changed?
    end
  end

  # Used as an indicator in certain models to show that this is part of a master record creation
  # This is used within an external identifier to disable certain validations
  def creating_master=(cm_flag)
    @creating_master = cm_flag
  end

  def creating_master
    @creating_master
  end

  #
  # The referring record attributes are typically set up to identify the record that refers to
  # this one, when this is itself embedded in the referrer.
  def set_referring_record(ref_record_type, ref_record_id, current_user)
    @ref_record_type = ref_record_type
    @ref_record_id = ref_record_id
    @referring_record = find_referring_record
    @referring_record.current_user = current_user
    @referring_record
  end

  #
  # Do the actual search to find the referring record based on the settings
  # made in #set_referring_record
  def find_referring_record
    return unless @ref_record_type

    ref_item_class_name = @ref_record_type.singularize.camelize

    # Find the matching UserBase subclass that has this name, avoiding using the supplied param
    # in a way that could be risky by allowing code injection
    ic = UserBase.class_from_name ref_item_class_name

    # Look up the item using the item_id parameter.
    @referring_record = ic.find(@ref_record_id.to_i)
    @referring_record.current_user = current_user
    @referring_record
  end

  #
  # Create a record for the referring record object that has been set up, if
  # a referring record type has been specified
  # @return [ModelReference]
  def create_referring_record
    return unless @ref_record_type

    @referring_record = find_referring_record
    ModelReference.create_with @referring_record, self if @referring_record
  end

  #
  # If the model has an attribute background_job_ref then use this to find and cancel the background job
  #  Typically used if disabling a record, to avoid future jobs attempting to reference it
  def cancel_associated_job!
    return unless respond_to?(:background_job_ref) && background_job_ref.present?

    ref_parts = background_job_ref.split('%')
    valid_ref_cns = ['delayed__backend__active_record__job'].freeze
    valid_ref_cn = valid_ref_cns.select { |s| s == ref_parts.first }.first
    return unless valid_ref_cn

    job = valid_ref_cn.ns_camelize.constantize.find(ref_parts.last.to_i)
    job&.delete
  end

  #
  # Set the background_job_ref attribute, either using a job, or directly with a string.
  # The stored format is "namespace__class_name%id"
  # @param [Job | String] job
  def set_background_job_ref(job)
    return unless respond_to?(:background_job_ref=)

    job = "#{job.provider_job.class.name.ns_underscore}%#{job.provider_job.id}" if job.respond_to?(:provider_job)
    self.background_job_ref = job
  end

  #
  # Allow a record to be saved without checking if the current user actually has access controls to do this
  def force_save!
    @force_save = true
  end

  def force_save?
    @force_save
  end

  #
  # Disable a record using either the master's current user, an explicit
  # current user, or force a save skipping the checks
  # This assumes the record has a `disabled` attribute
  def disable!(current_user: nil, force_save: false)
    force_save! if force_save
    self.current_user ||= current_user
    update! disabled: true
  end

  protected

  #
  # Validate crosswalk attributes supplied do not attempt to duplicate
  # any existing ids in other Master records, or provide crosswalk ids
  # and master ids that don't match.
  # This is skipped if this model is configured to not have a master association
  # Only crosswalk IDs (not external IDs) are checked in this way
  # If there is a specific crosswalk field in a model that should not be checked,
  # override {HandlesUserBase#prevent_crosswalk_check} with an array of the fields (Symbols) to
  # be ignored for this model.
  # For example, FPHS model ProInfo has a pro_info_id field that sets the same crosswalk
  # field in Master through a DB trigger after the ProInfo record has been persisted. Checking
  # the crosswalk field would fail, because the master record has not been updated at this point.
  def check_crosswalk
    return if self.class.no_master_association

    check_attrs = Master.crosswalk_attrs - (self.class.prevent_crosswalk_check || [])
    check_attrs.each do |attr|
      ext_id_val = send(attr)
      ext_id_val = nil if ext_id_val.blank?

      # An external id has been provided,
      # so lookup the master with the external id
      found_master = Master.find_with_alternative_id(attr, ext_id_val, current_user) if ext_id_val

      if ext_id_val && !master_id
        # An external id has been provided, and a master id has not,
        # so use the looked up the master
        raise "#{attr} set (#{ext_id_val}), but it does not match a master record #{master_id}" unless found_master

        self.master_id = found_master.id
      elsif ext_id_val && master_id && found_master&.id != master_id
        # An external id has been provided, and so has a master_id
        # but the master record found for the external id does not match
        # the master_id
        raise "#{attr}=#{ext_id_val} and master_id=#{master_id}, " \
              "but they do not correspond to the same record (found master #{found_master&.id})"
      end
    end

    return unless respond_to?(:master) && !(master_id && master) && !validating?

    raise FphsException, "master not set in #{self} #{id}"
  end

  def no_user_validation
    (creatable_without_user && !persisted?) ||
      validating? || force_save? ||
      (self.class.no_master_association && !respond_to?(:current_user))
  end

  #
  # Typically the user_id is not written to directly, and has been overriden to avoid
  # accidental changes. This method allows the model to write the user_id based on the
  # current user for the master that this object belongs to.
  def force_write_user
    return true if no_user_validation

    # Special handling for editable reports and dynamic models with no_master_association set
    if respond_to?(:user_id) && respond_to?(:current_user) && (
      !self.class.respond_to?(:no_master_association) || self.class.no_master_association
    )
      return write_attribute :user_id, current_user.id
    end

    logger.debug "Forcing save of user in #{self}"
    return if respond_to?(:master) && !master

    mu = master_user
    unless mu.is_a?(User) && mu.persisted?
      master = '[not defined]' unless respond_to? :master
      raise "bad user (for master #{master}) being pulled from master_user " \
      "(#{mu.is_a?(User) ? '' : 'not a user'}#{mu && mu.persisted? ? '' : ' not persisted'})"
    end

    write_attribute :user_id, mu.id
  end

  # When creating, set the created_by_user_id attribute if it exists
  def write_created_by_user
    return true unless attribute_names.include? 'created_by_user_id'

    # Failsafe, in case this is already set
    return true if attributes['created_by_user_id']

    # Special handling for editable reports and dynamic models with no_master_association set
    if respond_to?(:user_id) && respond_to?(:current_user) && (
      !self.class.respond_to?(:no_master_association) || self.class.no_master_association
    )
      return unless current_user

      cuid = if current_user.is_a? Integer
               current_user
             elsif current_user.respond_to? :id
               current_user.id
             end
      write_attribute :created_by_user_id, cuid
      return
    end

    return if respond_to?(:master) && !master

    mu = master_user
    unless mu.is_a?(User) && mu.persisted?
      raise "bad user (for master #{master}) being pulled from master_user when creating record " \
            "(#{mu.is_a?(User) ? '' : 'not a user'}#{mu && mu.persisted? ? '' : ' not persisted'})"
    end

    write_attribute :created_by_user_id, mu.id
  end

  # A validation method for if the user has been set
  def user_set
    return true if no_user_validation

    unless user
      errors.add :user, 'must be authenticated and set'
      logger.warn "User is not set. Failed user_set validation for #{inspect}"
    end
    user
  end

  # Downcase attributes prior to validation only if
  # the name does not match a predefined 'ignore' regex
  # and it is one of the permitted params
  # NOTE: previously there was a bug that downcased params that were not in the
  # permitted params list, and this could unexpectedly change attributes that were
  # not submitted by a user. Although this could be considered reasonable, with the
  # introduction of filepaths with Filestore, the result was damaging.
  # To allow specific models to specify additional attributes not to downcase
  # define a class method no_downcase_attributes returning an array of attribute names
  def downcase_attributes
    ea = ''
    attr_list = []

    if self.class.respond_to?(:no_downcase_attributes) && self.class.no_downcase_attributes
      attr_list += self.class.no_downcase_attributes
    end

    attr_list += no_downcase_attributes if respond_to?(:no_downcase_attributes) && no_downcase_attributes

    attr_list.each do |e|
      ea += "(#{e})?"
    end

    ignore =
      /(item_type)?(notes)?(description)?(message)?(.+_notes)?(.+_description)?(.+_details)?(e_signed_document)?#{ea}/

    attributes.select { |k, _v| k.to_sym.in? self.class.permitted_params }
              .reject { |k, _v| k && k.match(ignore)[0].present? }
              .each do |k, v|
                send("#{k}=".to_sym, v.downcase) if attributes[k].is_a? String
              end
    true
  end

  #
  # Check if the record can be saved (based on editable and creatable rules) and if not, raise an exception
  def check_can_save
    if persisted? && !can_edit?
      msg = if Rails.env.test?
              "This item is not editable (#{respond_to?(:human_name) ? human_name : self.class.name}) #{id}" \
              " - #{current_user.email} - #{current_user.app_type&.name}"
            else
              "This item is not editable (#{respond_to?(:human_name) ? human_name : self.class.name}) #{id}"
            end
      raise FphsException, msg
    end

    if !persisted? && !can_create?
      msg = if Rails.env.test?
              "This item can not be created (#{respond_to?(:human_name) ? human_name : self.class.name})" \
              " - #{current_user.email} - #{current_user.app_type&.name}"
            else
              "This item can not be created (#{respond_to?(:human_name) ? human_name : self.class.name})"
            end
      raise FphsException, msg
    end
  end

  #
  # Get the valid_if configuration from the option type config if available
  # then evaluate it.
  # Automatically true if there is no configuration
  # Sets @return_failures attribute hash if there are failures to report
  # @return [truthy]
  def evaluate_valid_if_config
    return true if @ignore_configurable_valid_if || !option_type_config.respond_to?(:valid_if)

    return true if option_type_config.valid_if.empty?

    action_name = persisted? ? :update : :create
    @return_failures = {}
    option_type_config.calc_valid_if action_name, self, return_failures: @return_failures
  end

  #
  # Validation method that checks if a valid_if configuration shows all the fields being valid,
  # or produces the appropriate errors if not
  def configurable_valid_if
    return true if evaluate_valid_if_config

    if @return_failures.empty?
      errors.add :field_validation, 'failed. Check your entries and try again'
      return
    end

    @return_failures.each do |c_var, c_vals|
      c_vals.each do |table, cond|
        cond.each do |k, v|
          v = v.present? ? v : '(blank)'
          if v.is_a? Hash
            next if v[:hide_error]

            v = if v[:condition]
                  "#{v[:condition]} #{v[:value].present? ? v[:value] : '(blank)'}"
                else
                  "#{v.first.first.to_s.humanize.downcase}: #{v.first.last.present? ? v.first.last : '(blank)'}"
                end
          elsif v.is_a?(Array) && [['', nil], [nil, '']].include?(v)
            v = '(blank)'
          else
            v = ": #{v}"
          end
          k = table == :this ? k : "#{table}.#{k}"

          msg = nil
          case c_var
          when :all
            msg = "is invalid. Expected value to be #{v}"
          when :any
            msg = "is one of several possible fields that is invalid - one must match. Expected value #{v}"
          when :not_any
            msg = "is invalid. Expected value not to be #{v}"
          when :not_all
            msg = "is one of several possible fields that is invalid - none must match. Expected value not #{v}"
          end

          errors.add k.to_sym, msg if msg
        end
      end
    end
    nil
  end

  # Validation method for the embedded item, checking whether the item has errors set,
  # and making them available locally if so
  def valid_embedded_item
    return unless embedded_item && !embedded_item.errors.empty?

    embedded_item.errors.each do |k, v|
      errors.add k, v
    end
  end

  #
  # Set a flag if the record was disabled,
  # cancel an associated background job if there is one
  # and disable any model references that were pointing to this item
  def handle_disabled
    @was_disabled = true
    cancel_associated_job!

    refs_pointing_to_self = ModelReference.find_references_to(self)
    refs_pointing_to_self.update_all(disabled: true)
  end
end
