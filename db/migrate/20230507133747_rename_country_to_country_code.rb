class RenameCountryToCountryCode < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :country, :country_code
  end
end
