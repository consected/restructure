class HandleMessageNotificationJob < ApplicationJob

  # retry_on FphsException
  queue_as :default

  def perform(mn)

    puts "Performing job on #{mn.inspect}"
    mn.handle_notification_now logger: Delayed::Worker.logger

  end
end
