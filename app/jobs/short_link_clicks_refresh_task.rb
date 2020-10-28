class ShortLinkClicksRefreshTask
  include Delayed::RecurringJob
  run_every 4.hours

  queue 'recurring-tasks'

  def perform
    c = DynamicModel::ZeusShortLinkClick.new
    c.get_logs
  end
end
