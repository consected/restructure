module NfsStore
  class BrowseController < NfsStoreController

    include InNfsStoreContainer

    def show
      render 'show'
    end

  end
end
