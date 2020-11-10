class AddPlayerContactRankToActivityLogPlayerContactPhones < ActiveRecord::Migration
  def change
    add_column :activity_log_player_contact_phones, :set_related_player_contact_rank, :string
  end
end
