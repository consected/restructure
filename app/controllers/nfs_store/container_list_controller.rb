module NfsStore
  class ContainerListController < NfsStoreController
    include ModelNaming
    include ControllerUtils
    include AppExceptionHandler
    include UserActionLogging
    include MasterHandler
    include InNfsStoreContainer

    def show

      begin
        if @container.readable?
          @downloads = Browse.list_files_from @container, activity_log: @activity_log
          # Prep a download object to allow selection of downloads in the browse list
          @download = Download.new container: @container, activity_log: @activity_log
        end

      rescue FsException::NotFound
        @directory_not_found = true
      end
      render partial: 'browse_list'

    end

    # def show_all
    #
    #   @master
    #   begin
    #     if @container.readable?
    #       @downloads = Browse.list_files_from @container, activity_log: @activity_log
    #       # Prep a download object to allow selection of downloads in the browse list
    #       @download = Download.new(container: @container)
    #     end
    #
    #   rescue FsException::NotFound
    #     @directory_not_found = true
    #   end
    #   render partial: 'browse_list'
    #
    # end

    protected

      # def find_container
      #   if action_name.in? ['create', 'update']
      #     cid = secure_params[:container_id]
      #   else
      #     cid = params[:id]
      #   end
      #   @container = Browse.open_container id: cid, user: current_user
      #   @master = @container.master
      #   @master.current_user ||= current_user
      #   @container
      # end


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
