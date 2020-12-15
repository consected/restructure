module NfsStore
  class ContainerListController < NfsStoreController
    include ModelNaming
    include ControllerUtils
    include AppExceptionHandler
    include UserActionLogging
    include MasterHandler
    include InNfsStoreContainer

    ValidViewTypes = %w[list icons].freeze
    DefaultViewType = 'list'.freeze

    def show
      view_type = params[:view_type]

      begin
        if @container.readable?
          @downloads = Browse.list_files_from @container, activity_log: @activity_log
          # Prep a download object to allow selection of downloads in the browse list
          @download = Download.new container: @container, activity_log: @activity_log
        end
      rescue FsException::NotFound
        @directory_not_found = true
      end

      view_type = ValidViewTypes.find { |vt| vt == view_type } || DefaultViewType
      render partial: "browse_#{view_type}"
    end

    protected

    # return the class for the current item
    # handles namespace if the item is like an ActivityLog:Something
    def primary_model
      NfsStore::Manage::Container
    end

    def object_name
      'container'
    end

    # notice the double underscore for namespaced models to indicate the delimiter
    # to remain consistent with the associations
    def full_object_name
      'nfs_store__manage__container'
    end

    # the association name from master to these objects
    # for example player_contacts or activity_log__player_contacts_phones
    # notice the double underscore for namespaced models to indicate the delimiter
    def objects_name
      :nfs_store__manage__containers
    end

    def human_name
      'Container'
    end
  end
end
