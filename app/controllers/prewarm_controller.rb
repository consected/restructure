# frozen_string_literal: true

# Renders the master template partial outside of any real HTTP request, driven only by
# ActionController::Renderer (issue #1362 Stage 2). ActionController::Renderer never runs
# before_action filters or touches Devise/Warden, so #current_user is overridden directly
# here rather than relying on the normal Devise session lookup, which would raise
# Devise::MissingWarden with no request/session present.
#
# A thread-local class attribute is used rather than the renderer's own `assigns:` option,
# since `assigns:` sets instance variables on the VIEW CONTEXT object, not on the
# controller instance itself (see ActionView::Rendering#_render_template) - a
# `helper_method`-delegated call like `current_user` from within a template always calls
# back to the CONTROLLER instance, which would never see it.
#
# No route ever points at this controller (config/routes.rb ends with a catch-all to
# bad_route#not_routed), so it is not dispatchable over HTTP at all. The overrides below
# are kept private regardless, since a public method on a controller is otherwise a
# dispatchable action by default - this removes that failure mode even if a route were
# ever added by mistake.
class PrewarmController < ApplicationController
  thread_mattr_accessor :prewarm_user

  private

  def current_user
    self.class.prewarm_user
  end
  helper_method :current_user

  def current_admin
    nil
  end
  helper_method :current_admin

  def user_signed_in?
    self.class.prewarm_user.present?
  end
  helper_method :user_signed_in?
end
