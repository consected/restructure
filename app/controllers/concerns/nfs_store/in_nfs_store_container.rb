module NfsStore
  module InNfsStoreContainer
    extend ActiveSupport::Concern

    included do
      before_action :find_container
    end

    private

      def find_container
        if action_name.in? ['create', 'update']
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
          al_type = altype.ns_camelize
          al_class = ActivityLog.implementation_classes.select {|a| a.to_s == al_type}.first
          raise FsException::List.new "activity log type specified is invalid" unless al_class
          @activity_log = al_class.find(alid)
          @activity_log.current_user = current_user
          raise FsException::NoAccess.new "User does not have access to this activity log" unless @activity_log.allows_current_user_access_to? :access
          # Get all the activity logs that may reference this container. Then check the specified one actually does
          refs = ModelReference.find_where_referenced_from(@container).pluck(:from_record_id, :from_record_type)
          in_refs = refs.select {|r| r.first == @activity_log.id && r.last == al_class.to_s}.first
          raise FsException::List.new "Container and Activity Log do not match" unless in_refs
        end

        @container
      end

  end
end
