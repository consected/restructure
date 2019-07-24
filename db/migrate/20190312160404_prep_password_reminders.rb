class PrepPasswordReminders < ActiveRecord::Migration
  def change
    return unless User.respond_to?(:reset_password_sent_at=)
    User.active.each do |user|
      user.send :set_default_password_expiration
      Users::Reminders.password_expiration(user)
    end
  end
end
