class AddResetPasswordToAdmin < ActiveRecord::Migration
  def change
    add_column :admins, :reset_password_sent_at, :datetime
  end
end
