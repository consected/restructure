# frozen_string_literal: true

class HandleBatchJob < ApplicationJob
  queue_as :batch

  #
  # Run the batch trigger for the specified dynamic definition (e.g. DynamicModel definition record)
  # as a job.
  # @param [String] dynamic_def - class name, one of ActivityLog, DynamicModel, ExternalIdentifier
  # @param [Integer|nil] limit - max records to process
  # @param [User|nil] user - force user to use for processing records
  # @param [Admin::AppType|nil] app_type - force user to use app type, rather than current app type set in the record
  def perform(dynamic_def, limit: nil, user: nil, app_type: nil)
    user ||= User.use_batch_user(app_type) if app_type
    dynamic_def_class = dynamic_def.constantize
    dynamic_def_class.trigger_batch_now(limit: limit, alt_user: user)
  end
end
