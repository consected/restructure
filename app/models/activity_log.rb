class ActivityLog < ActiveRecord::Base


  include DynamicModelHandler
  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  validates :name, presence: true, uniqueness: {scope: :disabled}
  validates :item_type, presence: true
  validate :check_item_type_and_rec_type




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


  # checks if this activity log works with the specified item_type and optionally rec_type based on admin activity log record configuration
  # if no rec_type is specified, then just the item_type will be used to match broadly,
  # even if the configuration specifies a rec_type as a requirement
  # Only enabled admin activity log records are used, excluding other possible options that are not configured.
  # Returns the item_type_name if true
  def self.works_with item_type, rec_type=nil
    item_type = item_type.downcase
    cond = {item_type: item_type}
    cond[:rec_type] = rec_type if rec_type
    res = self.enabled.where(cond).first
    return unless res
    res.item_type_name
  end

  def self.works_with_rec_types item_type
    self.enabled.where(item_type: item_type).all.map {|i| i.rec_type }
  end

  def blank_log_enabled?
    !blank_log_field_list.blank?
  end



  # return the activity log implementation class that corresponds to
  # this item (item_type / rec_type in an enabled admin activity log record)
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

    # attempt to get the activity log implementation class based on class name
    al_cn = al_cn.camelize
    begin
      fcn = "ActivityLog::#{al_cn}"
      implementation_class = fcn.constantize
    rescue => e
      logger.warn "Failed to get #{fcn} => \n#{e.backtrace[0..10].join("\n")}"
    end
    raise "Failed to get #{al_cn} " unless implementation_class
    return implementation_class
  end

  # The table name for the activity log implementation
  def table_name
    "activity_log_#{item_type_name}".pluralize
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

  # The class that an activity log implementation belongs to
  def item_class
    self.item_type.singularize.classify.constantize
  end

  def item_type_name
    return @item_type_name if @item_type_name
    tn = []
    tn << item_type
    tn << rec_type unless rec_type.blank?
    @item_type_name = tn.join('_')
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
    @implementation_classes = ActivityLog.enabled.map{|a| "ActivityLog::#{[a.item_type, a.rec_type].join('_').classify}".constantize }
  end


  # The selection of possible class names that activity logs could be used with
  # This list is the full list of possible items, and only those configured and read by #works_with are actually available
  # for activity logging
  def self.use_with_class_names
    (DynamicModel.model_names + ExternalIdentifier.model_names + Master::PrimaryAssociations).map{|m| m.to_s.singularize}
  end



  # List of item types that can be used to define GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new admin activity log record, which
  # is in fact provided by self.use_with_class_names
  def self.item_types

    list = []

    implementation_classes.each do |c|

      cn = c.attribute_names.select{|a| a.index('select_') == 0}.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at]
      cn.each do |a|
        list << "#{c.name.ns_underscore}_#{a}".to_sym
      end
    end

    list
  end



  def add_master_association &association_block

    # Add the association
    logger.debug "Associated master: has_many #{self.model_association_name} with class_name: #{self.full_implementation_class_name}"
    Master.has_many self.model_association_name, -> { order(self.action_when_attribute.to_sym => :desc, id: :desc)}, inverse_of: :master, class_name: self.full_implementation_class_name, &association_block
    # Unlike external_id handlers (Scantron, etc) there is no need to update the master's nested attributes this model's symbol
    # since there is no link to advanced search
  end


  # set up a route for each available activity log definition
  def self.routes_load

    begin
      m = self.enabled
      return if m.length == 0

      Rails.application.routes.draw do
        resources :masters, only: [:show, :index, :new, :create] do

            m.each do |pg|
              mn = pg.model_def_name.to_s.pluralize.to_sym
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
              get "activity_log__#{mn}/:id", to: "activity_log/#{mn}#show", as: "activity_log_#{pg.model_def_name.to_s}"

            end
        end
      end

    rescue ActiveRecord::StatementInvalid => e
      logger.warn "Not loading activity log routes. The table has probably not been created yet. #{e.backtrace.join("\n")}"
    end
  end

  # Generate the protocol / sub process  / protocol event entries that will be
  # used by implementations when updating and creating records, and subsequently tracking
  # those changes in the tracker history.
  def update_tracker_events

    logger.info "Generating protocol entries"
    admin = self.current_admin
    Protocol.enabled.each do |p|
      logger.info "For protocol: #{p.id} #{p.name}"
      sps = p.sub_processes.where(name: self.class.sub_process_name)
      if sps.length == 0
        sp = p.sub_processes.create!(name: self.class.sub_process_name, current_admin: admin, disabled: true)
        logger.info "Adding a new Activity sub process #{sp.id}"
      else
        sp = sps.first
        logger.info "Using the existing Activity sub process #{sp.id}"
      end

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
    unless item_type_valid?
      errors.add(:item_type, "#{self.item_type} is invalid. It must be one of (#{self.class.use_with_class_names.join(", ")})")
      return
    end
    unless rec_type_valid?
      errors.add(:rec_type, "(#{rec_type}) invalid for the selected item type #{item_type}.")
      return
    end
  end

  def generate_model

    failed = false

    logger.info "Generating ActivityLog model #{name}"

    if enabled? && !failed
      begin

        parent_type = (self.item_type).to_sym
        parent_rec_type = (self.rec_type).to_sym
        action_when_attribute = (self.action_when_attribute).to_sym
        activity_log_name = self.name

        # Main implementation class
        a_new_class = Class.new(UserBase) do

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
        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include TrackerHandler
        res.include WorksWithItem
        res.include ActivityLogHandler

        c_name = "#{model_class_name.pluralize}Controller"
        res2 = klass.const_set(c_name, a_new_controller)

        logger.debug "Model Name: #{m_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"

        add_model_to_list res
      rescue=>e
        failed = true
        logger.info "Failure creating a activity log model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"

      end
    end
    if failed || !enabled?
      remove_model_from_list
    end

    res
  end

  def check_implementation_class

    if !disabled
      val = view_attribute_list || []
      unless ready?
        err = "The implementation of #{model_class_name} was not completed. Ensure the DB table #{table_name} has been created. Run:
          db/table_generators/generate.sh activity_logs_table #{table_name} false #{val.map{|f| "'#{f}'"}.join(', ')}\"
        Then edit the result to change the field-type for the two CREATE TABLE statements at the top of the results.
        "
        errors.add :name, err
        # Force exit of callbacks
        raise  FphsException.new err
      end

      res = implementation_class.new rescue nil
      unless res
        err = "The implementation of #{model_class_name} was not completed although the DB table #{table_name} has been created."
        errors.add :name, err
        # Force exit of callbacks
        raise FphsException.new err
      end
    end
  end


end


# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
::ActivityLog.define_models
