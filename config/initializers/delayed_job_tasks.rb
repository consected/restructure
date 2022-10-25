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
        # Optionally, return only failed items if failed: true, or not yet failed items if failed: false
        # @param [String] class_name
        # @param [String] queue
        # @param [true | false | nil] locked
        # @param [true | false | nil] failed
        # @return [ActiveRecord::Relation]
        def self.lookup_jobs_by_class(class_name, queue: 'default', locked: nil, failed: nil)
          res = Delayed::Job.where(queue: queue)
                            .where(['handler LIKE ?', "--- !ruby/object:#{class_name}%"])
          res = res.where('locked_at IS NOT NULL') if locked
          res = res.where('locked_at IS NULL') if locked == false
          res = res.where('failed_at IS NOT NULL') if failed
          res = res.where('failed_at IS NULL') if failed == false
          res
        end

        #
        # Look up jobs by handler containing the specified text, in a queue (default: default).
        # Optionally, return only locked items if locked: true, or unlocked items if locked: false
        # Optionally, return only failed items if failed: true, or not yet failed items if failed: false
        # @param [String] class_name
        # @param [String] queue
        # @param [true | false | nil] locked
        # @param [true | false | nil] failed
        # @return [ActiveRecord::Relation]
        def self.handler_includes(text, queue: 'default', locked: nil, failed: nil)
          res = Delayed::Job.where(queue: queue)
                            .where((['handler LIKE ?', "%#{text}%"]))
          res = res.where('locked_at IS NOT NULL') if locked
          res = res.where('locked_at IS NULL') if locked == false
          res = res.where('failed_at IS NOT NULL') if failed
          res = res.where('failed_at IS NULL') if failed == false
          res
        end
      end

      if Settings.bulk_msg_app
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
end
