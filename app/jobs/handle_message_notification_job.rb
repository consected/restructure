# Queue a message notification job, either email or sms
class HandleMessageNotificationJob < ApplicationJob
  # retry_on FphsException
  queue_as :default

  def perform(message_notification, for_item: nil, on_complete_config: nil)
    puts "Performing job on #{message_notification.inspect}" unless Rails.env.test?
    message_notification.handle_notification_now logger: Delayed::Worker.logger,
                                                 for_item: for_item,
                                                 on_complete_config: on_complete_config
  end
end
