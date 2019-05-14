class ActivityLog < ActiveRecord::Base

  include DynamicModelHandler
  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  before_validation :set_table_name
  validates :name, presence: {scope: :active}
  validates :item_type, presence: {scope: :active}
  validates :table_name, presence: {scope: :active}
  validates :action_when_attribute, presence: {scope: :active}
  validate :item_type_exists
  validate :check_item_type_and_rec_type
  default_scope -> { order 'disabled asc nulls last'}

  after_save :force_option_config_parse

  def implementation_model_name
    item_type_name
  end

  def self.implementation_prefix
    "ActivityLog"
  end

  # Name used in the protocol updates setup for tracker
  def self.sub_process_name
    'Activity'
  end

  def human_name
    name
  end

  # List of record types across all item types that are valid for use
  def self.all_valid_item_and_rec_types
    Classification::GeneralSelection.selector_collection(['item_type like ?', "%_type"]).map{|i| [i.item_type.sub(/(_rec)?_type$/ ,'').singularize, i.value].join('_')} + self.use_with_class_names
  end


  # checks if this activity log works with the specified item_type and optionally rec_type based on admin activity log record configuration
  # if no rec_type is specified, then just the item_type will be used to match broadly,
  # even if the configuration specifies a rec_type as a requirement
  # Only enabled admin activity log records are used, excluding other possible options that are not configured.
  # Returns the item_type_name if true
  def self.works_with item_type, rec_type=nil, process_name=nil
    item_type = item_type.downcase
    cond = {item_type: item_type}
    cond[:rec_type] = rec_type if rec_type
    cond[:process_name] = process_name if process_name
    # Get the first item, since this will get the null rec_type and process_name if they match
    # For the least exact match this is what we want
    res = self.enabled.where(cond).unscope(:order).order('rec_type asc nulls first, process_name asc nulls first').first
    return unless res
    res.item_type_name
  end

  def self.works_with_rec_types item_type
    self.enabled.where(item_type: item_type).all.map {|i| i.rec_type }
  end

  # Get all the resource names for extra log types in all active activity log definitions
  # Used by user access control definitions and filestore filters
  # @param [Proc] an optional block may be passed to allow filtering based on values in the extra log type config for each entry
  # => for example: extra_log_type_resource_names {|e| e && e.references && e.references[:nfs_store__manage__container]}
  # @return [Array] array of string names
  def self.extra_log_type_resource_names &block
    res = []
    active.each do |a|
      if block_given?
        elts = a.extra_log_type_configs.select(&block)
      else
        elts = a.extra_log_type_configs
      end
      res += elts.map(&:resource_name)
    end
    return res
  end

  def blank_log_enabled?
    !blank_log_field_list.blank?
  end

  def extra_log_type_configs force: false
    @extra_log_type_configs = nil if force
    @extra_log_type_configs ||= ExtraLogType.parse_config(self)
  end

  def extra_log_type_valid?
      ExtraLogType.parse_config(self)
      return true
    rescue
      return false
  end

  def force_option_config_parse
    extra_log_type_configs force:true
  end

  # return the activity log implementation class that corresponds to
  # this item (item_type / rec_type / process_name in an enabled admin activity log record)
  def self.implementation_class_for item

    item_type = item.item_type

    # To start, see if the Activity Log works with this item
    al_cn = ActivityLog.works_with item_type

    # If Activity Log broadly works with this item
    # attempt the same test with the rec_type set to see if there is a more specific match
    if item.respond_to?(:rec_type) && !item.rec_type.blank?
      al_cn_rc = ActivityLog.works_with item_type, item.rec_type
      al_cn = al_cn_rc if al_cn_rc
    end

    #  return if the Activity Log does not work with this item_type / rec_type combo
    return nil unless al_cn


    # If Activity Log broadly works with this item and rec_type
    # attempt the same test with the process_name set to see if there is a more specific match
    if item.respond_to?(:process_name) && !item.process_name.blank?
      al_cn_rc_pn = ActivityLog.works_with item_type, item.rec_type, item.process_name
      al_cn = al_cn_rc_pn if al_cn_rc_pn
    end

    #  return if the Activity Log does not work with this item_type / rec_type combo
    return nil unless al_cn


    # attempt to get the activity log implementation class based on class name
    # al_cn = al_cn.camelize
    begin
      # Make sure we get this through checking the model names to avoid security weakness of using model attribute directly
      fc_model_name = self.model_names.select {|c| c == al_cn.to_sym}.first
      fc = ::ActivityLog.const_get(fc_model_name.to_s.camelize)
      implementation_class = fc
    rescue => e
      logger.warn "Failed to get constant #{al_cn} => \n#{e.backtrace[0..10].join("\n")}"
    end
    raise "Failed to get #{al_cn} " unless implementation_class
    return implementation_class
  end

  # The table name for the activity log implementation
  def generate_table_name
    tn = ["activity_log"]
    tn << item_type_name

    tn.join('_').pluralize
  end

  # The attribute list defined in the admin record. If blank, the implementation_class
  # equivalent of this method returns a set of fields based on the actual implementation table
  def view_attribute_list
    unless self.field_list.blank?
      self.field_list.split(',').map {|f| f.strip}.compact
    end
  end

  # The attribute list defined in the admin record. If blank, the implementation_class
  # equivalent of this method returns a set of fields based on the actual implementation table
  def view_blank_log_attribute_list
    unless self.blank_log_field_list.blank?
      self.blank_log_field_list.split(',').map {|f| f.strip}.compact
    end
  end

  # Get a complete list of all fields required to generate a table.
  # The individual field lists may overlap or be distinct. This gets us a usable list
  def all_implementation_fields ignore_errors: true
    begin
      res = (view_attribute_list || []) + (view_blank_log_attribute_list || []) + ExtraLogType.fields_for_all_in(self)
      res.uniq
    rescue FphsException => e
      raise e unless ignore_errors
      return []
    end
  end

  # The class that an activity log implementation belongs to
  def item_class
    self.item_type.singularize.classify.constantize
  end

  def item_type_name
    return @item_type_name if @item_type_name
    tn = []
    tn << item_type
    tn << process_name unless !respond_to?(:process_name) || process_name.blank?
    tn << rec_type unless rec_type.blank?
    @item_type_name = tn.join('_').singularize
  end




  def rec_type_valid?
    return true if self.rec_type.blank?
    rcs = item_class.valid_rec_types
    # it is valid if there are no rec types in the list || the current rec type is included
    return !rcs || rcs.include?(rec_type)
  end

  def item_type_valid?
    return true if self.class.use_with_class_names.include?(self.item_type)
    false
  end

  # the list of defined activity log implementation classes
  def self.implementation_classes
    @implementation_classes = ActivityLog.enabled.map{|a| "ActivityLog::#{a.item_type_name.classify}".constantize }
  end


  # The selection of possible class names that activity logs could be used with
  # This list is the full list of possible items, and only those configured and read by #works_with are actually available
  # for activity logging
  def self.use_with_class_names
    (DynamicModel.model_names + ExternalIdentifier.model_names + Master::PrimaryAssociations).map{|m| m.to_s.singularize}
  end



  # List of item types that can be used to define Classification::GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new admin activity log record, which
  # is in fact provided by self.use_with_class_names
  def self.item_types

    list = []

    implementation_classes.each do |c|

      cn = c.attribute_names.select{|a| a.start_with?('select_') || a.start_with?('multi_select_') || a.end_with?('_selection') || a.in?(%w(source rec_type rank)) }.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at]
      cn.each do |a|
        list << "#{c.model_name.to_s.ns_underscore}_#{a}".to_sym
      end
    end

    list
  end

  # Open an activity log instance for a user, given a string activity log type and ID
  # Verifies that the user has access to this activity log item
  # @param activity_log_type [String] type string that can be converted to a namespaced camelized class name
  # @param id [Integer] id for the activity log implementation instance
  # @return [ActivityLogBase]
  def self.open_activity_log activity_log_type, id, current_user
    al_class = activity_log_class_from_type activity_log_type
    activity_log = al_class.find(id)
    activity_log.current_user = current_user
    raise FsException::NoAccess.new "User does not have access to this activity log" unless activity_log.allows_current_user_access_to? :access
    activity_log
  end

  # Get the implementation class based on a String type, validating it along the way
  # @param activity_log_type [String] type string that can be converted to a namespaced camelized class name
  # @return [Class]
  def self.activity_log_class_from_type activity_log_type
    al_type = activity_log_type.ns_camelize
    al_class = ActivityLog.implementation_classes.select {|a| a.to_s == al_type}.first
    raise FsException::List.new "activity log type specified is invalid" unless al_class
    return al_class
  end

  def add_master_association &association_block

    return if disabled || !errors.empty?
    begin
      remove_assoc_class 'Master'

      # Add the association
      logger.debug "Associated master: has_many #{self.model_association_name} with class_name: #{self.full_implementation_class_name}"
      awa = self.action_when_attribute.to_sym
      awa = :created_at if awa == :alt_order
      Master.has_many self.model_association_name, -> { order(awa => :desc, id: :desc)}, inverse_of: :master, class_name: self.full_implementation_class_name, &association_block
      # Unlike external_id handlers (Scantron, etc) there is no need to update the master's nested attributes this model's symbol
      # since there is no link to advanced search
      add_parent_item_association
    rescue FphsException => e
      logger.debug e
    end
  end


  def add_parent_item_association
    # Generate the set of activity log associations, for this item type
    # Ensure the master is set on the activity log when building through the association block
    # build method being called
    # puts "Adding implementation class association: #{implementation_class.parent_class}.has_many #{self.model_association_name.to_sym} #{self.full_implementation_class_name}"


    remove_assoc_class "#{implementation_class.parent_class.to_s}ActivityLog" if item_type_exists
    #    has_many :activity_logs, as: :item, inverse_of: :item ????
    implementation_class.parent_class.has_many self.model_association_name.to_sym, class_name: self.full_implementation_class_name do
      def build att=nil
        att[:master] = proxy_association.owner.master
        super(att)
      end
    end


  end

  # set up a route for each available activity log definition
  def self.routes_load

    mn = nil
    begin
      m = self.enabled
      return if m.length == 0
      Rails.application.routes.draw do
        resources :masters, only: [:show, :index, :new, :create] do

            m.each do |pg|
              mn = pg.model_def_name.to_s.pluralize.to_sym
              Rails.logger.info "Setting up routes for #{mn}"

              ic = pg.item_type.pluralize
              get "#{ic}/:item_id/activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
              get "#{ic}/:item_id/activity_log/#{mn}/", to: "activity_log/#{mn}#index"
              get "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
              post "#{ic}/:item_id/activity_log/#{mn}", to: "activity_log/#{mn}#create"
              get "#{ic}/:item_id/activity_log/#{mn}/:id/edit", to: "activity_log/#{mn}#edit"
              patch "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"
              put "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"


              # used by links to get to activity logs without having to use parent item (such as a player contact with phone logs)
              get "activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
              get "activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
              get "activity_log/#{mn}/", to: "activity_log/#{mn}#index"
              get "activity_log/#{mn}/:id/edit", to: "activity_log/#{mn}#edit"
              post "activity_log/#{mn}", to: "activity_log/#{mn}#create"
              patch "activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"
              # used by item flags to generate appropriate URLs
              begin
                get "activity_log__#{mn}/:id", to: "activity_log/#{mn}#show", as: "activity_log_#{pg.model_def_name.to_s}"
              rescue
                Rails.logger.warn "Skipped creating route activity_log__#{mn}/:id since activity_log_#{pg.model_def_name.to_s} already exists?"
              end

            end
        end
      end

    rescue ActiveRecord::StatementInvalid => e
      logger.warn "Not loading activity log routes for #{mn}. The table has probably not been created yet. \n#{e}\n#{e.backtrace.join("\n")}"
    end
  end

  # Generate the protocol / sub process  / protocol event entries that will be
  # used by implementations when updating and creating records, and subsequently tracking
  # those changes in the tracker history.
  def update_tracker_events

    logger.info "Generating protocol entries"
    admin = self.current_admin

    if disabled
      logger.info "Not creating protocol entries - activity log implementation is disabled"
      return
    end

    # generate the basic activity log create / update records
    track_name = full_item_type_name.singularize.humanize.downcase

    Tracker.add_record_update_entries track_name, admin, 'record'

    Classification::Protocol.enabled.each do |p|
      logger.info "For protocol: #{p.id} #{p.name}"

      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      sps = p.sub_processes.where(name: self.class.sub_process_name)
      if sps.length == 0
        sp = p.sub_processes.create!(name: self.class.sub_process_name, current_admin: admin, disabled: true)
        logger.info "Adding a new Activity sub process #{sp.id}"
      else
        sp = sps.first
        logger.info "Using the existing Activity sub process #{sp.id}"
      end

      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      pes = sp.protocol_events.where name: self.name
      if pes.length == 0
        pe = sp.protocol_events.create! name: self.name, current_admin: admin
        logger.info "Adding a new Activity protocol event #{pe.id}"
      else
        logger.info "Using the existing Activity protocol event #{pes.first.id}"
      end
    end
    return true
  end

  def check_item_type_and_rec_type
    unless disabled
      unless item_type_valid?
        errors.add(:item_type, "#{self.item_type} is invalid. It must be one of (#{self.class.use_with_class_names.join(", ")})")
        return
      end
      unless rec_type_valid?
        errors.add(:rec_type, "(#{rec_type}) invalid for the selected item type #{item_type}.")
        return
      end
    end
  end

  # Ensure that other dynamic implementations have been loaded before we attempt to create
  # activity logs that rely on them
  def self.preload
    DynamicModel.define_models
    ExternalIdentifier.define_models
  end


  # Dynamically generate the model and controller for this activity log implementation
  def generate_model

    logger.info "---------------------------------------------------------------------------
    ************** GENERATING ActivityLog MODEL #{self.name} ****************
    ---------------------------------------------------------------------------"

    failed = false


    if enabled? && !failed
      begin

        parent_type = (self.item_type).to_sym
        parent_rec_type = (self.rec_type).to_sym
        action_when_attribute = (self.action_when_attribute).to_sym
        activity_log_name = self.name
        definition = self

        # Main implementation class
        a_new_class = Class.new(ActivityLogBase) do

          def self.parent_type= parent_type
            @parent_type = parent_type
          end
          def self.parent_type
            @parent_type
          end

          def self.parent_rec_type= parent_rec_type
            @parent_rec_type = parent_rec_type
          end
          def self.parent_rec_type
            @parent_rec_type
          end

          def self.action_when_attribute= action_when_attribute
            @action_when_attribute = action_when_attribute
          end
          def self.action_when_attribute
            @action_when_attribute
          end

          def self.activity_log_name= activity_log_name
            @activity_log_name = activity_log_name
          end
          def self.activity_log_name
            @activity_log_name
          end

          def self.definition= d
            @definition = d
          end

          def self.definition
            @definition
          end

          def self.permitted_params
            fts = self.fields_to_sync.map(&:to_sym)
            self.attribute_names.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at, "#{parent_type}_id".to_sym, parent_type, :tracker_id] + [:item_id] - fts
          end

          def model_data_type
            :activity_log
          end

          self.definition = definition
          self.parent_type = parent_type
          self.parent_rec_type = parent_rec_type
          self.action_when_attribute = action_when_attribute
          self.activity_log_name = activity_log_name
        end

        a_new_controller = Class.new(ActivityLog::ActivityLogsController) do

          # Annoyingly this needs to be forced, since const_set below does not
          # appear to set the parent class correctly, unlike for models
          # Possibly this is a Rails specific override, but the parent is set correctly
          # when a controller is created as a file in a namespaced folder, so rather
          # than fighting it, just force the known parent here.
          def self.parent
            ::ActivityLog
          end

          def self.item_controller
            @parent_type
          end
          def item_controller
            self.class.item_controller
          end
          def self.item_controller= parent_type
            @parent_type = parent_type
          end

          def self.item_rec_type
            @parent_rec_type
          end
          def item_rec_type
            self.class.item_rec_type
          end
          def self.item_rec_type= parent_rec_type
            @parent_rec_type = parent_rec_type
          end
          self.item_controller = parent_type.to_s.pluralize
          self.item_rec_type = parent_rec_type.to_s

        end

        m_name = model_class_name

        klass = ::ActivityLog

        begin
          # This may fail if an underlying dependent class (parent class) has been redefined by
          # another dynamic implementation, such as external identifier
          klass.send(:remove_const, model_class_name) if implementation_class_defined?(klass, fail_without_exception: true)
        rescue => e
          logger.info "*************************************************************************************"
          logger.info "Failed to remove the old definition of #{model_class_name}. #{e.inspect}"
          logger.info "*************************************************************************************"
        end

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include TrackerHandler
        res.include WorksWithItem
        res.include ActivityLogHandler
        ESignature::ESignatureManager.enable_e_signature_for res


        # Allow placeholder fields to pretend to be form fields
        placeholder_fields = all_implementation_fields.select {|f| f.start_with? 'placeholder_'}.map(&:to_sym)
        res.send :attr_accessor, *placeholder_fields

        c_name = full_implementation_controller_name

        begin
          # This may fail if an underlying dependent class (parent class) has been redefined by
          # another dynamic implementation, such as external identifier
          klass.send(:remove_const, c_name) if implementation_controller_defined?(klass)
        rescue => e
          logger.info "*************************************************************************************"
          logger.info "Failed to remove the old definition of #{c_name}. #{e.inspect}"
          logger.info "*************************************************************************************"
        end

        res2 = klass.const_set(c_name, a_new_controller)

        logger.debug "Model Name: #{m_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"

        add_model_to_list res
      rescue=>e
        failed = true
        puts "Failure creating activity log model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        logger.info "*************************************************************************************"
        logger.info "Failure creating activity log model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        logger.info "*************************************************************************************"

      end
    end
    if failed || !enabled?
      remove_model_from_list
    end

    res
  end

  def generator_script
    "db/table_generators/generate.sh activity_logs_table create #{table_name} #{item_type.pluralize} #{all_implementation_fields(ignore_errors: true).join(' ')}"
  end



  def item_type_exists
    return true if !errors.empty?
    begin
      implementation_class
    rescue => e
      logger.debug e
      return false
    end

    begin
      return implementation_class.parent_class
    rescue => e
      logger.debug e
      errors.add :item_type, "It seems that the model that this activity log definition is associated with does not exist. Check that the #{item_type.pluralize} table exists, and if this is a dynamic model or external ID, check it is enabled"
    end

  end

  def set_table_name
    self.table_name = self.generate_table_name
  end

end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
::ActivityLog.define_models
