module AppExceptionHandler
  extend ActiveSupport::Concern

  included do
  end

  def child_error_reporter
    render 'layouts/child_error_reporter'
  end


  protected

    def db_unique_violation e
      msg = e.message
      msg = msg.gsub('  ',' ').split('DETAIL: Key ').last.gsub('(',' ').gsub(')',' ').gsub('_',' ')
      code = 400
      return_and_log_error e, msg, code
    end

    def unhandled_exception_handler e
      msg = "An unexpected error occurred. Contact the administrator if this condition persists. #{e.message}"
      code = 500
      return_and_log_error e, msg, code
    end

    def fphs_app_exception_handler e
      msg = e.message
      code = 400
      return_and_log_error e, msg, code
    end

    def runtime_error_handler e
      msg = "A server error occurred. Contact the administrator if this condition persists. #{e.message}"
      code = 500
      return_and_log_error e, msg, code
    end

    def routing_error_handler e
      msg = "The request URL does not exist."
      code = 404
      return_and_log_error e, msg, code
    end

    def bad_auth_token e
      msg = "The information could not be submitted. Try returning to the home page to refresh the session."
      code = 422
      return_and_log_error e, msg, code
    end

    def runtime_record_not_found_handler e
      msg = "A database record was not found. Contact the administrator if this condition persists. #{e.message}"
      code = 404
      return_and_log_error e, msg, code
    end

    def return_and_log_error e, msg, code
      logger.error e.inspect
      logger.error e.backtrace.join("\n")

      if code.in? [400, 500]
        user_id = current_user&.id
        admin_id = current_admin&.id
        Admin::ExceptionLog.create message: (msg || 'error'), main: e.inspect, backtrace: e.backtrace.join("\n"), user_id: user_id, admin_id: admin_id
      end

      if performed?
        flash[:danger] = msg[0..2000]
        return true
      end
      respond_to do |type|
        type.html { render 'layouts/error_page', locals: {text: msg, status: code}, status: code }
        type.json  { render :json => {message: msg}, status: code }
        # For some errors the request suddenly gets interpreted as Javascript and breaks the errors on the front end
        type.js  { render :text => msg, status: code, content_type: 'text/plain'  }
        # special handling for CSV failures as they open new windows
        flash[:danger] = msg[0..2000]
        type.csv { redirect_to child_error_reporter_path }
      end
      true
    end

end
