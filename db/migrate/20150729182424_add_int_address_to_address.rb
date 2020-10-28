class AddIntAddressToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :country, :string, limit:3
    add_column :addresses, :postal_code, :string
    add_column :addresses, :region, :string
  end
end
