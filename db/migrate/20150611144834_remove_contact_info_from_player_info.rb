class RemoveContactInfoFromPlayerInfo < ActiveRecord::Migration
  def change
    remove_column :player_infos, :email, :string
    remove_column :player_infos, :email2, :string
    remove_column :player_infos, :email3, :string
    remove_column :player_infos, :twitter_id, :string
    remove_column :player_infos, :website, :string
    remove_column :player_infos, :alternate_website, :string
  end
end
