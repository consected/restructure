# frozen_string_literal: true

class AddCategoryToExternalIdentifiers < ActiveRecord::Migration[5.2]
  def change
    add_column :external_identifiers, :category, :string
  end
end
