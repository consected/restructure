class AppControl

  def self.restart_server

    begin
      if Rails.env.production?
        FileUtils.touch Rails.root.join('tmp', 'restart.txt')
      else
        FileUtils.touch Rails.root.join('app', 'models', 'dev_server.rb')
        Rails.reload! if Rails.respond_to? :reload! 
      end
    rescue => e
      Rails.logger.warn "Failed to restart server: #{e.inspect}"
    end

  end

end
