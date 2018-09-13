module NfsStore
  class ContainerListController < NfsStoreController

    include InNfsStoreContainer

    def show
      
      begin
        if @container.readable?
          @downloads = Browse.list_files_from @container
          # Prep a download object to allow selection of downloads in the browse list
          @download = Download.new(container: @container)
        end

      rescue FsException::NotFound
        @directory_not_found = true
      end
      render partial: 'browse_list'

    end

    # Hook allowing the class to be reopened safely in the initializers
    ActiveSupport.run_load_hooks(:nfs_store_container_list_controller, self)

  end
end
