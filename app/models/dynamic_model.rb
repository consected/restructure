class DynamicModel < ActiveRecord::Base

  include DynamicModelHandler
  include AdminHandler

  default_scope -> {order disabled: :asc, category: :asc, position: :asc,  updated_at: :desc }

  attr_accessor :editable

  def self.implementation_prefix
    "DynamicModel"
  end


  # List of item types that can be used to define GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new dynamic model record
  def self.item_types

    list = []

    implementation_classes.each do |c|

      cn = c.attribute_names.select{|a| a.index('select_') == 0 || a.in?(%w(source rec_type rank)) }.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at]
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

  def self.orientation category
    return :horizontal if category.to_s.include?('history')
    return :vertical
  end


  def add_master_association &association_block
    # Now forcibly set the Master association:
    Master.has_many self.model_association_name, inverse_of: :master , class_name: "DynamicModel::#{self.model_class_name}", foreign_key: self.foreign_key_name, primary_key: self.primary_key_name
  end

  def self.categories
    active.select(:category).distinct(:category).unscope(:order).map {|s| s.category||'default'}
  end



  def update_tracker_events

    return unless self.name && !disabled
    Tracker.add_record_update_entries self.name.singularize, current_admin, 'record'
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
        fkn = self.foreign_key_name.blank? ? 'master_id': self.foreign_key_name.to_sym
        tkn = self.table_key_name.blank? ? 'id' : self.table_key_name.to_sym
        man = self.model_association_name
        ro = self.result_order
        a_new_class = Class.new(UserBase) do
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


          self.primary_key = tkn
          self.foreign_key_name = fkn
          self.primary_key_name = pkn
          self.assoc_inverse = man
          self.result_order = ro

          def master_id
            master.id
          end

          def self.find id
            find_by(primary_key => id)
          end

          def id
            self.attributes[self.class.primary_key.to_s]
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
          klass.send(:remove_const, model_class_name) if implementation_class_defined?(klass, fail_without_exception: true)
        rescue => e
          logger.info "Failed to remove the old definition of #{model_class_name}. #{e.inspect}"
        end

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler

        # Create an alias in the main namespace to make dynamic model easier to refer to

        begin
          Object.send(:remove_const, model_class_name) if implementation_class_defined?(Object, fail_without_exception: true)
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

    mn = model_names

    Rails.application.routes.draw do
      resources :masters do
        mn.each do |pg|
          resources pg.to_s.pluralize.to_sym, except: [:destroy], controller: "dynamic_model/#{pg.to_s.pluralize}"
        end
        namespace :dynamic_model do
          mn.each do |pg|
            resources pg.to_s.pluralize.to_sym, except: [:destroy]
          end
        end
      end
    end
  end


end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
DynamicModel.define_models
