# frozen_string_literal: true

class ActivityLog < ActiveRecord::Base
  include Dynamic::VersionHandler
  include Dynamic::MigrationHandler
  include Dynamic::DefHandler
  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change, on: :update
  before_validation :set_table_name
  validates :name, presence: { scope: :active }
  validates :item_type, presence: { scope: :active }
  validates :table_name, presence: { scope: :active }
  validates :action_when_attribute, presence: { scope: :active }
  validate :item_type_exists
  validate :check_item_type_and_rec_type
  validate :name_ok
  default_scope -> { order 'disabled asc nulls last' }

  after_save :handle_placeholder_fields

  def resource_name
    full_item_types_name
  end

  def implementation_model_name
    item_type_name
  end

  def self.implementation_prefix
    'ActivityLog'
  end

  # Name used in the protocol updates setup for tracker
  def self.sub_process_name
    'Activity'
  end

  # Class that implements options functionality
  def self.options_provider
    OptionConfigs::ActivityLogOptions
  end

  # Don't allow empty extra log types.
  def self.allow_empty_options
    false
  end

  # Attribute holding option configs text
  def self.option_configs_attr
    :extra_log_types
  end

  def human_name
    name
  end

  # List of record types across all item types that are valid for use
  def self.all_valid_item_and_rec_types
    Classification::GeneralSelection
      .selector_collection(['item_type like ?', '%_type'])
      .map { |i| [i.item_type.sub(/(_rec)?_type$/, '').singularize, i.value].join('_') } +
      use_with_class_names
  end

  # checks if this activity log works with the specified item_type and optionally rec_type based on admin activity log record configuration
  # if no rec_type is specified, then just the item_type will be used to match broadly,
  # even if the configuration specifies a rec_type as a requirement
  # Only enabled admin activity log records are used, excluding other possible options that are not configured.
  # Returns the item_type_name if true
  def self.works_with(item_type, rec_type = nil, process_name = nil)
    item_type = item_type.downcase
    cond = { item_type: item_type }
    cond[:rec_type] = rec_type if rec_type
    cond[:process_name] = process_name if process_name
    # Get the first item, since this will get the null rec_type and process_name if they match
    # For the least exact match this is what we want
    res = enabled.where(cond).unscope(:order).order('rec_type asc nulls first, process_name asc nulls first').first
    return unless res

    res.item_type_name
  end

  #
  # Get a list of rec_types (such as [phone, email]) that an activity log of
  # this item type is constrained to use
  # @param [String | Symbol] item_type - an item type, such as 'player_contact'
  # @return [Array] - array of rec_types
  def self.works_with_rec_types(item_type)
    enabled.where(item_type: item_type).pluck(:rec_type).compact.uniq
  end

  def blank_log_enabled?
    !blank_log_field_list.blank?
  end

  # return the activity log implementation class that corresponds to
  # this item (item_type / rec_type / process_name in an enabled admin activity log record)
  def self.implementation_class_for(item)
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
      fc_model_name = model_names.select { |c| c == al_cn }.first
      fc = ::ActivityLog.const_get(fc_model_name.to_s.camelize)
      implementation_class = fc
    rescue StandardError => e
      logger.warn "Failed to get constant #{al_cn} / #{fc_model_name} => \n#{e.backtrace[0..10].join("\n")}"
    end
    raise "Failed to get #{al_cn} " unless implementation_class

    implementation_class
  end

  # The table name for the activity log implementation
  def generate_table_name
    tn = ['activity_log']
    tn << item_type_name

    tn.join('_').pluralize
  end

  # The attribute list defined in the admin record. If blank, the implementation_class
  # equivalent of this method returns a set of fields based on the actual implementation table
  def view_attribute_list
    field_list_array
  end

  # The attribute list defined in the admin record. If blank, the implementation_class
  # equivalent of this method returns a set of fields based on the actual implementation table
  def view_blank_log_attribute_list
    field_list_array for_attrib: blank_log_field_list
  end

  # Get a complete list of all fields required to generate a table.
  # The individual field lists may overlap or be distinct. This gets us a usable list
  def all_implementation_fields(ignore_errors: true)
    res = (view_attribute_list || []) + (view_blank_log_attribute_list || []) + OptionConfigs::ActivityLogOptions.fields_for_all_in(self)
    res.uniq
  rescue FphsException => e
    raise e unless ignore_errors

    @extra_error = e
    []
  end

  # The class that an activity log implementation belongs to
  def item_class
    item_type.singularize.classify.constantize
  end

  # Generate an item_type_name from its component parts
  def self.item_type_name(item_type, process_name, rec_type)
    tn = []
    tn << item_type
    tn << process_name unless process_name.blank?
    tn << rec_type unless rec_type.blank?
    tn.join('_').singularize
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
    return true if rec_type.blank?

    rcs = item_class.valid_rec_types
    # it is valid if there are no rec types in the list || the current rec type is included
    !rcs || rcs.include?(rec_type)
  end

  def item_type_valid?
    return true if self.class.use_with_class_names.include?(item_type)

    false
  end

  def belongs_to_model
    item_type
  end

  # The selection of possible class names that activity logs could be used with
  # This list is the full list of possible items, and only those configured and read by #works_with are actually available
  # for activity logging
  def self.use_with_class_names
    (
      DynamicModel.model_names +
      ExternalIdentifier.model_names +
      Master::PrimaryAssociations
    ).map { |m| m.to_s.singularize }
  end

  # Open an activity log instance for a user, given a string activity log type and ID
  # Verifies that the user has access to this activity log item
  # @param activity_log_type [String] type string that can be converted to a namespaced camelized class name
  # @param id [Integer] id for the activity log implementation instance
  # @return [Dynamic::ActivityLogBase]
  def self.open_activity_log(activity_log_type, id, current_user)
    al_class = activity_log_class_from_type activity_log_type
    activity_log = al_class.find(id)
    activity_log.current_user = current_user
    unless activity_log.allows_current_user_access_to? :access
      raise FsException::NoAccess,
            "User (#{current_user.id}) does not have access to this activity log " \
            "(#{activity_log.extra_log_type}) in (#{activity_log.class.resource_name})"
    end

    activity_log
  end

  # Get the implementation class based on a String type, validating it along the way
  # @param activity_log_type [String] type string that can be converted to a namespaced camelized class name
  # @return [Class]
  def self.activity_log_class_from_type(activity_log_type)
    al_type = activity_log_type.ns_camelize
    al_class = ActivityLog.implementation_classes.select { |a| a.to_s == al_type }.first
    raise FsException::List, 'activity log type specified is invalid' unless al_class

    al_class
  end

  # Set up an association to this class on the Master
  def add_master_association(&association_block)
    return if disabled || !errors.empty?

    begin
      remove_assoc_class 'Master'

      # Add the association
      logger.debug "Associated master: has_many #{model_association_name} with class_name: #{full_implementation_class_name}"
      awa = action_when_attribute.to_sym
      awa = :created_at if awa == :alt_order
      Master.has_many model_association_name,
                      -> { order(awa => :desc, id: :desc) },
                      inverse_of: :master,
                      class_name: full_implementation_class_name,
                      &association_block

      # Unlike external_id handlers (Scantron, etc) there is no need to update the
      # master's nested attributes for this model's symbol
      # since there is no link to advanced search
      add_parent_item_association
    rescue StandardError => e
      puts e
      logger.debug e
    end
  end

  def add_parent_item_association
    # Generate the set of activity log associations, for this item type
    # Ensure the master is set on the activity log when building through the association block
    # build method being called
    # puts "Adding implementation class association: #{implementation_class.parent_class}.has_many #{self.model_association_name.to_sym} #{self.full_implementation_class_name}"
    impl_parent_class = implementation_class.parent_class

    remove_assoc_class "#{impl_parent_class}ActivityLog" if item_type_exists
    #    has_many :activity_logs, as: :item, inverse_of: :item ????
    impl_parent_class.has_many model_association_name.to_sym, class_name: full_implementation_class_name do
      def build(att = nil)
        att[:master] = proxy_association.owner.master
        super(att)
      end
    end
  rescue StandardError => e
    # Catch the errors to avoid an issue preventing the system from starting up
    puts e
    # puts e.backtrace.join("\n")
    logger.error e
  end

  # set up a route for each available activity log definition
  def self.routes_load
    mn = nil
    begin
      m = enabled
      return if m.empty?

      Rails.application.routes.draw do
        resources :masters, only: %i[show index new create] do
          m.each do |pg|
            mn = pg.implementation_model_name.pluralize.to_sym
            Rails.logger.info "Setting up routes for #{mn}"

            ic = pg.item_type.pluralize
            get "#{ic}/:item_id/activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
            get "#{ic}/:item_id/activity_log/#{mn}/", to: "activity_log/#{mn}#index"
            get "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
            post "#{ic}/:item_id/activity_log/#{mn}", to: "activity_log/#{mn}#create"
            get "#{ic}/:item_id/activity_log/#{mn}/:id/edit", to: "activity_log/#{mn}#edit"
            patch "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"
            put "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"
            get "#{ic}/:item_id/activity_log/#{mn}/:id/template_config", to: "activity_log/#{mn}#template_config"

            # used by links to get to activity logs without having to use parent item (such as a player contact with phone logs)
            get "activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
            get "activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
            get "activity_log/#{mn}/", to: "activity_log/#{mn}#index"
            get "activity_log/#{mn}/:id/edit", to: "activity_log/#{mn}#edit"
            post "activity_log/#{mn}", to: "activity_log/#{mn}#create"
            patch "activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"
            get "activity_log/#{mn}/:id/template_config", to: "activity_log/#{mn}#template_config"

            # used by item flags to generate appropriate URLs
            begin
              get "activity_log__#{mn}/:id", to: "activity_log/#{mn}#show",
                                             as: "activity_log_#{pg.implementation_model_name}"
            rescue StandardError
              Rails.logger.warn "Skipped creating route activity_log__#{mn}/:id since activity_log_#{pg.implementation_model_name} already exists?"
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
    logger.info 'Generating protocol entries'
    admin = current_admin

    if disabled
      logger.info 'Not creating protocol entries - activity log implementation is disabled'
      return
    end

    # generate the basic activity log create / update records
    track_name = full_item_type_name.singularize.humanize.downcase

    Tracker.add_record_update_entries track_name, admin, 'record'

    Classification::Protocol.enabled.each do |p|
      # logger.info "For protocol: #{p.id} #{p.name}"

      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      sps = p.sub_processes.where(name: self.class.sub_process_name)
      if sps.empty?
        sp = p.sub_processes.create!(name: self.class.sub_process_name, current_admin: admin, disabled: true)
        logger.info "Adding a new Activity sub process #{sp.id}"
      else
        sp = sps.first
        # logger.info "Using the existing Activity sub process #{sp.id}"
      end

      # Note that we do not use the enabled scope, since we allow this item to be disabled (preventing its use by users)
      pes = sp.protocol_events.where name: name
      if pes.empty?
        pe = sp.protocol_events.create! name: name, current_admin: admin
        logger.info "Adding a new Activity protocol event #{pe.id}"
      else
        # logger.info "Using the existing Activity protocol event #{pes.first.id}"
      end
    end
    true
  end

  def check_item_type_and_rec_type
    unless disabled
      unless item_type_valid?
        errors.add(:item_type,
                   "#{item_type} is invalid. It must be one of " \
                   "(#{self.class.use_with_class_names.join(', ')})")
        return
      end
      unless rec_type_valid?
        errors.add(:rec_type, "(#{rec_type}) invalid for the selected item type #{item_type}.")
        nil
      end
    end
  end

  # Ensure that other dynamic implementations have been loaded before we attempt to create
  # activity logs that rely on them
  def self.preload
    ExternalIdentifier.define_models
    DynamicModel.define_models
  end

  # Dynamically generate the model and controller for this activity log implementation
  def generate_model
    logger.info "---------------------------------------------------------------------------
************** GENERATING ActivityLog MODEL #{name} ****************
---------------------------------------------------------------------------"

    klass = ::ActivityLog
    failed = false
    @regenerate = nil

    if enabled? && !failed
      begin
        definition = self

        if prevent_regenerate_model
          logger.info "Already defined class #{model_class_name}."
          # Refresh the definition in the implementation class
          implementation_class.definition = definition
          return
        end

        # Main implementation class
        a_new_class = Class.new(Dynamic::ActivityLogBase) do
          class << self
            attr_accessor :definition
          end

          self.definition = definition
        end

        a_new_controller = Class.new(ActivityLog::ActivityLogsController) do
          class << self
            attr_accessor :definition
          end

          self.definition = definition
        end

        begin
          # This may fail if an underlying dependent class (parent class) has been redefined by
          # another dynamic implementation, such as external identifier
          if implementation_class_defined?(klass, fail_without_exception: true)
            klass.send(:remove_const, model_class_name)
          end
        rescue StandardError => e
          logger.info '*************************************************************************************'
          logger.info "Failed to remove the old definition of #{model_class_name}. #{e.inspect}"
          logger.info '*************************************************************************************'
        end

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include TrackerHandler
        res.include WorksWithItem
        res.include UserHandler
        res.include Dynamic::ActivityLogImplementer
        res.include Dynamic::ModelReferenceHandler
        res.include Dynamic::RelatedModelHandler
        ESignature::ESignatureManager.enable_e_signature_for res
        res.final_setup

        c_name = full_implementation_controller_name

        begin
          # This may fail if an underlying dependent class (parent class) has been redefined by
          # another dynamic implementation, such as external identifier
          klass.send(:remove_const, c_name) if implementation_controller_defined?(klass)
        rescue StandardError => e
          logger.info '*************************************************************************************'
          logger.info "Failed to remove the old definition of #{c_name}. #{e.inspect}"
          logger.info '*************************************************************************************'
        end

        res2 = klass.const_set(c_name, a_new_controller)
        res2.include ActivityLogControllerHandler

        logger.debug "Model Name: #{model_class_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"

        add_model_to_list res
      rescue StandardError => e
        failed = true
        puts "Failure creating activity log model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        logger.info '*************************************************************************************'
        logger.info "Failure creating activity log model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        logger.info '*************************************************************************************'
      end
    end

    if failed || !enabled?
      remove_model_from_list
    else
      # Check that the implementation has been successful
      unless implementation_class_defined?(klass, fail_without_exception: true)
        puts 'Failure checking activity log model definition.'
        logger.info '*************************************************************************************'
        logger.info 'Failure checking activity log model definition.'
        logger.info '*************************************************************************************'
      end
    end

    @regenerate = res
  end

  def generator_script(version, mode = 'create')
    cname = "#{mode}_#{table_name}_#{version}".camelize
    do_create_or_update = if mode == 'create'
                            'create_activity_log_tables'
                          elsif mode == 'create_or_update'
                            'create_or_update_activity_log_tables'
                          else
                            migration_generator.migration_update_table
                          end

    <<~CONTENT
                  require 'active_record/migration/app_generator'
                  class #{cname} < ActiveRecord::Migration[5.2]
                    include ActiveRecord::Migration::AppGenerator
      #{'      '}
                    def change
                      self.belongs_to_model = '#{item_type}'
                      #{migration_generator.migration_set_attribs}
            #{'          '}
                      #{do_create_or_update}
                      create_activity_log_trigger
                    end
                  end
    CONTENT
  end

  def item_type_exists
    return true unless errors.empty?

    begin
      implementation_class
    rescue StandardError => e
      logger.debug e
      return false
    end

    begin
      implementation_class.parent_class
    rescue StandardError => e
      logger.debug e
      errors.add :item_type,
                 'It seems that the model that this activity log definition is associated with does not exist. ' \
                 "Check that the #{item_type.pluralize} table exists, and if this is a dynamic model " \
                 'or external ID, check it is enabled'
    end
  end

  def set_table_name
    self.table_name = generate_table_name
  end

  def name_ok
    if name.index(/_[0-9]/)
      errors.add :name, 'must not contain numbers preceded by an underscore.'
    else
      true
    end
  end

  # Callback method specific to regenerating models
  def other_regenerate_actions
    if @regenerate
      # Specific to regeneration of the class
    end

    # Always performed
    self.class.reset_all_option_configs_resource_names!

    true
  end

  def handle_placeholder_fields
    return if disabled?

    # Allow placeholder fields to pretend to be form fields
    placeholder_fields = all_implementation_fields.select { |f| f.start_with? 'placeholder_' }.map(&:to_sym)
    implementation_class.send :attr_accessor, *placeholder_fields

    embedded_report_fields = all_implementation_fields.select { |f| f.start_with? 'embedded_report_' }.map(&:to_sym)
    implementation_class.send :attr_accessor, *embedded_report_fields
  end
end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
# ::ActivityLog.define_models
