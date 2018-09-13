module AppExceptionHandler
  extend ActiveSupport::Concern

  included do
  end


  protected


    def return_and_log_error e, msg, code
      logger.error e.inspect
      logger.error e.backtrace.join("\n")

      if performed?
        flash[:danger] = msg[0..2000]
        return true
      end
      errors = { error: [msg] }
      response.headers['X-Upload-Errors'] = errors.to_json

      respond_to do |type|
        type.html {
          render 'layouts/error_page', locals: {text: msg, status: code}, status: code
        }
        type.json  {
          render :json => {message: msg}, status: code
        }
        # For some errors the request suddenly gets interpreted as Javascript and breaks the errors on the front end
        type.js  {
          render :text => msg, status: code, content_type: 'text/plain'
        }

      end
      true
    end

end
