class AddEmailsToPlayerInfos < ActiveRecord::Migration
  def change
    add_column :player_infos, :email, :string
    add_column :player_infos, :email2, :string
    add_column :player_infos, :email3, :string
    remove_column :player_infos, :current_email
  end
end
