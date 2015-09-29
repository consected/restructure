class Application  
  
  def self.version    
    @@version ||= File.read('./version.txt').gsub("\n",'')    
  end
  
  def self.server_cache_version
    Rails.cache.fetch('server_cache_version'){
      Time.now.to_f.to_s
    }
  end
  
  
  def self.record_error_message record
    res = []
    
    return "unexpected error" unless record
    
    record.errors.each do |r|
      res << r.join(' ')
    end
    
    res.join "; "
  end
  
  def self.hide_messages
    @@hide_messages ||= [I18n.translate('devise.sessions.signed_in')]
    Rails.logger.info "Hide messages: #{@@hide_messages}"
    @@hide_messages
  end
  
  
end
