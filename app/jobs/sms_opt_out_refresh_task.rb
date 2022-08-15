class SmsOptOutRefreshTask
  include Delayed::RecurringJob
  run_every 24.hours

  queue 'recurring-tasks'

  def perform
    DynamicModel::PlayerContactPhoneInfo.update_opt_outs
  end
end
