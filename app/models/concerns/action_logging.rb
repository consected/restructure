module ActionLogging

  extend ActiveSupport::Concern
  
  def session_class_name
    self.class.name.downcase.to_sym
  end
  
  def action_logger
    # We are using syslog now, so push everything out through the same logger
    Rails.logger
  end
  
  def log_action action, sub, results, method, params, status="OK", extras={}
    
    res = {user: self.id, user_type: session_class_name, email: self.email, action: action, sub: sub, method: method, params: params, results: results, status: status, action_at: DateTime.now.iso8601}
    res.merge! extras
    
    # Note: the prefix on the front of the message is used by rsyslog to filter messages to the correct file
    action_logger.info("fphs_#{session_class_name}_actions=#{res.to_json}")
  end
  
  def after_database_authentication
    log_action "#{session_class_name} login", "LOGIN", 0, :post, {}
  end

  
end
