class DynamicModel < ActiveRecord::Base
  
  include AdminHandler

  default_scope -> {order disabled: :asc, updated_at: :desc }
  
  
  after_commit :reload_model
  
  def reload_model
    generate_model
    self.class.routes_reload
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

  def model_class_name
    table_name.singularize.camelcase
  end
  
  def model_def
    
    logger.info "models?>>>>>>>>>>>>>>>>>> #{self.class.models}"
    
    self.class.models[model_def_name]
  end
  
  def self.define_models
    dma = DynamicModel.active
    logger.info "Generating dynamic models #{DynamicModel.active.length}"
    dma.each do |dm|
      dm.generate_model       
    end
    
  end
  
  def generate_model
    
    obj = self
    
    
    a_new_class = Class.new(ActiveRecord::Base) do
                
      self.table_name = obj.table_name
      def self.assoc_inverse
        self.table_name.to_s.underscore.pluralize.to_sym
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
    if enabled?      
      logger.info "Added enabled model #{tn}"
      self.class.models[tn] = res

      unless self.class.model_names.include? tn
        self.class.model_names << tn
      end
    else
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
