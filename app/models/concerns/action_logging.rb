module ActionLogging

  extend ActiveSupport::Concern
  
  def session_class_name
    self.class.name.downcase.to_sym
  end
  
  def action_logger
    logv = DateTime.now.strftime('%Y-%m-%d')
    @@action_logger ||= {}
    @@action_logger[logv] ||= Logger.new("#{Rails.root}/action_logs/#{session_class_name}_action_log-#{logv}.log")
  end
  
  def log_action action, sub, results, method, params, status="OK", extras={}
    
    res = {user: self.id, user_type: session_class_name, email: self.email, action: action, sub: sub, method: method, params: params, results: results, status: status, action_at: DateTime.now.iso8601}
    res.merge! extras
    
    action_logger.info(res.to_json)
  end
  
  def after_database_authentication
    log_action "#{session_class_name} login", "LOGIN", 0, :post, {}
  end

  
end
