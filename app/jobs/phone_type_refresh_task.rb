class PhoneTypeRefreshTask
  include Delayed::RecurringJob
  run_every 4.hours

  queue 'recurring-tasks'

  def perform
    # Use the admin email as the user - this assumes that the equivalent user has been set up for automated use
    user = User.where(email: Settings::AdminEmail).first
    PlayerContactPhoneInfo.validate_incomplete user: user
  end
end
