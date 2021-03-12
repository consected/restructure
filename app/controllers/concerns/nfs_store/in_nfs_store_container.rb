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

      @container = Browse.open_container id: cid, user: current_user
      @master = @container.master
      @master.current_user ||= current_user

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

        @container.parent_item = @activity_log
        # Get all the activity logs that may reference this container. Then check the specified one actually does
        refs = ModelReference.find_where_referenced_from(@container).pluck(:from_record_id, :from_record_type)
        in_refs = refs.select { |r| r.first == @activity_log.id && r.last == @activity_log.class.to_s }.first
        raise FsException::List, 'Container and Activity Log do not match' unless in_refs
      end

      @container
    end

    def use_secure_view
      current_user.can?(:view_files_as_image) || current_user.can?(:view_files_as_html)
    end
  end
end
