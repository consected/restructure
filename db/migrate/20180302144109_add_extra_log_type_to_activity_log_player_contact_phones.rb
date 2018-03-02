class AddExtraLogTypeToActivityLogPlayerContactPhones < ActiveRecord::Migration
  def change
    add_column :activity_log_player_contact_phones, :extra_log_type, :string
  end
end
