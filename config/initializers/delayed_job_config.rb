Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = Rails.env.production? ? 5 : 5
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 60.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
if Rails.env.production?
  Delayed::Worker.logger = Logger.new('/dev/null')
else
  Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
end

# Make an alias of this class at the top level, to allow globalid to work
MessageNotification = Messaging::MessageNotification


ActiveJob::QueueAdapters::DelayedJobAdapter.singleton_class.prepend(Module.new do
  def enqueue(job)
    provider_job = super
    job.provider_job = provider_job
    provider_job
  end

  def enqueue_at(job, timestamp)
    provider_job = super
    job.provider_job = provider_job
    provider_job
  end
end)
