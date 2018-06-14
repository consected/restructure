class Admin::AppTypesController < AdminController

  def upload
    uploaded_io = params[:config]

    _, results = Admin::AppType.import_config(uploaded_io.read, current_admin)

    render json: results

  end

  def show
    app_type = Admin::AppType.find(params[:id])
    send_data app_type.export_config, filename: "#{app_type.name}_config.json"

  end

  protected
  private
    def permitted_params
        [:name, :label, :disabled]
    end
end
