module DynamicModelHandler

  extend ActiveSupport::Concern

  included do
      after_commit :add_master_association
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

    def define_models

      begin
        dma = self.active

        logger.info "Generating models #{self.name} #{self.active.length}"

        dma.each do |dm|
          dm.generate_model
        end
      rescue =>e
        Rails.logger.warn "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}\n#{e.backtrace.join("\n")}"
        puts "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}\n#{e.backtrace.join("\n")}"
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
          dm.add_master_association
        end
      else
        puts "Table doesn't exist yet: #{self.table_name}"
      end
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


  def implementation_class
    full_implementation_class_name.ns_constantize
  end



  def add_model_to_list m
    tn = model_def_name
    self.class.models[tn] = m
    logger.info "Added new model #{tn}"
    puts "Added new model #{tn}"
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

  def reload_routes
    self.class.routes_reload
  end


end
