require_dependency "nfs_store/application_controller"
module NfsStore
  class FsBaseController < ApplicationController
    include AppExceptionHandler
    include FsExceptionHandler

  end

end
