# Run the recurring jobs
if ActiveRecord::Base.connection.table_exists? :delayed_jobs

  class Delayed::Job
    def self.lookup_jobs_by_class class_name, queue: 'default'
      Delayed::Job.where(queue: queue).where("handler LIKE '--- !ruby/object:#{class_name}%'")
    end
  end

  res = Delayed::Job.lookup_jobs_by_class('SmsDeliveryStatusRefreshTask', queue: 'recurring-tasks')

  if res.length == 0
    Rails.logger.info "Scheduling the SMS delivery refresh task"
    SmsDeliveryStatusRefreshTask.schedule!
  end

  res = Delayed::Job.lookup_jobs_by_class('PhoneTypeRefreshTask', queue: 'recurring-tasks')

  if res.length == 0
    Rails.logger.info "Scheduling the phone type refresh task"
    PhoneTypeRefreshTask.schedule!
  end

end
