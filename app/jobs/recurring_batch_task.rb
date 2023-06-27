# frozen_string_literal: true

class RecurringBatchTask < ApplicationRecurringJob
  queue :batch

  #
  # Run the batch trigger for the specified dynamic definition (e.g. DynamicModel definition record)
  # as a job.
  # @param [String] dynamic_def - class nam, one of ActivityLog, DynamicModel, ExternalIdentifier
  # @param [Integer|nil] limit - max records to process
  # @param [User|nil] user - force user to use for processing records
  # @param [Admin::AppType|nil] app_type - force user to use app type, rather than current app type set in the record
  def perform
    gid = recurring_job_data[:dynamic_def]
    dynamic_def = GlobalID::Locator.locate gid
    dynamic_def.reload
    dynamic_def.option_configs force: true
    bt = dynamic_def.configurations&.dig(:batch_trigger)
    unless bt
      msg = "Attempted to perform recurring batch job for #{gid} - but _configurations:" \
                        "has no batch_trigger: defined\n" \
                        "#{dynamic_def.configurations || '(nil _configurations)'}"
      Rails.logger.warn msg
      raise FphsException, msg
    end
    limit = bt[:limit]

    user = dynamic_def.class.user_for_conf_snippet(bt)

    dynamic_def_imp_class = dynamic_def.implementation_class
    dynamic_def_imp_class.trigger_batch_now(limit: limit, alt_user: user)
  rescue StandardError => e
    Rails.logger.warn "Recurring job failed: #{self} - #{gid} - #{e}"
    Rails.logger.warn e.backtrace.join("\n")
    ApplicationJob.notify_failure self
    raise
  end
end
