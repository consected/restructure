# frozen_string_literal: true

# Controller to handle Content Security Policy violation reports.
# CSP reports are sent automatically by the browser when a policy violation is detected.
# Since these are browser-initiated background requests (not user actions),
# they must not extend the user's session timeout.
class CspReportsController < ApplicationController
  # Skip session tracking so CSP reports don't reset the Devise inactivity timer.
  # This must run before any authentication callbacks that trigger Warden's after_set_user hook
  # (e.g., log_access_for_current_user calling current_user).
  prepend_before_action :skip_session_tracking
  before_action :authenticate_user_or_admin!
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.error("CSP Violation: #{request.body.read}")
    head :no_content
  end

  private

  # Prevent CSP reports from resetting session last_request_at.
  # Without this, automatic browser CSP reports keep the session alive
  # indefinitely, preventing Devise's timeoutable from ever timing out.
  def skip_session_tracking
    request.env['devise.skip_trackable'] = true
  end

  def no_action_log
    true
  end
end
