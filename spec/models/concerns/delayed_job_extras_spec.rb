# frozen_string_literal: true

require 'rails_helper'

# Tests for DelayedJobExtras#find_by_job_id and #lookup_jobs_by.
#
# These specs cover issue #1232 ("Admin Job ID search no longer works").
# The admin "Job UUID" search field and the job failure notification email
# both rely on Delayed::Job.find_by_job_id to locate a Delayed::Job record
# from the ActiveJob job_id embedded in its serialized `handler` YAML.
#
# The existing implementation builds a single LIKE pattern by concatenating
# fragments in a fixed order (job_id fragment, then job_class fragment, then
# ref_record fragment), which:
#   1. requires the job_id fragment to appear *before* the job_class fragment
#      in the handler YAML, even though real ActiveJob handlers always
#      serialize job_class before job_id - so combining job_class: and
#      job_id: in a single lookup can never match.
#   2. requires the job_id key to be indented by exactly two spaces on the
#      line immediately following the wildcard, making the match fragile to
#      any change in how the handler YAML is indented/nested.
#
# These specs demonstrate both problems and confirm the fix makes job_id
# lookups resilient to handler formatting differences.
RSpec.describe DelayedJobExtras do
  before :all do
    # DelayedJobExtras is normally included inside config.after_initialize in
    # delayed_job_tasks.rb. In isolated model specs the initializer may not have
    # run, so we include it here to ensure the class methods are available.
    Delayed::Job.include DelayedJobExtras unless Delayed::Job.include?(DelayedJobExtras)
  end

  def create_job_with_handler(handler)
    Delayed::Job.create!(handler: handler, run_at: 1.hour.from_now)
  end

  describe '.find_by_job_id' do
    it 'finds a job from a realistic ActiveJob delayed_job handler' do
      job_id = SecureRandom.uuid
      other_job_id = SecureRandom.uuid
      handler = <<~YAML
        --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: SomeTestJob
          job_id: #{job_id}
          provider_job_id:
          queue_name: default
          priority:
          arguments: []
          executions: 0
      YAML
      other_handler = <<~YAML
        --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: SomeTestJob
          job_id: #{other_job_id}
      YAML

      job = create_job_with_handler(handler)
      other_job = create_job_with_handler(other_handler)

      found = Delayed::Job.find_by_job_id(job_id)
      expect(found&.id).to eq(job.id)
      expect(found&.id).not_to eq(other_job.id)
    end

    it 'does not find a job when given an unrelated job_id' do
      job_id = SecureRandom.uuid
      handler = <<~YAML
        --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: SomeTestJob
          job_id: #{job_id}
      YAML
      create_job_with_handler(handler)

      found = Delayed::Job.find_by_job_id(SecureRandom.uuid)
      expect(found).to be_nil
    end

    it 'finds a job regardless of the indentation depth of the job_id key' do
      # The old implementation hard-coded a two-space indent in the LIKE pattern.
      # The fix uses a flexible substring match, so deeper nesting still works.
      job_id = SecureRandom.uuid
      handler = <<~YAML
        --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          nested:
            job_class: SomeTestJob
            job_id: #{job_id}
      YAML

      job = create_job_with_handler(handler)

      found = Delayed::Job.find_by_job_id(job_id)
      expect(found&.id).to eq(job.id)
    end
  end

  describe '.lookup_jobs_by' do
    it 'finds a job when both job_class and job_id are provided, matching real handler key order' do
      # The old implementation required job_id: to appear before job_class: in the
      # LIKE pattern, but ActiveJob always serializes job_class before job_id.
      job_id = SecureRandom.uuid
      handler = <<~YAML
        --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: SomeTestJob
          job_id: #{job_id}
      YAML

      job = create_job_with_handler(handler)

      res = Delayed::Job.lookup_jobs_by(job_class: 'SomeTestJob', job_id: job_id)
      expect(res.pluck(:id)).to include(job.id)
    end

    it 'finds a job by class_name prefix (used by recurring task initialization in delayed_job_tasks.rb)' do
      # These lookups use class_name: to check whether a recurring task is already
      # scheduled, matching the leading YAML object tag of the handler.
      handler_match = "--- !ruby/object:SmsDeliveryStatusRefreshTask\nsome_field: value\n"
      handler_other = "--- !ruby/object:PhoneTypeRefreshTask\nsome_field: value\n"

      job_match = create_job_with_handler(handler_match)
      job_other = create_job_with_handler(handler_other)

      res = Delayed::Job.lookup_jobs_by(class_name: 'SmsDeliveryStatusRefreshTask')
      expect(res.pluck(:id)).to include(job_match.id)
      expect(res.pluck(:id)).not_to include(job_other.id)
    end

    it 'finds a job by job_class and ref_record together (used by Redcap::ProjectAdmin.existing_jobs)' do
      # The handler uses '- _aj_globalid:' (YAML list-item syntax). The LIKE pattern
      # intentionally includes the '- ' prefix so that '_' is not a wildcard.
      handler = <<~YAML
        --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: SomeTestJob
          arguments:
          - _aj_globalid: gid://#{Settings::GlobalIdPrefix}/Admin::AppType/42
      YAML

      job = create_job_with_handler(handler)
      ref_record = instance_double('Admin::AppType', class: Admin::AppType, id: 42)

      res = Delayed::Job.lookup_jobs_by(job_class: 'SomeTestJob', ref_record: ref_record)
      expect(res.pluck(:id)).to include(job.id)
    end
  end
end
