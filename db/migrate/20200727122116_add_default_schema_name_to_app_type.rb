# frozen_string_literal: true

class AddDefaultSchemaNameToAppType < ActiveRecord::Migration[5.2]
  def change
    add_column :app_types, :default_schema_name, :string
  end
end
