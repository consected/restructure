class DynamicModel < ActiveRecord::Base

  include DynamicModelHandler
  include AdminHandler

  default_scope -> {order disabled: :asc, category: :asc, position: :asc,  updated_at: :desc }

  attr_accessor :editable

  after_commit :reload_model

  def implementation_model_name
    table_name.singularize
  end

  def self.orientation category
    return :horizontal if category.to_s.include?('history')
    return :vertical
  end

  def reload_model
    generate_model

    add_master_association
    self.class.routes_reload
  end

  def add_master_association &association_block
    # Now forcibly set the Master association:
    Master.has_many self.model_association_name, inverse_of: :master , class_name: "DynamicModel::#{self.model_class_name}", foreign_key: self.foreign_key_name, primary_key: self.primary_key_name
  end

  def self.categories
    active.select(:category).distinct(:category).unscope(:order).map {|s| s.category||'default'}
  end






  def generate_model

    obj = self
    failed = false


    if enabled? && !failed
      begin

        pkn = (self.primary_key_name).to_sym
        fkn = (self.foreign_key_name || 'master_id').to_sym
        tkn = (self.table_key_name || 'id').to_sym
        man = self.model_association_name
        ro = self.result_order
        a_new_class = Class.new(UserBase) do
          def self.is_dynamic_module
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

        a_new_controller = Class.new(ApplicationController) do

          def edit
            not_authorized
          end

          def update
            not_authorized
          end

          def new
            not_authorized
          end

          def create
            not_authorized
          end

          def destroy
            not_authorized
          end

          private

            def secure_params
            end
        end

        m_name = model_class_name

        res = DynamicModel.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler


        c_name = "#{table_name.pluralize.camelcase}Controller"
        res2 = DynamicModel.const_set(c_name, a_new_controller)
        # Do the include after naming, to ensure the correct names are used during initialization
        res2.include MasterHandler

        logger.info "Model Name: #{m_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"

        tn = model_def_name

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
