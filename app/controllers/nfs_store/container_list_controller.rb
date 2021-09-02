module NfsStore
  class ContainerListController < NfsStoreController
    include ModelNaming
    include ControllerUtils
    include AppExceptionHandler
    include UserActionLogging
    include MasterHandler
    include InNfsStoreContainer

    ValidViewTypes = %w[list icons json].freeze
    DefaultViewType = 'json'.freeze

    def show
      view_type = params[:view_type]

      begin
        if @container.readable?
          # Check if we should show flags for classifications on each of the types of container file
          @allow_show_flags = {}
          %i[stored_file archived_file].each do |rt|
            full_name = "nfs_store__manage__#{rt}"
            show_flag = !!Classification::ItemFlagName.enabled_for?(full_name, current_user)
            @allow_show_flags[rt] = show_flag
          end

          # List types should we include flags for in the queries that return the stored_files and archived_files
          show_flags_for = @allow_show_flags.filter { |_k, v| v }.keys.map { |i| i.to_s.pluralize.to_sym }
          @downloads = Browse.list_files_from @container, activity_log: @activity_log, include_flags: show_flags_for
          # Prep a download object to allow selection of downloads in the browse list
          @download = Download.new container: @container, activity_log: @activity_log
        end
      rescue FsException::NotFound
        @directory_not_found = true
      end

      view_type = ValidViewTypes.find { |vt| vt == view_type } || DefaultViewType

      if view_type == 'json'
        extras = {
          except: %i[file_metadata last_process_name_run description updated_at created_at user_id file_hash
                     content_type],
          allow_show_flags: @allow_show_flags
        }

        render json: {
          nfs_store_container: {
            id: @container.id,
            container_files: @downloads.as_json(extras),
            item_type: 'nfs_store_container'
          }
        }
        return
      end

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
