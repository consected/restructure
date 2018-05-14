module DynamicModelHandler

  extend ActiveSupport::Concern

  included do
    after_save :generate_model
    after_save :reload_routes
    after_save :add_master_association
    after_save :add_user_access_controls
    after_save :check_implementation_class
    after_save :update_tracker_events
  end

  class_methods do

    def implementation_prefix
      nil
    end

    # This is intentionally a class variable, to capture the model names for all dynamic models
    def model_names
      @model_names ||= []
    end

    def model_names= m
      @model_names = m
    end

    def model_name_strings
      model_names.map {|m| m.to_s}
    end

    def models
      @models ||= {}
    end

    def preload
      nil
    end

    def define_models
      self.preload

      begin
        dma = self.active

        logger.info "Generating models #{self.name} #{self.active.length}"

        dma.each do |dm|
          dm.generate_model
          # Force the admin for cases that this is run outside of the admin console
          # It is expected that this is mostly when originally seeding the database
          dm.current_admin ||= dm.admin

          dm.update_tracker_events
        end
      rescue Exception => e
        Rails.logger.warn "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}"
        puts "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}"
      end

    end

    def routes_reload
      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!
    end


    def enable_active_configurations
      # to ensure that the db migrations can run, check for the existence of the admin table
      # before attempting to use it. Otherwise Rake tasks fail.
      if ActiveRecord::Base.connection.table_exists? self.table_name
        self.active.each do |dm|
          dm.add_master_association if dm.ready?
        end
      else
        puts "Table doesn't exist yet: #{self.table_name}"
      end
    end

  end


  def implementation_controller_defined? parent_class=Module
    return false unless full_implementation_controller_name

    # Check that the class is defined
    klass = parent_class.const_get(full_implementation_controller_name)
    res = klass.is_a?(Class)
    return res
  rescue NameError
    return false
  end

  def implementation_class_defined? parent_class=Module, opt={}
      return false unless full_implementation_class_name
      # Check that the class is defined
      klass = parent_class.const_get(full_implementation_class_name)
      res = klass.is_a?(Class)

      return false unless res

      begin
        # Check if it can be instantiated correctly - if it can't, allow it to raise an exception
        # since this is seriously unexpected
        klass.new
      rescue Exception => e
        err  = "Failed to instantiate the class #{full_implementation_class_name} in parent #{parent_class}: #{e}"
        if opt[:fail_without_exception]
          return false
        else
          raise FphsException.new err
        end
      end

    rescue NameError
      return false
  end

  def can_edit?

    # either use the editable_if configuration if there is one,
    # or only allow the latest item to be used otherwise
    dopt = self.default_options
    if dopt.editable_if
      res = dopt.calc_editable_if(self)
      return unless res
    end

    # Finally continue with the standard checks if none of the previous have failed
    super()
  end


  def ready?
    begin
      return !self.disabled && ActiveRecord::Base.connection.table_exists?(self.table_name)
    rescue => e
      puts e
      return false
    end
  end

  # This needs to be overridden in each provider to allow consistency of calculating model names for implementations
  def implementation_model_name
    nil
  end

  def model_class_name
    implementation_model_name.ns_camelize
  end

  def model_def_name
    implementation_model_name.to_sym
  end

  def model_def
    self.class.models[model_def_name]
  end


  def model_data_template_name
    model_association_name.to_s.hyphenate
  end

  def model_association_name
    full_implementation_class_name.pluralize.ns_underscore.to_sym
  end

  # Full namespaced item type name, underscored with double underscores
  # If there is no prefix then this matches the simple model name
  def full_item_type_name
    prefix = ""
    if self.class.implementation_prefix
      prefix = "#{self.class.implementation_prefix.ns_underscore}__"
    end

    "#{prefix}#{implementation_model_name}"
  end

  # Full namespaced item types (pluralized) name, underscored with double underscores
  def full_item_types_name
    full_item_type_name.pluralize
  end


  def full_implementation_class_name
    full_item_type_name.ns_camelize
  end

  def full_implementation_controller_name
    "#{model_class_name.pluralize}Controller"
  end


  def implementation_class
    full_implementation_class_name.ns_constantize
  end

  def update_tracker_events
    raise "DynamicModel configuration implementation must define update_tracker_events"
  end

  def add_model_to_list m
    tn = model_def_name
    self.class.models[tn] = m
    logger.info "Added new model #{tn}"

    unless self.class.model_names.include? tn
      self.class.model_names << tn
    end
  end

  def remove_model_from_list
    tn = model_def_name
    logger.info "Removed disabled model #{tn}"
    self.class.models.delete(tn)
    self.class.model_names -= [tn]
  end

  def remove_assoc_class in_class_name
    # Dump the old association
    begin
      assoc_ext_name = "#{in_class_name}#{model_class_name.pluralize}AssociationExtension"
      Object.send(:remove_const, assoc_ext_name) if implementation_class_defined?(Object)
    rescue => e
      logger.debug "Failed to remove #{assoc_ext_name} : #{e}"
      # puts "Failed to remove #{assoc_ext_name} : #{e}"
    end
  end


  def reload_routes

    self.class.routes_reload
  end

  def add_user_access_controls

    if !persisted? || disabled_changed?
      admin = self.current_admin
      Admin::UserAccessControl.create_control_for_all_apps admin, :table, model_association_name, disabled: disabled
    end

  end

  def check_implementation_class

    if !disabled
      raise FphsException.new "The implementation of #{table_name} is enabled but the table is not ready to use" unless ready?
      begin
        res = implementation_class.new
      rescue => e
        raise FphsException.new "The implementation of #{table_name} was not completed. Ensure the DB table #{table_name} has been created. #{e}" unless res
      end
    end
  end
end
