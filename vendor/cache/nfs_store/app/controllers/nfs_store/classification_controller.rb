module NfsStore
  class ClassificationController < NfsStoreController

    include InNfsStoreContainer

    def edit

      render partial: 'nfs_store/classification/edit'
    end

    def create
      render text: ''
    end

    protected

    # Hook allowing the class to be reopened safely in the initializers
    ActiveSupport.run_load_hooks(:nfs_store_classification_controller, self)

  end
end
