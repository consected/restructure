class PrepPasswordReminders < ActiveRecord::Migration
  def change
    User.active.each do |user|
      user.send :set_default_password_expiration
      Users::Reminders.password_expiration(user)
    end
  end
end
