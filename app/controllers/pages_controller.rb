# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user_or_admin!
  include AppTypeChange

  #
  # Will redirect to the home page specified in the logo_link (which may cause a change in app type)
  # If logo_link is not set it will redirect to the root path.
  def home
    home_url = if current_user && !current_admin
                 app_config_text(:logo_link, '/')
               else
                 '/'
               end
    redirect_to home_url
  end

  #
  # If a user is logged in (but not as an admin):
  #   Redirect to the home page specified in the app_home_url. If this is not set, it will redirect to the logo_link,
  #   with a possible change in app type. If neither is set, it will redirect to /masters index.
  # If the user is not logged in, or is logged in as an admin:
  #   it will redirect to the root path.
  def app_home
    home_url = if current_user && !current_admin
                 app_config_text :app_home_url, app_config_text(:logo_link, '/masters')
               else
                 '/'
               end
    redirect_to home_url
  end

  #
  # If a user is logged in (but not as an admin):
  #   it will redirect to the home page specified in the logo_link (which may cause a change in app type),
  #   and if logo_link is not set it will redirect to the /masters index.
  # If the user is not logged in, or is logged in as an admin:
  #   Render the admin panel index page
  def index
    if current_user && !current_admin
      home_url = app_config_text(:logo_link, masters_search_path)
      redirect_to home_url
      return
    end
    redirect_to_admin_panel
  end

  #
  # Simple action to refresh the session timeout and return the application version.
  def show
    if params[:id] == 'version'
      render json: { version: Application.version }
    else
      not_found
    end
  end

  #
  # Get the masters index page, which loads all the templates for the app
  # Will try to rely on the browser cache if the reported etag is up to date.
  # Will return blank content if not logged in.
  def template
    return not_authorized unless current_user || current_admin

    etag = Digest::SHA256.hexdigest(helpers.partial_cache_key(:master__search_results_template))
    if current_user
      set_browser_cache(max_age: 604_800, immutable: true)
      return unless stale?(etag: etag)

      render partial: 'masters/cache_search_results_template'
    else
      render plain: ''
    end
  end

  private

  def no_action_log
    true
  end

  def ignore_temp_password_for
    %w[show template]
  end

  def redirect_to_admin_panel
    @is_admin_index = true
    @app_type ||= helpers.admin_app_type
    @server_info = Admin::ServerInfo.new(current_admin)
    render 'index', layout: 'admin_application'
  end
end
