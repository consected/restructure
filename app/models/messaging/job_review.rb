# frozen_string_literal: true

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

    #
    # Delete all the failed jobs in the current scope
    # @return [Integer] - number of jobs deleted
    def self.delete_failed_jobs!
      jobs = all_failed
      res = 0
      jobs.each do |job|
        next unless job.failed?

        job.delete
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
