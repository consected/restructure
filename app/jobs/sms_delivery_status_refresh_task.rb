class SmsDeliveryStatusRefreshTask
  include Delayed::RecurringJob
  run_every 10.minutes

  queue 'recurring-tasks'

  def perform
    DynamicModel::ZeusBulkMessageStatus.add_status_from_log
  end
end
