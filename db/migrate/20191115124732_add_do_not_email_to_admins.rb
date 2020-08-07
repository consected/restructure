class AddDoNotEmailToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :do_not_email, :boolean, default: false
  end
end
