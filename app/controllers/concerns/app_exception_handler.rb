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
    rescue_from FphsNotAuthorized, with: :not_authorized
    rescue_from FphsGeneralError, with: :general_error
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

  #
  # General method for showing errors, either as plain text or as an error page
  def show_error(title, status, text: nil, flash_level: nil)
    text = text.to_s[0..2000] if text

    flash_level ||= :danger
    flash[flash_level] = title
    if request.format == :html
      @error_title = title
      render 'layouts/error_page', status: status, locals: { text: text }
    else
      msg = title
      msg = "#{title} - #{text}" if text
      render plain: msg, status: status
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
    flash[:danger] = 'Requested information not found'
    routing_error_handler ActionController::RoutingError.new('Not Found')
  end

  def bad_request
    show_error 'The request failed to validate', 422
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
    msg = "An unexpected error occurred. Contact the administrator if this condition persists. #{error.message}"
    code = 500
    return_and_log_error error, msg, code, log_level: Settings::LogLevel[__method__]
  end

  def fphs_app_exception_handler(error)
    msg = error.message
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
    logger.send(log_level, error.backtrace.join("\n")) if error.backtrace

    if code.in? [400, 500]
      user_id = current_user&.id
      admin_id = current_admin&.id
      if Rails.env.production?
        Admin::ExceptionLog.create message: (msg || 'error'),
                                   main: error.inspect,
                                   backtrace: error.backtrace.join("\n"),
                                   user_id: user_id,
                                   admin_id: admin_id
      end
    end

    if performed?
      flash[:danger] = msg[0..2000]
      return true
    end
    errors = { error: [msg] }
    response.headers['X-Upload-Errors'] = errors.to_json

    respond_to do |type|
      type.html do
        render 'layouts/error_page', locals: { text: msg, status: code }, status: code
      end
      type.json do
        render json: { message: msg }, status: code
      end
      # For some errors the request suddenly gets interpreted as Javascript and breaks the errors on the front end
      type.js  do
        render plain: msg, status: code, content_type: 'text/plain'
      end
      # special handling for CSV failures as they open new windows
      type.csv do
        flash[:danger] = msg[0..2000]
        redirect_to child_error_reporter_path
      end
      type.all do
        render plain: msg, status: code, content_type: 'text/plain'
      end
    end
    true
  end
end
