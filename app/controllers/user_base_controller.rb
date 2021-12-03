# frozen_string_literal: true

#
# Base (abstract) class for virutally all controllers that are to be accessed by a user.
# Its primary responsibilities are:
# - enforcement of authentication
# - search and filtering of results
# - model name resolution based on the controller name
# - handling app type changes requested by a user
class UserBaseController < ApplicationController
  #
  # Provide a forgery protection strategy that recognizes if a request is attempting to use
  # an API user_token, and if so disables CSRF. The user_token has to be correct for the request
  # to actually pass. If a X-CSRF-Token header is provided and is correct, this will override the
  # user_token and the request will be treated as a browser request. If it is not correct, the user_token must be
  # If neither user_token or X-CSRF-Token header are provided then the request will fail.
  #
  # It is expected that this strategy will be extended when JWT or another API request style is implemented.
  class MixedStrategy
    attr_accessor :controller

    def initialize(controller)
      @controller = controller
    end

    def handle_unverified_request
      return null_session.handle_unverified_request if api_user?

      exception.handle_unverified_request
    end

    def api_user?
      controller.params[:user_token].present?
    end

    def jwt_user?
      false
    end

    def request
      @request ||= @controller.request
    end

    def null_session
      ActionController::RequestForgeryProtection::ProtectionMethods::NullSession.new(@controller)
    end

    def exception
      ActionController::RequestForgeryProtection::ProtectionMethods::Exception.new(@controller)
    end
  end

  protect_from_forgery with: MixedStrategy
  acts_as_token_authentication_handler_for User, fallback: :exception

  include FilterUtils
  include ModelNaming
  include AppTypeChange

  before_action :authenticate_user!
  # The #secure_params method is memoized. This can cause specs to fail since they reuse controllers
  before_action -> { @secure_params = nil }
end
