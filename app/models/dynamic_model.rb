class DynamicModel < ActiveRecord::Base

  include DynamicModelDefHandler
  include AdminHandler

  default_scope -> {order disabled: :asc, category: :asc, position: :asc,  updated_at: :desc }

  after_save :force_option_config_parse

  attr_accessor :editable

  def self.implementation_prefix
    "DynamicModel"
  end


  # List of item types that can be used to define Classification::GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new dynamic model record
  def self.item_types

    list = []

    implementation_classes.each do |c|

      cn = c.attribute_names.select{|a| a.start_with?('select_') || a.start_with?('multi_select_') || a.end_with?('_selection') || a.in?(%w(source rec_type rank)) }.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at]
      cn.each do |a|
        list << "#{c.name.ns_underscore.pluralize}_#{a}".to_sym
      end
    end

    list
  end

  # the list of defined activity log implementation classes
  def self.implementation_classes
    @implementation_classes = DynamicModel.active.map{|a| "DynamicModel::#{a.model_class_name.classify}".constantize }
  end


  def implementation_model_name
    table_name.singularize
  end

  def field_list_array
    self.field_list.split(/[,\s]/).map(&:strip).compact if self.field_list
  end

  def all_implementation_fields ignore_errors: true
    begin
      fl = field_list_array

      res = (fl || [])
      res.uniq

      if res.length == 0 && self.model_def
        begin
          res = self.model_def.attribute_names - ['id', 'created_at', 'updated_at', 'contactid', 'user_id', 'master_id']
        rescue => e
          puts "Failed to get all_implementation_fields for reason: #{e.inspect} \n#{e.backtrace.join("\n")}"
          raise e unless ignore_errors
          return []
        end
      end
      res
    rescue FphsException => e
      raise e unless ignore_errors
      return []
    end
  end

  def self.orientation category
    return :horizontal if category.to_s.include?('history') || category.to_s.include?('-records')
    return :vertical
  end



  def add_master_association &association_block
    # Now forcibly set the Master association if there is a foreign_key_name set
    # If there is no foreign_key_name set, then this is not attached to a master record
    if foreign_key_name.present?
      Master.has_many self.model_association_name, inverse_of: :master , class_name: "DynamicModel::#{self.model_class_name}", foreign_key: self.foreign_key_name, primary_key: self.primary_key_name
    end
  end

  def self.categories
    active.select(:category).distinct(:category).unscope(:order).map {|s| s.category||'default'}
  end

  def option_configs force: false
    @option_configs = nil if force
    @option_configs ||= DynamicModelOptions.parse_config(self)
  end

  def option_configs_valid?
      DynamicModelOptions.parse_config(self)
      return true
    rescue => e
      return false
  end


  def option_config_for name
    return unless option_configs
    option_configs.select{|s| s.name == name}.first
  end

  def default_options
    res = option_config_for :default
    res || DynamicModelOptions.new(:default, {}, self)
  end

  def force_option_config_parse
    option_configs force:true
  end

  def update_tracker_events

    return unless self.name && !disabled
    Tracker.add_record_update_entries self.table_name.singularize, current_admin, 'record'
    # flag items are added when item flag names are added to the list
    #Tracker.add_record_update_entries self.name.singularize, current_admin, 'flag'
  end


  def generate_model

    obj = self
    failed = false
    mcn = model_class_name


    if enabled? && !failed
      begin

        pkn = (self.primary_key_name).to_sym
        fkn = self.foreign_key_name.blank? ? nil: self.foreign_key_name.to_sym
        tkn = self.table_key_name.blank? ? 'id' : self.table_key_name.to_sym
        man = self.model_association_name
        ro = self.result_order
        default_options = self.default_options
        n = self.name
        definition = self

        a_new_class = Class.new(DynamicModelBase) do
          def self.is_dynamic_model
            true
          end
          self.table_name = obj.table_name
          def self.assoc_inverse= man
            @assoc_inverse = man
          end
          def self.assoc_inverse
            @assoc_inverse
          end
          def self.foreign_key_name= fkn
            @foreign_key_name = fkn
          end
          def self.foreign_key_name
            @foreign_key_name
          end

          def self.primary_key_name= pkn
            @primary_key_name = pkn
          end
          def self.primary_key_name
            @primary_key_name
          end
          def self.result_order= ro
            @result_order = ro

            unless ro.blank?
              default_scope -> {order ro}
            end

          end
          def self.result_order
            @result_order
          end

          def self.no_master_association
            !@foreign_key_name
          end

          def self.definition= d
            @definition = d
          end

          def self.definition
            @definition
          end

          def self.default_options= default_options
            @default_options = default_options
          end

          def self.default_options
            @default_options
          end

          def self.human_name= n
            @human_name = n
          end

          def self.human_name
            @human_name
          end

          def model_data_type
            :dynamic_model
          end


          self.definition = definition
          self.primary_key = tkn
          self.foreign_key_name = fkn
          self.primary_key_name = pkn
          self.assoc_inverse = man
          self.result_order = ro
          self.default_options = default_options
          self.human_name = n

          def master_id
            return nil if self.class.no_master_association
            master.id
          end

          def current_user
            if self.class.no_master_association
              @current_user
            else
              master.current_user
            end
          end

          def current_user= cu
            if self.class.no_master_association
              @current_user = cu
            else
              master.current_user = cu
            end
          end

          def self.find id
            find_by(primary_key => id)
          end

          def id
            self.attributes[self.class.primary_key.to_s]
          end

          def self.permitted_params

            field_list = definition.field_list
            if field_list.blank?
              field_list = self.attribute_names.map(&:to_sym) - [:disabled, :user_id, :created_at, :updated_at, :tracker_id] + [:item_id]
            else
              field_list = field_list.split(/[,\s]/).map(&:strip).map(&:to_sym)
            end

            field_list
          end

          def option_type
            'default'
          end

          def option_type_config
            self.class.default_options
          end

        end

        a_new_controller = Class.new(DynamicModel::DynamicModelsController) do

          def self.model_class_name= m
            @model_class_name = m
          end
          def self.model_class_name
            @model_class_name
          end
          self.model_class_name = mcn

          # Annoyingly this needs to be forced, since const_set below does not
          # appear to set the parent class correctly, unlike for models
          # Possibly this is a Rails specific override, but the parent is set correctly
          # when a controller is created as a file in a namespaced folder, so rather
          # than fighting it, just force the known parent here.
          def self.parent
            ::DynamicModel
          end

          def edit_form
            'common_templates/edit_form'
          end

          def implementation_class
            cn = self.class.model_class_name
            cnf = "DynamicModel::#{cn}"
            cnf.constantize
          end
        end

        m_name = model_class_name

        klass = ::DynamicModel
        begin
          klass.send(:remove_const, model_class_name) if implementation_class_defined?(klass, fail_without_exception: true, fail_without_exception_newable_result: true)
        rescue => e
          logger.info "Failed to remove the old definition of #{model_class_name}. #{e.inspect}"
        end

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler
        res.include DynamicModelHandler

        ext = Rails.root.join('app', 'models', 'dynamic_model_extension', "#{model_class_name.underscore}.rb")

        if File.exist? ext
          require_dependency ext
          res.include "DynamicModelExtension::#{model_class_name}".constantize
          res.extension_setup if res.respond_to? :extension_setup
        end

        # Create an alias in the main namespace to make dynamic model easier to refer to

        begin
          Object.send(:remove_const, model_class_name) if implementation_class_defined?(Object, fail_without_exception: true, fail_without_exception_newable_result: true)
        rescue => e
          logger.info "Failed to remove the old alias of Object::#{model_class_name}. #{e.inspect}"
        end

        Object.const_set(model_class_name, res)

        c_name = "#{table_name.pluralize.camelcase}Controller"
        begin
          klass.send(:remove_const, c_name) if implementation_controller_defined?(klass)
        rescue => e
          logger.info "Failed to remove the old definition of #{c_name}. #{e.inspect}"
        end

        res2 = klass.const_set(c_name, a_new_controller)
        # Do the include after naming, to ensure the correct names are used during initialization
        res2.include MasterHandler

        logger.info "Model Name: #{m_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"

        add_model_to_list res
      rescue=>e
        failed = true
        logger.info "Failure creating a dynamic model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
      end
    end
    if failed || !enabled?
      remove_model_from_list
    end

    res
  end

  def self.routes_load

    Rails.application.routes.draw do
      DynamicModel.active.each do |dm|

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

end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
DynamicModel.define_models
