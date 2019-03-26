module NfsStore
  class BrowseController < NfsStoreController

    include InNfsStoreContainer
    helper_method :use_secure_view

    def show
      render 'show'
    end

  end
end
