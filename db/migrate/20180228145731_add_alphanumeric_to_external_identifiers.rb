class AddAlphanumericToExternalIdentifiers < ActiveRecord::Migration
  def change
    add_column :external_identifiers, :alphanumeric, :boolean
  end
end
