# frozen_string_literal: true

class DynamicModel < ActiveRecord::Base
  include Dynamic::VersionHandler
  include Dynamic::MigrationHandler
  include Dynamic::DefHandler
  include Dynamic::DefGenerator
  include AdminHandler

  StandardFields = %w[id created_at updated_at contactid user_id master_id].freeze

  default_scope -> { order disabled: :asc, category: :asc, position: :asc, updated_at: :desc }

  validate :table_name_ok
  before_save :set_field_list_from_table
  before_save :set_comments_from_table
  before_create :set_keys_from_columns
  before_create :set_field_types_from_columns

  after_save :setup_data_dictionary

  attr_accessor :editable

  def self.implementation_prefix
    'DynamicModel'
  end

  #
  # Dynamic Models may have singular or plural table names, so we must use
  # this definition rather than the general resource name method
  def resource_name
    "dynamic_model__#{table_name}"
  end

  # Resource name for a single instance of the model
  def resource_item_name
    resource_name.to_s.singularize.to_sym
  end

  #
  # Class that implements options functionality
  def self.options_provider
    OptionConfigs::DynamicModelOptions
  end

  #
  # Short singular name without prefix - the model name for the implementation
  def implementation_model_name
    table_name.singularize
  end

  #
  # All fields used by the implementation are either specified in the field list
  # or if empty, the fields are pulled from the underlying table fields, removing
  # standard fields (such as id, created_at...)
  # @param [true|false|nil] ignore_errors - return empty array rather than raising exception
  # @param [true|false|nil] only_real - only return real table columns, not placeholders, etc
  # @return [Array{String}]
  def all_implementation_fields(ignore_errors: true, only_real: false)
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

    res = res.reject { |f| f.index(/^embedded_report_|^placeholder_/) } if only_real

    res
  rescue FphsException => e
    raise e unless ignore_errors

    []
  end

  #
  # A simple (and unreliable) mechanism for forcing the orientation
  # that dynamic model blocks appear in within
  # a panel. Page Layouts is the preferred mechanism for handling this.
  def self.orientation(category)
    return :horizontal if category.to_s.include?('history') || category.to_s.include?('-records')

    :vertical
  end

  #
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
    # This is not the default scope, since it calls #calc_if(:showable_if,...) under the covers, and that may
    # reference the associations itself, causing a cascade of calls
    Master.send :define_method, "#{Master::FilteredAssocPrefix}#{man}" do
      send(man).filter_results
    end
  end

  #
  # Default array of category names, with blanks set to 'default'
  def self.categories
    active.select(:category)
          .distinct(:category)
          .unscope(:order)
          .map { |s| s.category || 'default' }
  end

  #
  # Full set of active table names
  def self.table_names
    active.select(:category)
          .distinct(:table_name)
          .unscope(:order)
          .pluck(:table_name)
          .sort
  end

  #
  # Generate the protocol / sub process  / protocol event entries that will be
  # used by implementations when updating and creating records, and subsequently tracking
  # those changes in the tracker history.
  def update_tracker_events
    return unless name && !disabled

    Tracker.add_record_update_entries table_name.singularize, current_admin, 'record'
  end

  #
  # Generate the implementation model
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
        a_new_class = Class.new(Dynamic::DynamicModelBase) do
          def self.definition=(d)
            @definition = d
            # Force the table_name, since it doesn't include dynamic_model_ as a prefix,
            # which is the Rails convention for namespaced models
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

        remove_implementation_class

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler
        res.include Dynamic::DynamicModelImplementer
        res.include Dynamic::ModelReferenceHandler
        add_handlers(res)

        res.final_setup

        # Handle extensions with an appropriate name
        ext = Rails.root.join('app', 'models', 'dynamic_model_extension', "#{model_class_name.underscore}.rb")
        if File.exist? ext
          require_dependency ext
          res.include "DynamicModelExtension::#{model_class_name}".constantize
          res.extension_setup if res.respond_to? :extension_setup
        end

        remove_implementation_class Object
        Object.const_set(model_class_name, res)

        # Setup the controller
        remove_implementation_controller_class

        res2 = klass.const_set(full_implementation_controller_name, a_new_controller)
        res2.include DynamicModelControllerHandler
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

  #
  # View handlers allow the use of code extensions to implement specific functionality
  # for this model.
  # For example, a view handler 'address' handles country processing and other features
  # of models with specific fields that need address handling
  def add_handlers(res)
    vh = default_options.view_options[:view_handlers]
    return unless vh.present?

    vh.each do |v|
      h = "ViewHandlers::#{v.camelize}".constantize
      res.include h

      res.handle_include_extras if res.respond_to? :handle_include_extras
    end
  end

  def base_route_segments
    "dynamic_model/#{implementation_model_name.pluralize.to_sym}"
  end

  def base_route_short_name
    implementation_model_name.pluralize.to_sym
  end

  #
  # Load dynamic model routes for all active implementations
  def self.routes_load
    m = active_model_configurations
    Rails.application.routes.draw do
      m.each do |dm|
        pg_name = dm.base_route_segments
        short_pg_name = dm.base_route_short_name
        if dm.foreign_key_name.present?

          resources :masters do
            resources short_pg_name, except: [:destroy], controller: pg_name
            namespace :dynamic_model do
              resources short_pg_name, except: [:destroy]
            end
            get "#{pg_name}/:id/template_config", to: "#{pg_name}#template_config"
          end

        else

          resources short_pg_name, except: [:destroy], controller: pg_name
          namespace :dynamic_model do
            resources short_pg_name, except: [:destroy]
          end
          get "#{pg_name}/:id/template_config", to: "#{pg_name}#template_config"
        end
      end
    end
  end

  def table_name_ok
    if table_name.index(/_[0-9]/)
      errors.add :name, 'must not contain numbers preceded by an underscore.'
    else
      true
    end
  end

  #
  # before_save trigger forces the field list to be set, based on database fields
  # @return [String] - space separated field list
  def set_field_list_from_table(force: nil)
    self.field_list = default_field_list_array.join(' ') if force || field_list.blank?
  end

  def default_field_list_array
    return [] unless Admin::MigrationGenerator.table_or_view_exists? table_name

    tc = Admin::MigrationGenerator.table_column_names(table_name)
    tc - StandardFields
  rescue StandardError => e
    logger.warn "Failed to get the default_field_list_array, probably because the class is not available.\n#{e}"
    []
  end

  #
  # before_save trigger forces the comments configuration to be set, based on
  # database table comment and field comments
  def set_comments_from_table(force: nil)
    return unless Admin::MigrationGenerator.table_or_view_exists? table_name

    # Ensure the new options have reloaded
    option_configs
    # Get the table comments configurations
    tc = table_comments || {}
    return if !force && (tc.key?(:table) || tc.key?(:fields))

    tc = {}
    table_comment = Admin::MigrationGenerator.table_comment(table_name, schema_name)
    # The table had a table comment
    tc[:table] = table_comment if table_comment

    column_comments = Admin::MigrationGenerator
                      .column_comments
                      .select { |c| c['schema_name'] == schema_name && c['table_name'] == table_name }

    tc[:fields] = {}
    # Check each each field for a comment in the database
    field_list_array.each do |fname|
      cc = column_comments.find { |c| c['column_name'] == fname }
      next unless cc && cc['column_comment']

      tc[:fields][fname] = cc['column_comment']
    end

    return unless tc[:table] || tc[:fields].present?

    hash = { '_comments' => tc }
    prepend_to_options(hash)
  end

  #
  # If we are creating a new dynamic model referring to a table that already exists,
  # we can use the existence of certain DB columns to populate the dynamic model config.
  # If the id column doesn't exist for example, perhaps it would make sense to use
  # the actual primary key on the table. From an app perspective, id makes most sense when
  # it exists.
  def set_keys_from_columns
    return unless Admin::MigrationGenerator.table_or_view_exists? table_name

    tc = Admin::MigrationGenerator.table_column_names(table_name)
    self.primary_key_name = 'id' if tc.include?('id')
    self.foreign_key_name = 'master_id' if tc.include?('master_id')
  end

  #
  # If we are creating a new dynamic model referring to a table that already exists,
  # setup the options YAML text with DB column types from the database.
  def set_field_types_from_columns(force: nil)
    return unless Admin::MigrationGenerator.table_or_view_exists? table_name

    # Ensure the new options have reloaded
    option_configs
    return if !force && db_columns.present?

    dbc = {}
    table_columns.each do |col|
      dbc[col.name.to_s] = {
        type: col.type.to_s
      }
      dbc[col.name.to_s][:array] = true if col.array?
    end

    return if dbc.empty?

    hash = { '_db_columns' => dbc }
    prepend_to_options(hash)
  end

  #
  # Add the hash to the start of the options text
  # This really needs to be replaced with real configuration
  # handling, but it works effectively when the configuration is new.
  def prepend_to_options(hash)
    hash.deep_stringify_keys!
    key = hash.keys.first
    new_options = YAML.dump(hash)
    self.options ||= ''
    self.options = if self.options.index(/^#{key}:/)
                     self.options = self.options.gsub(/^(#{key}:(.+?))(\n[^\s]|\z)/m, "#{new_options}\\3")
                   else
                     "#{new_options}\n#{self.options}"
                   end

    self.options = self.options.gsub(/^---.*\n/, '')
  end

  #
  # Set up the data dictionary if _data_dictionary: {study: , domain:} options have been specified
  # This is run after_save
  def setup_data_dictionary
    return unless data_dictionary && data_dictionary[:study] && data_dictionary[:domain]

    return if data_dictionary[:prevent_update]

    data_dictionary_handler.refresh_variables_records
  end

  #
  # Produce a data dictionary handler
  def data_dictionary_handler
    @data_dictionary_handler ||= Dynamic::DataDictionary.new(self)
  end

  #
  # After a migration, get updates to the configuration
  def update_config_from_table
    set_field_list_from_table force: true
    set_comments_from_table force: true
    set_field_types_from_columns force: true
    option_configs
  end
end
