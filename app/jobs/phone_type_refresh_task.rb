class PhoneTypeRefreshTask
  include Delayed::RecurringJob
  run_every 4.hours

  queue 'recurring-tasks'

  def perform
    user = User.use_batch_user(Settings.bulk_msg_app)
    DynamicModel::PlayerContactPhoneInfo.validate_incomplete user: user

    DynamicModel::FemflContactPhoneInfo.validate_incomplete user: user
  end
end
