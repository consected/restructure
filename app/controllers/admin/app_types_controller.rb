class Admin::AppTypesController < AdminController

  def upload
    uploaded_io = params[:config]

    res, results = AppType.import_config(uploaded_io.read, current_admin)

    render json: results

  end

  def show
    render json: AppType.find(params[:id]).export_config
  end

  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :label, :app_type_id, :disabled)
    end
end
