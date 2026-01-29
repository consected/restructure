# frozen_string_literal: true

# Controller to handle Content Security Policy violation reports
class CspReportsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.error("CSP Violation: #{request.body.read}")
    head :no_content
  end
end
