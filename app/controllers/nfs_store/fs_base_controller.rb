# frozen_string_literal: true

module NfsStore
  #
  # Simple base class for NFsStore filestore related controllers
  # not returning full page results
  class FsBaseController < UserBaseController
    include FsExceptionHandler
  end
end
