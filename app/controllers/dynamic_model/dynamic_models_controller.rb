class DynamicModel::DynamicModelsController < UserBaseController


  def destroy
    not_authorized
  end

  private



    def permitted_params
      @implementation_class ||= implementation_class

      res = @implementation_class.permitted_params
      res
    end

    def secure_params
      @implementation_class = implementation_class
      params.require(@implementation_class.name.ns_underscore.gsub('__', '_').singularize.to_sym).permit(*permitted_params)
    end



end
