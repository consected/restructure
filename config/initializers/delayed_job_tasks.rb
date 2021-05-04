# frozen_string_literal: true

# Run the recurring jobs of each type of *RefreshTask
# if any of them are in the database, identified by a specific handler string
Rails.application.configure do
  config.after_initialize do
    if ActiveRecord::Base.connection.table_exists? :delayed_jobs

      class Delayed::Job
        #
        # Look up jobs by class name, in a queue (default: default).
        # Optionally, return only locked items if locked: true, or unlocked items if locked: false
        # @param [String] class_name
        # @param [String] queue
        # @param [true | false | nil] locked
        # @return [ActiveRecord::Relation]
        def self.lookup_jobs_by_class(class_name, queue: 'default', locked: nil)
          res = Delayed::Job.where(queue: queue).where(['handler LIKE ?', "--- !ruby/object:#{class_name}%"])
          res = res.where('locked_at is not null') if locked
          res = res.where('locked_at is null') if locked == false
          res
        end
      end

      res = Delayed::Job.lookup_jobs_by_class('SmsDeliveryStatusRefreshTask', queue: 'recurring-tasks')
      if res.empty?
        Rails.logger.info 'Scheduling the SMS delivery refresh task'
        SmsDeliveryStatusRefreshTask.schedule!
      end

      res = Delayed::Job.lookup_jobs_by_class('PhoneTypeRefreshTask', queue: 'recurring-tasks')
      if res.empty?
        Rails.logger.info 'Scheduling the phone type refresh task'
        PhoneTypeRefreshTask.schedule!
      end

      res = Delayed::Job.lookup_jobs_by_class('ZeusShortLinkClick', queue: 'recurring-tasks')
      if res.empty?
        Rails.logger.info 'Scheduling the short link click refresh task'
        ShortLinkClicksRefreshTask.schedule!
      end

      res = Delayed::Job.lookup_jobs_by_class('SmsOptOutRefreshTask', queue: 'recurring-tasks')
      if res.empty?
        Rails.logger.info 'Scheduling the SMS opt out refresh task'
        SmsOptOutRefreshTask.schedule!
      end

    end
  end
end
