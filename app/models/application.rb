class Application
  def self.server_cache_version
    Rails.cache.fetch('server_cache_version'){
      Time.now.to_f.to_s
    }
  end
end
