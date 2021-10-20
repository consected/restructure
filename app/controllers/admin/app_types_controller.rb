# frozen_string_literal: true

class Admin::AppTypesController < AdminController
  ValidFormats = %w[json yaml].freeze
  after_action :routes_reload, only: [:upload]

  def restart_server
    AppControl.restart_server
    Rails.cache.clear
    flash.now[:notice] = 'Restarting server, DelayedJob and clearing cache'
    render json: 'Restarting server, DelayedJob and clearing cache'
  end

  def restart_delayed_job
    AppControl.restart_delayed_job
    flash.now[:notice] = 'Restarting DelayedJob'
    render json: 'Restarting DelayedJob'
  end

  def upload
    uploaded_io = params[:config]

    f = params[:upload_format]
    if f.present?
      raise FphsException, "Invalid upload format. Allowed formats: #{ValidFormats}" unless f.in? ValidFormats
    else
      f = 'json'
    end

    begin
      @app_type, results = Admin::AppType.import_config(uploaded_io.read, current_admin, format: f.to_sym)
    rescue StandardError, FphsException => e
      @message = 'FAILED'
      @primary = "#{e}\n#{e.backtrace.join("\n")}"
      render 'upload_results'
      return
    end

    @message = 'SUCCESS'
    if f == 'json'
      @primary = JSON.pretty_generate results
    elsif f == 'yaml'
      @primary = YAML.dump results
    end

    Rails.cache.clear

    render 'upload_results'
  end

  def show
    app_type = Admin::AppType.find(params[:id])
    f = params[:export_format]
    if f.present?
      raise FphsException, "Invalid export format. Allowed formats: #{ValidFormats}" unless f.in? ValidFormats
    else
      f = 'json'
    end

    app_type.current_admin = current_admin

    send_data app_type.export_config(format: f.to_sym), filename: "#{app_type.name}_config.#{f}"
  end

  def export_migrations
    app_type = Admin::AppType.find(params[:id])
    app_type.current_admin = current_admin

    send_file app_type.zip_app_export_migrations.path,
              filename: "#{app_type.name}--#{Admin::AppType::AppExportDirSuffix}.zip"
  end

  protected

  def routes_reload
    DynamicModel.routes_reload
  end

  private

  def permitted_params
    %i[name label default_schema_name disabled]
  end
end
