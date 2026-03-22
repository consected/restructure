class AddOtpSecretToAdmin < ActiveRecord::Migration[7.2]
  def change
    add_column :admins, :otp_secret, :string
  end
end
