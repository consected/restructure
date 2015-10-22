class Admin::DynamicModelsController < ApplicationController

  include AdminControllerHandler
  helper_method :permitted_params, :objects_instance
  
  
  protected
  
    def permitted_params
      @permitted_params = [:id, :name, :category, :table_name, :table_key_name, :schema_name, :primary_key_name, :foreign_key_name, :position, :description, :disabled]
    end          

    def secure_params      
      params.require(object_name.to_sym).permit(*permitted_params)
    end

end
