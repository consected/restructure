class SmsDeliveryStatusRefreshTask
  include Delayed::RecurringJob
  run_every 2.hours

  queue 'recurring-tasks'

  def perform
    DynamicModel::ZeusBulkMessageStatus.add_status_from_log
  end
end
