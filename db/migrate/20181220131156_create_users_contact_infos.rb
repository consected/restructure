class CreateUsersContactInfos < ActiveRecord::Migration
  def change
    create_table :users_contact_infos do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.string :sms_number
      t.string :phone_number
      t.string :alt_email

      t.timestamps null: false
    end
  end
end
