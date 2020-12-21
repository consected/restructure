# frozen_string_literal: true

module Messaging
  class JobReview < Delayed::Job
    scope :limited_index, -> { limit 100 }

    attr_accessor :disabled, :admin_id

    # @param job [ActiveRecord::Relation] all the jobs to fix
    def restart_failed_jobs(jobs)
      jobs.each do |job|
        next unless job.failed?

        job.update! attempts: 0, failed_at: nil, locked_at: nil, last_error: nil, locked_by: nil
      end
    end

    def current_admin=(admin); end
  end
end
