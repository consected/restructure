# frozen_string_literal: true

module NfsStore
  module InNfsStoreContainer
    extend ActiveSupport::Concern

    included do
      before_action :find_container
    end

    private

    def find_container
      if request.post? || request.patch? || request.put?
        alid = secure_params[:activity_log_id]
        altype = secure_params[:activity_log_type]
        cid = secure_params[:container_id]
      else
        alid = params[:activity_log_id]
        altype = params[:activity_log_type]
        cid = params[:id]
      end

      if alid.present? && altype.present?
        if altype.start_with?('activity_log_')
          @activity_log = ActivityLog.open_activity_log altype, alid, current_user
        else
          unless altype.in? Settings::FilestoreAdminResourceNames
            raise FphsException, "invalid resource type for altype: #{altype}"
          end

          altype = Settings::FilestoreAdminResourceNames.find { |r| r == altype } # ensure Brakeman doesn't complain
          @activity_log = altype.singularize.ns_camelize.ns_constantize.find(alid)
          @activity_log.current_user = current_user
        end
      end

      @container = if @set_container_from_activity_log
                     NfsStore::Manage::Container.referenced_container(@activity_log)
                   else
                     Browse.open_container id: cid, user: current_user
                   end

      @master = @container.master
      @master.current_user ||= current_user

      if @activity_log
        @container.parent_item = @activity_log

        activity_log_for_container_access
      end

      @container
    end

    #
    # Get all the activity logs that may reference this container.
    # If the activity log specified in the request matches one of these, use it to control
    # access to the container.
    # Otherwise, if the first one has the option {nfs_store: {always_use_this_for_access_control: true} }
    # then use that activity log to control the access to the container.
    def activity_log_for_container_access
      al_id = @activity_log.id
      al_cname = @activity_log.class.to_s

      # Match the specified activity log against a referenced item
      refs = ModelReference.find_where_referenced_from(@container)
      in_refs = refs.find { |r| r.from_record_id == al_id && r.from_record_type == al_cname }
      return @activity_log if in_refs

      # No match, so try the first reference to see if it has the nfs_store option
      from_al = refs.first.from_record
      use_this_for_access = from_al.option_type_config.nfs_store&.dig(:always_use_this_for_access_control)
      raise FsException::List, 'Container and Activity Log do not match' unless use_this_for_access

      @activity_log = from_al
    end

    def use_secure_view
      current_user.can?(:view_files_as_image) || current_user.can?(:view_files_as_html)
    end
  end
end
