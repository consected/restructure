# frozen_string_literal: true

class DynamicModel < ActiveRecord::Base
  include DynamicModelDefHandler
  include AdminHandler

  default_scope -> { order disabled: :asc, category: :asc, position: :asc, updated_at: :desc }

  validate :table_name_ok
  after_save :force_option_config_parse

  attr_accessor :editable

  def self.implementation_prefix
    'DynamicModel'
  end

  def resource_name
    full_item_types_name
  end

  # List of item types that can be used to define Classification::GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new dynamic model record
  def self.item_types
    list = []

    implementation_classes.each do |c|
      cn = c.attribute_names.select { |a| a.start_with?('select_') || a.start_with?('multi_select_') || a.end_with?('_selection') || a.in?(%w[source rec_type rank]) }.map(&:to_sym) - %i[disabled user_id created_at updated_at]
      cn.each do |a|
        list << "#{c.name.ns_underscore.pluralize}_#{a}".to_sym
      end
    end

    list
  end

  # the list of defined activity log implementation classes
  def self.implementation_classes
    @implementation_classes = active_model_configurations.map { |a| "DynamicModel::#{a.model_class_name.classify}".constantize }
  end

  def implementation_model_name
    table_name.singularize
  end

  def field_list_array
    field_list.split(/[,\s]+/).map(&:strip).compact if field_list
  end

  def all_implementation_fields(ignore_errors: true)
    fl = field_list_array

    res = (fl || [])
    res.uniq

    if res.empty? && model_def
      begin
        res = model_def.attribute_names - %w[id created_at updated_at contactid user_id master_id]
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
    if category.to_s.include?('history') || category.to_s.include?('-records')
      return :horizontal
    end

    :vertical
  end

  def add_master_association
    # Now forcibly set the Master association if there is a foreign_key_name set
    # If there is no foreign_key_name set, then this is not attached to a master record
    if foreign_key_name.present?

      man = model_association_name

      Master.has_many man, inverse_of: :master, class_name: "DynamicModel::#{model_class_name}", foreign_key: foreign_key_name, primary_key: primary_key_name

      # Add a filtered scope method, which allows master associations to remove non-accessible items automatically
      # This is not the default scope, since it calls calc_showable_if under the covers, and that may
      # reference the associations itself, causing a cascade of calls
      Master.send :define_method, "#{Master::FilteredAssocPrefix}#{model_association_name}" do
        send(man).filter_results
      end

    end
  end

  def self.categories
    active.select(:category).distinct(:category).unscope(:order).map { |s| s.category || 'default' }
  end

  def option_configs(force: false)
    @option_configs = nil if force
    @option_configs ||= DynamicModelOptions.parse_config(self)
  end

  def option_configs_valid?
    DynamicModelOptions.parse_config(self)
    true
  rescue StandardError => e
    logger.info "Checking option configs valid failed silently: #{e}"
    false
  end

  def option_config_for(name)
    return unless option_configs

    option_configs.select { |s| s.name == name }.first
  end

  def default_options
    res = option_config_for :default
    res || DynamicModelOptions.new(:default, {}, self)
  end

  def force_option_config_parse
    option_configs force: true
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
          end

          self.definition = definition
        end

        a_new_controller = Class.new(DynamicModel::DynamicModelsController) do
          class << self
            attr_writer :definition
          end

          class << self
            attr_reader :definition
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
          if implementation_controller_defined?(klass)
            klass.send(:remove_const, c_name)
          end
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
    else
      add_model_to_list res if res
    end

    @regenerate = res
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

  def generator_script
    "db/table_generators/generate.sh dynamic_models_table create  #{table_name} #{all_implementation_fields(ignore_errors: true).join(' ')}"
  end

  def table_name_ok
    if table_name.index(/_[0-9]/)
      errors.add :name, 'must not contain numbers preceded by an underscore.'
    else
      true
    end
  end
end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
# DynamicModel.define_models
