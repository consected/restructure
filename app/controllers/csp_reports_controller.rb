# frozen_string_literal: true

# Controller to handle Content Security Policy violation reports
class CspReportsController < ApplicationController
  before_action :authenticate_user_or_admin!
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.warn("CSP Violation: #{request.body.read}")
    head :no_content
  end

  private

  def no_action_log
    true
  end
end
