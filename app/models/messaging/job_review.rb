# frozen_string_literal: true

# A breaking change in delayed_job causes the Delayed::Job constant not to be
# defined until late in the load process. This means it can't be inherited, breaking
# the server startup.
# Although not a perfect option, wait until initialization has completed before
# defining this class
Rails.application.configure do
  config.after_initialize do
    module Messaging
      class JobReview < Delayed::Job
        ValidQueues = %w[default nfs_store_process recurring-tasks redcap batch].freeze

        scope :limited_index, -> { limit 100 }
        scope :all_failed, -> { where.not(failed_at: nil) }

        attr_accessor :disabled, :admin_id

        after_save :delete_job, if: -> { queue == 'delete' }

        #
        # Restart all the failed jobs in the current scope
        # @return [Integer] - number of jobs restarted
        def self.restart_failed_jobs!
          jobs = all_failed
          res = 0
          jobs.each do |job|
            next unless job.failed?

            job.update! attempts: 0, failed_at: nil, locked_at: nil, last_error: nil, locked_by: nil
            res += 1
          end

          res
        end

        def current_admin=(admin)
          # Accept anything
        end

        #
        # Provide a mechanism for deleting jobs that have failed permanently (for example)
        # If the queue is set to "delete" after saving, delete this
        def delete_job
          delete
        end
      end
    end
  end
end
