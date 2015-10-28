class DynamicModel < ActiveRecord::Base
  
  include AdminHandler

  default_scope -> {order disabled: :asc, category: :asc, position: :asc,  updated_at: :desc }
  
  attr_accessor :editable
  
  after_commit :reload_model

  def self.orientation category
    return :horizontal if category.to_s.include?('history') 
    return :vertical
  end
  
  def reload_model
    generate_model
    self.class.routes_reload
  end
  
  def self.categories
    active.select(:category).distinct(:category).unscope(:order).map {|s| s.category||'default'}
  end
  
  # This is intentionally a class variable, to capture the model names for all dynamic models
  def self.model_names
    @model_names ||= []
  end
  
  def self.model_names= m
    @model_names = m
  end

  def self.model_name_strings
    model_names.map {|m| m.to_s}
  end

  
  def self.models
    @models ||= {}
  end
  
  def model_def_name 
    table_name.singularize.to_sym
  end
  
  def model_association_name
    table_name.pluralize.to_sym
  end    
  
  def model_path_name
    table_name.pluralize.to_sym
  end
  
  def model_data_template_name
    model_association_name.to_s.hyphenate
  end

  def model_class_name
    table_name.singularize.camelcase
  end
  
  def model_def
    
    self.class.models[model_def_name]
  end
  
  def self.define_models
    
    begin
    
    dma = DynamicModel.active
    logger.info "Generating dynamic models #{DynamicModel.active.length}"
    dma.each do |dm|
      dm.generate_model       
    end
    rescue =>e      
      Rails.logger.warn " Failed to generate dynamic models. Hopefully this is during a migration. #{e.inspect}\n#{e.backtrace.join("\n")}"
    end
    
  end
  
  def generate_model
    
    obj = self
    failed = false
    
    
    if enabled? && !failed # !DynamicModel.const_defined?(model_class_name)
      begin
        
        pkn = (self.primary_key_name).to_sym
        fkn = (self.foreign_key_name || 'master_id').to_sym
        tkn = (self.table_key_name || 'id').to_sym
        man = self.model_association_name
        ro = self.result_order 
        a_new_class = Class.new(ActiveRecord::Base) do
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

        self.class.models[tn] = res

        unless self.class.model_names.include? tn
          self.class.model_names << tn
        end
      rescue=>e
        failed = true
        logger.info "Failure creating a dynamic model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
      end
    end
    if failed || !enabled?    
      logger.info "Removed disabled model #{tn}"
      self.class.models.delete(tn)  
      self.class.model_names -= [tn]
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

  def self.routes_reload
    Rails.application.reload_routes!
  end
    
end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
DynamicModel.define_models