class AddOptionsToRedcapProjectAdmins < ActiveRecord::Migration[5.2]
  def change
    add_column :redcap_project_admins, :options, :string
  end
end
