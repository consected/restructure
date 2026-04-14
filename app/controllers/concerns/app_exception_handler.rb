# frozen_string_literal: true

module AppExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Exception, with: :unhandled_exception_handler
    rescue_from ActiveRecord::RecordNotFound, with: :runtime_record_not_found_handler
    rescue_from ActionController::RoutingError, with: :routing_error_handler
    rescue_from ActionController::InvalidAuthenticityToken, with: :bad_auth_token
    rescue_from ActionController::UnknownFormat, with: :bad_format_handler
    rescue_from FphsException, with: :fphs_app_exception_handler
    rescue_from ActiveRecord::RecordInvalid, with: :validation_failed
    rescue_from FphsNotAuthorized, with: :not_authorized
    rescue_from FphsGeneralError, with: :general_error
    rescue_from FphsNotFound, with: :resource_not_found
    rescue_from ESignature::ESignatureException, with: :fphs_app_exception_handler
    rescue_from ESignature::ESignatureUserError, with: :user_error_handler
    rescue_from PG::RaiseException, with: :fphs_app_exception_handler
    rescue_from ActionDispatch::Cookies::CookieOverflow, with: :cookie_overflow_handler
    rescue_from PG::UniqueViolation, with: :db_unique_violation
    rescue_from RuntimeError, with: :runtime_error_handler
  end

  def child_error_reporter
    render 'layouts/child_error_reporter'
  end

  protected

  def exceptions_logger
    @@exceptions_logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}-exceptions.log")
  end

  def log_exception(error)
    return if Rails.env.production?

    exceptions_logger.error(error)
    exceptions_logger.error(error.short_string_backtrace) if error.backtrace
  end

  #
  # Consistent flash handling, to avoid long messages from
  # overloading the header length passed to the client.
  # @param [String] message The message to display
  # @param [Symbol] level The flash level (e.g. :info, :warning, :danger)
  def flash_this_now(message, level = :info)
    flash.now[level] = message.to_s[0..2000]
  end

  #
  # General method for showing errors, either as plain text or as an error page
  def show_error(title, status, text: nil, flash_level: nil)
    flash_level ||= :danger
    Rails.logger.warn("AppExceptionHandler.show_error (#{flash_level}): #{title} (#{status})\n#{text}")
    Rails.logger.warn(short_string_backtrace(caller))
    text = text.to_s[0..2000] if text

    if request.format == :html
      @error_title = title
      render 'layouts/error_page', status:, locals: { text: }
    else
      flash_this_now(title, flash_level)
      msg = title
      msg = "#{title} - #{text}" if text
      render plain: msg, status:
    end
  end

  def not_authorized
    show_error 'You are not authorized to perform the requested action', :unauthorized
  end

  def not_editable
    show_error "This item can't be edited", 401
  end

  def not_creatable
    show_error "This item can't be created", 403
  end

  def not_found
    flash_this_now('Requested information not found', :danger)
    routing_error_handler ActionController::RoutingError.new('Not Found')
  end

  def bad_request
    show_error 'The request failed to validate', 422
  end

  def update_out_of_date(prev_at, submitted_at)
    dates = "stored record: #{prev_at} <> submitted record #{submitted_at}"
    show_error "The submitted record doesn't match the latest one - will not update (#{dates})", 422
  end

  def unexpected_error(msg)
    show_error 'An error occurred', 400, text: msg
  end

  def general_error(msg, level = :info)
    show_error 'Error', 400, text: msg, flash_level: level
  end

  def db_unique_violation(error)
    msg = error.message
    msg = msg.gsub('  ', ' ').split('DETAIL: Key ').last.gsub('(', ' ').gsub(')', ' ').gsub('_', ' ')
    code = 400
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def unhandled_exception_handler(error)
    msg = "An unexpected error occurred. Contact the administrator if this condition persists.\n#{error.message}"
    code = 500
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def fphs_app_exception_handler(error)
    msg = error.message
    code = 400
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def validation_failed(error)
    msg = error.message.sub('invalid_error_message:', '- ')
    code = 400
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def user_error_handler(error)
    msg = error.message
    code = 400
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def runtime_error_handler(error)
    msg = "A server error occurred. Contact the administrator if this condition persists. #{error.message}"
    code = 500
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def routing_error_handler(error)
    msg = 'The request URL does not exist.'
    code = 404
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def resource_not_found(error)
    msg = 'The request resource was not found.'
    code = 404
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def bad_format_handler(error)
    msg = 'A bad page format was requested'
    code = 400
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def bad_auth_token(error)
    msg = 'The information could not be submitted. Copy any important text from the fields or text editors ' \
          'of your form, then open this page in a new tab, edit the form and re-enter any missing information.'
    code = 422
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def runtime_record_not_found_handler(error)
    msg = "A database record was not found. Contact the administrator if this condition persists. #{error.message}"
    code = 404
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def return_and_log_error(error, msg, code, log_level: nil)
    log_level ||= :error
    logger.send(log_level, error.inspect)
    logger.send(log_level, error.short_string_backtrace) if error.backtrace
    log_exception(error)

    if code.in? [400, 500]
      user_id = current_user&.id
      admin_id = current_admin&.id
      if Rails.env.production?
        Admin::ExceptionLog.create message: msg || 'error',
                                   main: error.inspect,
                                   backtrace: error.short_string_backtrace,
                                   user_id:,
                                   admin_id:
      end
    end

    if performed?
      flash_this_now(msg[0..2000], :danger)
      return true
    end
    errors = { error: [msg] }
    response.headers['X-Upload-Errors'] = errors.to_json

    respond_to do |type|
      type.html do
        raise ActiveRecord::RecordNotFound if code == 404 && !request.xhr?

        render 'layouts/error_page', locals: { text: msg, status: code }, status: code
      end
      type.json do
        render json: { message: msg }, status: code
      end
      # For some errors the request suddenly gets interpreted as Javascript and breaks the errors on the front end
      type.js do
        render plain: msg, status: code, content_type: 'text/plain'
      end
      # special handling for CSV failures as they open new windows
      type.csv do
        flash_this_now(msg, :danger)
        redirect_to child_error_reporter_path
      end
      type.all do
        render plain: msg, status: code, content_type: 'text/plain'
      end
    end
    true
  rescue ActionController::RespondToMismatchError => e
    # This error is raised when the response format does not match any of the requested formats.
    # Catch it so we can send a useful response.
    render plain: msg, status: code, content_type: 'text/plain'
    true
  end

  def short_string_backtrace(from_caller)
    ExceptionExtensions.short_string_backtrace(from_caller)
  end
end
