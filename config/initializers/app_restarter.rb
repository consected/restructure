class AppControl
  @@currently_defining_models = false

  def self.restart_server
    if Rails.env.production?
      FileUtils.touch Rails.root.join('tmp', 'restart.txt')
      restart_delayed_job
    else
      FileUtils.touch Rails.root.join('app', 'models', 'dev_server.rb')
      Rails.reload! if Rails.respond_to? :reload!
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to restart server: #{e.inspect}"
  end

  def self.restart_delayed_job
    `app-scripts/restart_delayed_job.sh`
  end

  def self.define_models
    if @@currently_defining_models
      Rails.logger.info 'Already defining models'
      return
    end

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
