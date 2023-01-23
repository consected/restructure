# frozen_string_literal: true

# Provide a controller that allows bad routes to be logged without a full stacktrace
class BadRouteController < ActionController::Base
  include AppExceptionHandler

  def not_routed
    @error_title = 'Not Found'
    routing_error_handler ActionController::RoutingError.new('Not Found')
  end
end
