module NfsStore
  #
  # Handle the file list viewing for a container.
  # Lists are returned based on the view_type requested, currently:
  # - list
  # - icons
  # The content of the list is a full directory structure of files with their metadata
  # and information that allows them to be downloaded or viewed.
  class ContainerListController < NfsStoreController
    include ModelNaming
    include ControllerUtils
    include AppExceptionHandler
    include UserActionLogging
    include MasterHandler
    include InNfsStoreContainer

    ValidViewTypes = %w[list icons].freeze
    DefaultViewType = 'list'.freeze

    #
    # Show the main list container
    def show
      setup_download_list
      render partial: "browse_#{view_type}"
    end

    #
    # Return the file list content as JSON for rendering in the list container
    # The actual metadata returned varies based on the view_type requested,
    # in order to speed up large directories
    def content
      setup_download_list

      except_list = case view_type
                    when 'icons'
                      %i[file_metadata last_process_name_run updated_at created_at user_id file_hash
                         content_type nfs_store_stored_file_id]
                    else
                      %i[file_metadata last_process_name_run description updated_at created_at user_id file_hash
                         content_type nfs_store_stored_file_id]
                    end

      extras = {
        except: except_list,
        allow_show_flags: @allow_show_flags,
        limited_results: true
      }

      tfa = @container.user_file_actions_config&.map { |a| a[:id] }

      ff = NfsStore::Filter::Filter.human_filters_for(@activity_log)

      dl_json = @downloads.as_json(extras)

      render json: {
        nfs_store_container: {
          id: @container.id,
          name: @container.name,
          container_files: dl_json,
          item_type: 'nfs_store_container',
          writeable: @container.writable?,
          readable: @container.readable?,
          can_download_or_view: @container.can_download_or_view?,
          can_download: @container.can_download?,
          can_send_to_trash: @container.can_send_to_trash?,
          can_move_files: @container.can_move_files?,
          can_rename_files: @container.can_move_files?,
          can_rename_folders: @container.can_move_files?,
          can_user_file_actions: @container.can_user_file_actions?,
          parent_type: @activity_log.class.to_s.ns_underscore,
          parent_id: @activity_log.id,
          parent_sk: @activity_log.respond_to?(:secondary_key) && @activity_log.secondary_key,
          master_id: @activity_log.master_id,
          trigger_file_action_ids: tfa,
          directory_not_found: @directory_not_found,
          filters_for: ff,
          view_options: @container.view_options
        }
      }
    end

    protected

    #
    # Type of filestore browser requested
    def view_type
      @view_type = ValidViewTypes.find { |vt| vt == params[:view_type] } || DefaultViewType
    end

    #
    # Setup the list of download file items, handling item flags if needed.
    # Also add a @download object, required to build the download selection form.
    def setup_download_list
      return unless @container.readable?

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
    rescue FsException::NotFound
      @directory_not_found = true
    end

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
