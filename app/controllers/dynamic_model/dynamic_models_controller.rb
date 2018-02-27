class DynamicModel::DynamicModelsController < ApplicationController

  # def edit
  #   not_authorized
  # end
  #
  # def update
  #   not_authorized
  # end
  #
  # def new
  #   not_authorized
  # end
  #
  # def create
  #   not_authorized
  # end

  def destroy
    not_authorized
  end

  private



    def permitted_params
      @implementation_class ||= implementation_class

     res =  @implementation_class.attribute_names.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at, :tracker_id] + [:item_id]
     res
    end

    def secure_params
      @implementation_class = implementation_class
      puts params
      params.require(@implementation_class.name.ns_underscore.gsub('__', '_').singularize.to_sym).permit(*permitted_params)
    end



end
