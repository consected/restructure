# Run the recurring jobs

res = Delayed::Job.where(queue: 'recurring-tasks').where("handler LIKE '--- !ruby/object:SmsDeliveryStatusRefreshTask%'")

if res.length == 0
  Rails.logger.info "Scheduling the SMS delivery refresh task"
  SmsDeliveryStatusRefreshTask.schedule!
end
