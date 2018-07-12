class Admin::AppTypesController < AdminController

  def upload
    uploaded_io = params[:config]

    begin
      _, results = Admin::AppType.import_config(uploaded_io.read, current_admin)
    rescue => e
      render text: "#{e}\n#{e.backtrace.join("\n")}"
      return
    end

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
