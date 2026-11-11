# frozen_string_literal: true

module Messaging
  class MessageNotificationsController < UserBaseController
    before_action :set_accessible_master

    def show
      return not_authorized unless current_user.has_access_to?(:read, :table, :message_notifications)

      @tracker_history = TrackerHistory.find_by(
        master_id: @master.id,
        item_type: MessageNotification.name,
        item_id: params[:id]
      )
      return not_authorized unless @tracker_history

      @notification = MessageNotification.find(params[:id])

      render partial: 'messaging/message_notifications/preview',
             locals: { notification: @notification, tracker_history: @tracker_history }
    end

    private

    def set_accessible_master
      @master = Master.find(params[:master_id])
      @master.current_user = current_user
      not_authorized unless @master.allows_user_access
    end
  end
end
