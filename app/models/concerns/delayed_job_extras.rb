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
      res = Delayed::Job.where(['handler LIKE ?', "--- !ruby/object:#{class_name}%"]) if class_name
      res ||= Delayed::Job.all

      # Each of the following attributes is matched independently, rather than
      # requiring all of them to appear consecutively in a single fixed order.
      # This avoids depending on the exact order that keys are serialized in
      # the handler YAML, and on the exact indentation/nesting used, both of
      # which are implementation details of ActiveJob/Psych serialization that
      # can change between versions (see issue #1232).
      res = res.where(['handler LIKE ?', "%job_id: #{job_id}%"]) if job_id
      res = res.where(['handler LIKE ?', "%job_class: #{job_class}%"]) if job_class

      if ref_record
        # Prefix with '- ' (the YAML list-item marker that always precedes _aj_globalid)
        # to avoid the leading underscore being treated as a SQL LIKE single-character wildcard.
        res = res.where(['handler LIKE ?',
                         "%- _aj_globalid: gid://#{Settings::GlobalIdPrefix}/#{ref_record.class}/#{ref_record.id}%"])
      end

      res = res.where(queue: queue) if queue
      res = res.where('locked_at IS NOT NULL') if locked
      res = res.where('locked_at IS NULL') if locked == false
      res = res.where('failed_at IS NOT NULL') if failed
      res = res.where('failed_at IS NULL') if failed == false
      res
    end
  end
end
