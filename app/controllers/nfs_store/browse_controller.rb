module NfsStore
  #
  # Controller to support a standalone full page file browser. Not used within ReStructure
  # applications, and may not even work. Consider removing in the future.
  class BrowseController < NfsStoreController
    include InNfsStoreContainer
    helper_method :use_secure_view

    def show
      render 'show'
    end
  end
end
