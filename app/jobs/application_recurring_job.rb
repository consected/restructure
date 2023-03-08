# frozen_string_literal: true

#
# Base class for recurring jobs that are scheduled through instances
class ApplicationRecurringJob
  include Delayed::RecurringJob

  JobMatchingParam = 'schedule_id'

  #
  # Schedule a new or replace an existing recurring pull
  # @param [ActiveRecord] owner - instance that owns this job
  # @param [Hash | nil] data - to be accessible in the job
  # @param [duration] run_every - schedule
  # @param [DateTime] run_at - first run | defaults to now + run_every
  # @return [Delayed::Job]
  def self.schedule_task(owner, data, run_every: nil, run_at: nil)
    options = {
      job_matching_param: JobMatchingParam,
      schedule_id: owner_identifier(owner)
    }

    options[:run_every] = run_every if run_every
    options[:run_at] = if run_at
                         run_at
                       elsif !run_at
                         DateTime.now + run_every
                       end

    data ||= {}
    data[:owner_instance] = owner_identifier(owner)
    options[:data] = data

    schedule! options
  end

  #
  # Unschedule any existing recurring pulls
  # @param [ActiveRecord] owner - the owner instance
  def self.unschedule_task(owner)
    unschedule(job_matching_param: JobMatchingParam, schedule_id: owner_identifier(owner))
  end

  #
  # Return the scheduling information for the next Delayed::Job set to run as a recurring job for the owner instance,
  # or return empty array if there is no matching schedule
  # @param [ActiveRecord] owner - the owner instance
  # @return [Array{Delayed::Job}]
  def self.task_schedule(owner)
    jobs(job_matching_param: JobMatchingParam, schedule_id: owner_identifier(owner))
  end

  #
  # Get the unique owner identifier string
  # @param [ActiveRecord] owner
  def self.owner_identifier(owner)
    owner.to_global_id.to_s
  end

  #
  # Data passed when the job is originally scheduled, to be used in #perform
  # each time the recurring task is run
  # @return [Hash{Symbol: Value} | nil]
  def recurring_job_data
    @schedule_options[:data]
  end
end
