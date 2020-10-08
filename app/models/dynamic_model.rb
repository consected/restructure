# frozen_string_literal: true

class DynamicModel < ActiveRecord::Base
  include DynamicModelDefHandler
  include AdminHandler

  StandardFields = %w[id created_at updated_at contactid user_id master_id].freeze

  default_scope -> { order disabled: :asc, category: :asc, position: :asc, updated_at: :desc }

  validate :table_name_ok
  after_save :set_empty_field_list

  attr_accessor :editable

  def self.implementation_prefix
    'DynamicModel'
  end

  # Dynamic Models may have singular or plural table names, so we must use
  # this definition rather than the general resource name method
  def resource_name
    "dynamic_model__#{table_name}"
  end

  # Class that implements options functionality
  def self.options_provider
    OptionConfigs::DynamicModelOptions
  end

  def implementation_model_name
    table_name.singularize
  end

  def all_implementation_fields(ignore_errors: true)
    fl = field_list_array

    res = (fl || [])
    res.uniq

    if res.empty? && model_class
      begin
        res = model_class.attribute_names - StandardFields
      rescue StandardError => e
        puts "Failed to get all_implementation_fields for reason: #{e.inspect} \n#{e.backtrace.join("\n")}"
        raise e unless ignore_errors

        return []
      end
    end
    res
  rescue FphsException => e
    raise e unless ignore_errors

    []
  end

  def self.orientation(category)
    return :horizontal if category.to_s.include?('history') || category.to_s.include?('-records')

    :vertical
  end

  # Set up an association to this class on the Master if there is a foreign_key_name set
  # If there is no foreign_key_name set, then this is not attached to a master record
  def add_master_association
    return if disabled || foreign_key_name.blank?

    man = model_association_name
    Master.has_many man, inverse_of: :master,
                         class_name: "DynamicModel::#{model_class_name}",
                         foreign_key: foreign_key_name,
                         primary_key: primary_key_name

    # Add a filtered scope method, which allows master associations to remove non-accessible items automatically
    # This is not the default scope, since it calls calc_showable_if under the covers, and that may
    # reference the associations itself, causing a cascade of calls
    Master.send :define_method, "#{Master::FilteredAssocPrefix}#{man}" do
      send(man).filter_results
    end
  end

  def self.categories
    active.select(:category).distinct(:category).unscope(:order).map { |s| s.category || 'default' }
  end

  def update_tracker_events
    return unless name && !disabled

    Tracker.add_record_update_entries table_name.singularize, current_admin, 'record'
    # flag items are added when item flag names are added to the list
    # Tracker.add_record_update_entries self.name.singularize, current_admin, 'flag'
  end

  def generate_model
    logger.info "---------------------------------------------------------------------------
************** GENERATING DynamicModel MODEL #{name} ****************
---------------------------------------------------------------------------"

    klass = ::DynamicModel
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
        a_new_class = Class.new(DynamicModelBase) do
          def self.definition=(d)
            @definition = d
            # Force the table_name, since it doesn't include dynamic_model_ as a prefix, which is the Rails convention for namespaced models
            self.table_name = d.table_name
          end

          class << self
            attr_reader :definition

            # Add definition here, since UserHandler relies on it during include
            def no_master_association
              definition.foreign_key_name.blank?
            end
          end

          self.definition = definition
        end

        a_new_controller = Class.new(DynamicModel::DynamicModelsController) do
          class << self
            attr_accessor :definition
          end

          self.definition = definition
        end

        begin
          # This may fail if an underlying dependent class (parent class) has been redefined by
          # another dynamic implementation, such as external identifier
          if implementation_class_defined?(klass, fail_without_exception: true, fail_without_exception_newable_result: true)
            klass.send(:remove_const, model_class_name)
          end
        rescue StandardError => e
          logger.info '*************************************************************************************'
          logger.info "Failed to remove the old definition of #{model_class_name}. #{e.inspect}"
          logger.info '*************************************************************************************'
        end

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler
        res.include DynamicModelHandler
        add_handlers(res)

        res.final_setup

        # Handle extensions with an appropriate name
        ext = Rails.root.join('app', 'models', 'dynamic_model_extension', "#{model_class_name.underscore}.rb")
        if File.exist? ext
          require_dependency ext
          res.include "DynamicModelExtension::#{model_class_name}".constantize
          res.extension_setup if res.respond_to? :extension_setup
        end

        # Create an alias in the main namespace to make dynamic model easier to refer to
        begin
          if implementation_class_defined?(Object, fail_without_exception: true, fail_without_exception_newable_result: true, class_name: model_class_name)
            Object.send(:remove_const, model_class_name)
          end
        rescue StandardError => e
          logger.info '*************************************************************************************'
          logger.info "Failed to remove the old definition of Object::#{model_class_name}. #{e.inspect}"
          logger.info '*************************************************************************************'
        end

        Object.const_set(model_class_name, res)

        # Setup the controller
        c_name = full_implementation_controller_name
        begin
          klass.send(:remove_const, c_name) if implementation_controller_defined?(klass)
        rescue StandardError => e
          logger.info '*************************************************************************************'
          logger.info "Failed to remove the old definition of #{c_name}. #{e.inspect}"
          logger.info '*************************************************************************************'
        end

        res2 = klass.const_set(c_name, a_new_controller)
        res2.include DynamicModelControllerHandler

        logger.debug "Model Name: #{model_class_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"
      rescue StandardError => e
        failed = true
        puts "Failure creating dynamic model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        logger.info '*************************************************************************************'
        logger.info "Failure creating dynamic log model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        logger.info '*************************************************************************************'
      end
    end

    if failed || !enabled?
      remove_model_from_list
    elsif res
      add_model_to_list res
    end

    @regenerate = res
  end

  def add_handlers(res)
    vh = default_options.view_options[:view_handlers]
    return unless vh.present?

    vh.each do |v|
      h = "ViewHandlers::#{v.camelize}".constantize
      res.include h

      res.handle_include_extras if res.respond_to? :handle_include_extras
    end
  end

  def self.routes_load
    m = active_model_configurations
    Rails.application.routes.draw do
      m.each do |dm|
        pg_name = dm.implementation_model_name.pluralize.to_sym
        if dm.foreign_key_name.present?

          resources :masters do
            resources pg_name, except: [:destroy], controller: "dynamic_model/#{pg_name}"
            namespace :dynamic_model do
              resources pg_name, except: [:destroy]
            end
          end

        else

          resources pg_name, except: [:destroy], controller: "dynamic_model/#{pg_name}"
          namespace :dynamic_model do
            resources pg_name, except: [:destroy]
          end
        end
      end
    end
  end

  def generator_script(version, mode = 'create')
    cname = "#{mode}_#{table_name}_#{version}".camelize
    do_create_or_update = if mode == 'create'
                            'create_dynamic_model_tables'
                          else
                            migration_generator.migration_update_fields
                          end

    <<~CONTENT
      require 'active_record/migration/app_generator'
      class #{cname} < ActiveRecord::Migration[5.2]
        include ActiveRecord::Migration::AppGenerator

        def change
          #{migration_generator.migration_set_attribs}

          #{do_create_or_update}
          create_dynamic_model_trigger
        end
      end
    CONTENT
  end

  def table_name_ok
    if table_name.index(/_[0-9]/)
      errors.add :name, 'must not contain numbers preceded by an underscore.'
    else
      true
    end
  end

  def set_empty_field_list
    fl = implementation_class.attribute_names - StandardFields
    self.field_list = fl.join(' ') if field_list.blank?
  end
end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
# DynamicModel.define_models
