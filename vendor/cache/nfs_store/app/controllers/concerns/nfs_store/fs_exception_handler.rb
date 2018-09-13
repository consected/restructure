module NfsStore
  module FsExceptionHandler

    extend ActiveSupport::Concern

    included do
      rescue_from FsException::NoAccess, with: :fs_app_exception_no_access
      rescue_from FsException::NotFound, with: :fs_app_exception_not_found
      rescue_from FsException::Action, with: :fs_app_exception_handler
      rescue_from FsException::Download, with: :fs_app_exception_handler
      rescue_from FsException::File, with: :fs_app_exception_handler
      rescue_from FsException::List, with: :fs_app_exception_handler
      rescue_from FsException::Filesystem, with: :fs_app_exception_handler
      rescue_from FsException::Upload, with: :fs_app_exception_handler
      rescue_from FsException::FilenameExists, with: :fs_app_exception_handler
    end


    def fs_app_exception_handler e
      msg = e.message
      code = 400
      return_and_log_error e, msg, code
    end
    def fs_app_exception_no_access e
      msg = e.message
      code = 401
      return_and_log_error e, msg, code
    end
    def fs_app_exception_not_found e
      msg = e.message
      code = 404
      return_and_log_error e, msg, code
    end

  end
end
