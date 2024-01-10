# frozen_string_literal: true

class Admin::AppTypesController < AdminController
  ValidFormats = %w[json yaml].freeze
  after_action :routes_reload, only: [:upload]

  def restart_server
    AppControl.restart_server
    flash.now[:notice] = 'Restarting server, DelayedJob and clearing cache'
    render json: 'Restarting server, DelayedJob and clearing cache'
  end

  def restart_delayed_job
    AppControl.restart_delayed_job
    flash.now[:notice] = 'Restarting DelayedJob'
    render json: 'Restarting DelayedJob'
  end

  def run_db_seeds
    require "#{::Rails.root}/db/seeds.rb"

    res = Seeds.setup
    errors = res.select { |m| m.include? 'ERROR:' }
    if errors.empty?
      render json: 'DB Seeds run'
      return
    end

    flash.now[:notice] = "DB Seeds run - errors #{errors}"
    render json: { message: 'DB Seeds run - errors #{errors} - results in response', lines: res }
  end

  def upload
    uploaded_io = params[:config]

    case params[:force_update]
    when 'yes'
      force_update = :force
    when 'changed'
      force_update = :changed
    end

    dry_run = (params[:dry_run] == 'yes')
    skip_fail = (params[:skip_fail] == 'yes')
    f = params[:upload_format]
    if f.present?
      raise FphsException, "Invalid upload format. Allowed formats: #{ValidFormats}" unless f.in? ValidFormats
    else
      f = 'json'
    end

    @res_obj, @results = Admin::AppTypeImport.import_config(uploaded_io.read,
                                                            current_admin,
                                                            format: f.to_sym,
                                                            force_update: force_update,
                                                            dry_run: dry_run,
                                                            skip_fail: skip_fail)

    render 'upload_results', locals: { dry_run: dry_run }

    Rails.cache.clear
    AppControl.restart_server
  end

  def show
    app_type = Admin::AppType.find(params[:id])

    exp_format = params[:export_format]
    show_components = params[:show_components].present?
    only_config_notices = params[:only_config_notices].present?
    if exp_format.present?
      raise FphsException, "Invalid export format. Allowed formats: #{ValidFormats}" unless exp_format.in? ValidFormats
    elsif show_components
      return render_show_components(app_type)
    elsif only_config_notices
      return render_show_config_notices(app_type)
    else
      exp_format = 'json'
    end

    app_type.current_admin = current_admin
    data = app_type.export_config(format: exp_format.to_sym)
    send_data data, filename: "#{app_type.name}_config.#{exp_format}"
  rescue FphsException => e
    return render_show_config_notices(app_type) if e.message.start_with? 'Bad configurations'

    raise
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

  def default_index_order
    { id: :desc }
  end

  def set_objects_instance(list)
    list = list.to_a.sort_by { |a| a.active_on_server? ? 0 : 1 }
    instance_variable_set("@#{objects_name}", list)
  end

  private

  def permitted_params
    %i[name label default_schema_name disabled]
  end

  def render_show_components(app_type)
    @app_type = app_type
    @config_notices = @app_type.check_option_configs
    render 'admin/app_types/components'
  end

  def render_show_config_notices(app_type)
    @app_type = app_type
    @config_notices = @app_type.check_option_configs
    @config_notices_only = true
    render 'admin/app_types/components'
  end
end
