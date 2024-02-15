# frozen_string_literal: true

module DelayedJobExtras
  extend ActiveSupport::Concern
  class_methods do
    #
    # Find a job in the specified queue(s) by job_id. Returns nil if nothing matches
    # @param [String] job_id
    # @param [String | Array] queue
    # @return [Delayed::Job | nil]
    def find_by_job_id(job_id, queue: nil)
      Delayed::Job.lookup_jobs_by(job_id: job_id, queue: queue).first
    end

    #
    # Look up jobs by class name, in a queue (default: default).
    # Optionally, return only locked items if locked: true, or unlocked items if locked: false
    # Optionally, return only failed items if failed: true, or not yet failed items if failed: false
    # @param [String] class_name
    # @param [String] queue
    # @param [true | false | nil] locked
    # @param [true | false | nil] failed
    # @param [Class] job_class in handler
    # @param [ActiveRecord] ref_record - record referenced by job
    # @return [ActiveRecord::Relation]
    def lookup_jobs_by(class_name: nil, queue: nil, locked: nil, failed: nil, job_class: nil, ref_record: nil,
                       job_id: nil)
      like_string = "--- !ruby/object:#{class_name}%"

      if job_id
        like_string = <<~END_TEXT
          #{like_string}
            job_id: #{job_id}
          %
        END_TEXT
      end

      if job_class
        like_string = <<~END_TEXT
          #{like_string}
            job_class: #{job_class}
          %
        END_TEXT
      end

      if ref_record
        like_string = <<~END_TEXT
          #{like_string}
            - _aj_globalid: gid://#{Settings::GlobalIdPrefix}/#{ref_record.class}/#{ref_record.id}
          %
        END_TEXT
      end

      res = Delayed::Job.where(['handler LIKE ?', "#{like_string}%"])
      res = res.where(queue: queue) if queue
      res = res.where('locked_at IS NOT NULL') if locked
      res = res.where('locked_at IS NULL') if locked == false
      res = res.where('failed_at IS NOT NULL') if failed
      res = res.where('failed_at IS NULL') if failed == false
      res
    end
  end
end
