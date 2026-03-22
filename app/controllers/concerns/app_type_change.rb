# frozen_string_literal: true

#
# Handle user app type selection and change for any controller that requires it.
# Ensures that users have access to the desired app type,
# and if a change is made handles appropriate redirections.
# The functionality is driven by two params that can be used in any controller
# that includes this module:
#
#  - :use_app_type
#  - :no_redirect
#
# :use_app_type will change (and save) the app_type_id for the current user
# if it has changed.
# :no_redirect non-blank will prevent a redirect to / (home) after a change,
# or can just be excluded if the default home redirect is required.
#
# Also the current user will be given an app type if they have one and no current
# value is set, and not app type is requested. This is likely the very first request
# they make when logged in.
module AppTypeChange
  extend ActiveSupport::Concern

  included do
    before_action :setup_current_app_type
  end

  protected

  #
  # Called before all actions in the controller
  def setup_current_app_type
    return unless current_user

    return if handled_user_has_no_app_types

    return if user_set_to_default_app_type

    # If the user requests a change to the app type from the nav bar selector, make the change
    if app_type_requested.present?

      return if handled_requested_user_app_not_available

      return if handled_user_app_type_change

    end

    # An app type was set after all this, so just return
    return unless current_user.app_type.nil?

    display_final_app_type_not_set
  end

  private

  def no_redirect_after_change
    params[:no_redirect].present?
  end

  def app_type_requested
    params[:use_app_type]
  end

  #
  # Return true, redirect to home page and flash a message if the requested
  # app type not available to the user
  def handled_requested_user_app_not_available
    return if app_type_requested_id

    msg = 'This app is not available'
    respond_to do |type|
      type.html do
        flash[:warning] = msg
        redirect_to '/'
      end
      type.json do
        render json: { message: msg }, status: 401
      end
    end
    true
  end

  #
  # If the current user does not have any app types available, logout and flash a message
  # Returns nil if the user has app types available
  def handled_user_has_no_app_types
    return unless all_user_app_type_ids.empty?

    msg = 'You have not been granted access to any application types. ' \
          'Contact an administrator to continue use of the application.'

    current_user.app_type_id = nil

    respond_to do |type|
      type.html do
        sign_out current_user
        flash[:warning] = msg
        redirect_to '/'
      end
      type.json do
        render json: { message: msg }, status: 401
      end
    end
    true
  end

  #
  # If the current user app type is not valid, set it to the first item in the list
  # and return true if saved OK
  def user_set_to_default_app_type
    return if @current_user.app_type_valid?

    current_user.app_type_id = all_user_app_type_ids.first
    current_user.save
  end

  def all_user_app_type_ids
    Admin::AppType.all_ids_available_to(current_user)
  end

  #
  # A requested :use_app_type param can be either a string representing an id, or
  # an app type name. Return an app type id if either match.
  # @return [Integer]
  def app_type_requested_id
    @app_type_requested_id ||= if app_type_requested.to_i > 0
                                 all_user_app_type_ids.find { |app_id| app_id == app_type_requested.to_i }
                               else
                                 Admin::AppType
                                   .all_available_to(current_user)
                                   .find { |app| app.name == app_type_requested }&.id
                               end

    unless @app_type_requested_id
      raise FphsException,
            "App type requested was not found, or you may not have access to it: #{app_type_requested}"
    end

    @app_type_requested_id
  end

  #
  # Handle the app type requested being different from the value stored for the current user.
  # If a change is made, return true, and redirect to the home page unless :no_redirect has
  # been requested
  def handled_user_app_type_change
    return if current_user.app_type_id == app_type_requested_id

    current_user.app_type_id = app_type_requested_id
    current_user.save

    respond_to do |type|
      type.html do
        # Redirect, to ensure the flash and navs in the layout are updated
        redirect_to request.path unless no_redirect_after_change
      end
      type.json do
      end
    end
    true
  end

  #
  # The app type was not set after all other options. Display a message appropriately
  def display_final_app_type_not_set
    msg = 'No app type has been selected. ' \
          'Include use_app_type=<id> parameter to set the current application to work with'

    respond_to do |type|
      type.json do
        render json: { message: msg }, status: 400
      end
      type.html do
        flash[:warning] = msg
        redirect_to '/'
      end
    end
  end
end
