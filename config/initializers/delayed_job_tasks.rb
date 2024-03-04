# frozen_string_literal: true

# Run the recurring jobs of each type of *RefreshTask
# if any of them are in the database, identified by a specific handler string
Rails.application.configure do
  config.after_initialize do
    if ActiveRecord::Base.connection.table_exists? :delayed_jobs

      class Delayed::Job
        include DelayedJobExtras
      end

      if Settings.bulk_msg_app
        res = Delayed::Job.lookup_jobs_by(class_name: 'SmsDeliveryStatusRefreshTask', queue: 'recurring-tasks')
        if res.empty?
          Rails.logger.info 'Scheduling the SMS delivery refresh task'
          SmsDeliveryStatusRefreshTask.schedule!
        end

        res = Delayed::Job.lookup_jobs_by(class_name: 'PhoneTypeRefreshTask', queue: 'recurring-tasks')
        if res.empty?
          Rails.logger.info 'Scheduling the phone type refresh task'
          PhoneTypeRefreshTask.schedule!
        end

        res = Delayed::Job.lookup_jobs_by(class_name: 'ZeusShortLinkClick', queue: 'recurring-tasks')
        if res.empty?
          Rails.logger.info 'Scheduling the short link click refresh task'
          ShortLinkClicksRefreshTask.schedule!
        end

        res = Delayed::Job.lookup_jobs_by(class_name: 'SmsOptOutRefreshTask', queue: 'recurring-tasks')
        if res.empty?
          Rails.logger.info 'Scheduling the SMS opt out refresh task'
          SmsOptOutRefreshTask.schedule!
        end
      end

    end
  end
end
