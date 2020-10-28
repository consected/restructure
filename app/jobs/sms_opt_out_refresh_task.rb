class SmsOptOutRefreshTask
  include Delayed::RecurringJob
  run_every 24.hours

  queue 'recurring-tasks'

  def perform
    # user = User.use_batch_user(Settings.bulk_msg_app)
    DynamicModel::PlayerContactPhoneInfo.update_opt_outs
  end
end
