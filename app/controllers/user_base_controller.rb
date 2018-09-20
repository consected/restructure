class UserBaseController < ApplicationController

  protect_from_forgery with: :exception, if: Proc.new { |c| c.params[:user_token].blank? }
  protect_from_forgery with: :null_session, if: Proc.new { |c| !c.params[:user_token].blank? }
  acts_as_token_authentication_handler_for User


  include FilterUtils
  include ModelNaming

  before_action :authenticate_user!
  before_action :setup_current_app_type


  def setup_current_app_type
    return unless current_user
    all_apps = Admin::AppType.all_available_to(@current_user)

    # If the current user does not have any app types available, logout and flash a message
    if all_apps.length == 0
      msg = "You have not been granted access to any application types. Contact an administrator to continue use of the application."
    elsif @current_user.app_type_valid?
      current_user.app_type = all_apps.first
      return current_user.save
    end

    if msg
      current_user.app_type = nil

      respond_to do |type|
        type.html {
          sign_out current_user
          redirect_to '/'
          raise FphsException.new msg
        }
        type.json  {
          render :json => {message: msg}, status: 401
        }
      end
      return
    end

    # If the user requests a change to the app type from the nav bar selector, make the change
    if params[:use_app_type].present?
      a = all_apps.select{|app| app.id == params[:use_app_type].to_i}.first
      if a && current_user.app_type_id != a.id
        current_user.app_type = a
        current_user.save

        respond_to do |type|
          type.html {
            # Redirect, to ensure the flash and navs in the layout are updated
            redirect_to masters_search_path
          }
          type.json  {
          }
        end
        return
      elsif !a
        msg = "This app is not available"
        respond_to do |type|
          type.json  {
            render :json => {message: msg}, status: 401
          }
        end
      end
    end

    # If we don't have an app type set, force one
    if current_user.app_type.nil?

      respond_to do |type|
        type.html {
          # If there is only one app type, use it
          # Otherwise, assume the first until a user selects otherwise
          current_user.app_type = all_apps.first
          current_user.save
          # Redirect, to ensure the flash and navs in the layout are updated
          redirect_to masters_search_path
        }
        type.json  {
          msg = "No app type has been selected. Include use_app_type=<id> parameter to set the current application to work with"
          render :json => {message: msg}, status: 400
        }
      end
      return

    end
  end


end
