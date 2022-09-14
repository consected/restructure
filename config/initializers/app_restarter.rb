class AppControl
  @@currently_defining_models = false

  def self.restart_server(not_delayed_job: nil, not_memcached: nil)
    Rails.logger.warn 'Restart Server requested'
    if Rails.env.production?
      pid = spawn('app-scripts/restart_app_server.sh')
      Process.detach(pid)
    else
      FileUtils.touch Rails.root.join('app', 'models', 'dev_server.rb')
      Rails.reload! if Rails.respond_to? :reload!
    end
    restart_delayed_job unless not_delayed_job
    restart_memcached unless not_memcached
  rescue StandardError => e
    Rails.logger.warn "Failed to restart server: #{e.inspect}"
  end

  def self.restart_delayed_job
    Rails.logger.warn 'Restart delayed_job requested'
    pid = spawn('app-scripts/restart_delayed_job.sh')
    Process.detach(pid)
  rescue StandardError => e
    Rails.logger.warn "Failed to restart DelayedJob: #{e.inspect}"
  end

  def self.restart_memcached
    Rails.logger.warn 'Restart Memcached requested'
    pid = spawn('app-scripts/restart_memcached.sh')
    Process.detach(pid)
  rescue StandardError => e
    Rails.logger.warn "Failed to restart Memcached: #{e.inspect}"
  end

  def self.define_models
    if @@currently_defining_models
      Rails.logger.warn 'Already defining models'
      return
    end

    Rails.logger.warn 'Define models requested'
    @@currently_defining_models = true

    ::ActivityLog.define_models

    @@currently_defining_models = false
  end
end

# # On restarts and when code is changed in development, run define models
Rails.application.config.to_prepare do
  require_dependency 'master'
  AppControl.define_models
end
