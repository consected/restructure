class AddOtpSecretToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :otp_secret, :string
  end
end
