# Migration version added
class AddDoNotEmailToAdmins < ActiveRecord::Migration[4.2]
  def change
    add_column :admins, :do_not_email, :boolean, default: false
  end
end
