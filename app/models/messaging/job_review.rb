module Messaging
  class JobReview < Delayed::Job

    scope :index, -> { limit 10 }

    attr_accessor :disabled, :admin_id

    # @param job [ActiveRecord::ResultSet] all the jobs to fix
    def restart_failed_jobs jobs
      jobs.each do |job|
        next unless job.failed?
        job.update! attempts: 0, failed_at: nil, locked_at: nil, last_error: nil, locked_by: nil
      end
    end

    def current_admin= admin
    end

  end
end
