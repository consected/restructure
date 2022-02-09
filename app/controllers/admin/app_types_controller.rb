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
    @primary = case f
               when 'json'
                 @JSON.pretty_generate results
               when 'yaml'
                 YAML.dump results
               end

    Rails.cache.clear

    render 'upload_results'
  end

  def show
    app_type = Admin::AppType.find(params[:id])

    exp_format = params[:export_format]
    show_components = params[:show_components].present?
    if exp_format.present?
      raise FphsException, "Invalid export format. Allowed formats: #{ValidFormats}" unless exp_format.in? ValidFormats
    elsif show_components
      @app_type = app_type
      render 'admin/app_types/components'
      return
    else
      exp_format = 'json'
    end

    app_type.current_admin = current_admin
    send_data app_type.export_config(format: exp_format.to_sym), filename: "#{app_type.name}_config.#{exp_format}"
  end

  #
  # Exports migrations for creating / updating the app_type
  # to the directory <app type name>--app-export then
  # generates a zip file
  def export_migrations
    app_type = Admin::AppType.find(params[:id])
    app_type.current_admin = current_admin

    atn = app_type.name
    raise FphsException if atn.include?('.') || atn.include?('/') || atn.include?('~')

    app_type.export_migrations
    send_file app_type.zip_app_export_migrations.path,
              filename: "#{atn}--#{Admin::AppType::AppExportDirSuffix}.zip"
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
