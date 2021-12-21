# frozen_string_literal: true

module NfsStore
  #
  # Controller to support a standalone full page file browser. Not used within ReStructure
  # applications, and may not even work. Consider removing in the future.
  class ClassificationController < NfsStoreController
    # include InNfsStoreContainer
    #
    # def edit
    #
    #   render partial: 'nfs_store/classification/edit'
    # end
    #
    # def create
    #   render plain: ''
    # end
    #
    # protected
    #
    # # Hook allowing the class to be reopened safely in the initializers
    # ActiveSupport.run_load_hooks(:nfs_store_classification_controller, self)
  end
end
