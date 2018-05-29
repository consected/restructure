class Admin::AppTypesController < AdminController

  def upload
    uploaded_io = params[:config]

    _, results = Admin::AppType.import_config(uploaded_io.read, current_admin)

    render json: results

  end

  def show
    render json: Admin::AppType.find(params[:id]).export_config
  end

  protected
  private
    def permitted_params
        [:name, :label, :disabled]
    end
end
