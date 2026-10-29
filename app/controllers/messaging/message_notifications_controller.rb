# frozen_string_literal: true

module Messaging
  class MessageNotificationsController < UserBaseController
    before_action :set_accessible_master

    def show
      return head :forbidden unless current_user.has_access_to?(:read, :table, :message_notifications)

      notification_id = Integer(params[:id], 10)
      @tracker_history = TrackerHistory.find_by(
        master_id: @master.id,
        item_type: MessageNotification.name,
        item_id: notification_id
      )
      return head :not_found unless @tracker_history

      @notification = MessageNotification.find_by(id: notification_id)
      return head :not_found unless @notification

      render partial: 'messaging/message_notifications/preview',
             locals: { notification: @notification, tracker_history: @tracker_history }
    rescue ArgumentError, TypeError
      head :not_found
    end

    private

    def set_accessible_master
      master_id = Integer(params[:master_id], 10)
      @master = Master.find(master_id)
      @master.current_user = current_user
      return if @master.allows_user_access

      head :not_found
    rescue ActiveRecord::RecordNotFound, ArgumentError, TypeError
      head :not_found
    end
  end
end
