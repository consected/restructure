class Admin::AppTypesController < AdminController

  after_action :routes_reload, only: [:upload]

  def upload
    uploaded_io = params[:config]

    begin
      _, results = Admin::AppType.import_config(uploaded_io.read, current_admin)
    rescue => e
      @message = 'FAILED'
      @primary = "#{e}\n#{e.backtrace.join("\n")}"
      render 'upload_results'
      return
    end

    @message = "SUCCESS"
    @primary = JSON.pretty_generate results

    render 'upload_results'

  end

  def show
    app_type = Admin::AppType.find(params[:id])
    send_data app_type.export_config, filename: "#{app_type.name}_config.json"

  end

  protected
    def routes_reload
      DynamicModel.routes_reload
    end

  private
    def permitted_params
        [:name, :label, :disabled]
    end
end
