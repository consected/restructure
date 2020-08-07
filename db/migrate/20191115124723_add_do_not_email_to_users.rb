class AddDoNotEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :do_not_email, :boolean, default: false
  end
end
