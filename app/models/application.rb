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
    
    record.errors.each do |r|
      res << r.join(' ')
    end
    
    res.join "; "
  end
end
