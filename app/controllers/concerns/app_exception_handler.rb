module AppExceptionHandler
  extend ActiveSupport::Concern

  included do
  end

  def child_error_reporter
    render 'layouts/child_error_reporter'
  end


  protected

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
      msg = "The information could not be submitted. Try returning to the home page to refresh the page."
      code = 401
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
      respond_to do |type|
        type.html { render :text => msg, :status => code }
        type.json  { render :json => {message: msg}, :status => code }
        # special handling for CSV failures as they open new windows
        flash[:danger] = msg
        type.csv { redirect_to child_error_reporter_path }
      end
      true
    end

end
