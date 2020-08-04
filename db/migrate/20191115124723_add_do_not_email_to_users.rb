# Migration version added
class AddDoNotEmailToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :do_not_email, :boolean, default: false
  end
end
