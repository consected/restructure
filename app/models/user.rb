class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => true, :if => :email_changed?
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => true, :if => :email_changed?
 
  before_create :generate_password
  
  
  def force_password_reset
    generate_password
  end
  
  def new_password
    @new_password
  end
  
  def action_logger
    logv = DateTime.now.strftime('%Y-%m-%d')
    @@action_logger ||= {}
    @@action_logger[logv] ||= Logger.new("#{Rails.root}/log/action_log-#{logv}.log")
  end
  
  def log_action action, sub, results, method, params, status="OK"
    
    res = {user: self.id, email: self.email, action: action, sub: sub, method: method, params: params, results: results, status: status, action_at: DateTime.now.iso8601}
    action_logger.info(res.to_json)
  end

protected

  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end
  
  
end
