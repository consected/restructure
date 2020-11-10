# Queue a message notification job, either email or sms
class HandleMessageNotificationJob < ApplicationJob

  # retry_on FphsException
  queue_as :default

  def perform(mn, for_item: nil, on_complete_config: nil)

    puts "Performing job on #{mn.inspect}"
    mn.handle_notification_now logger: Delayed::Worker.logger, for_item: for_item, on_complete_config: on_complete_config

  end
end
