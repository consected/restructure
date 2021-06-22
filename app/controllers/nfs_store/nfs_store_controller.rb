# frozen_string_literal: true

module NfsStore
  #
  # Simple base class for NFsStore filestore related controllers
  # that may return full page results
  class NfsStoreController < FsBaseController
    layout 'nfs_store'
  end
end
