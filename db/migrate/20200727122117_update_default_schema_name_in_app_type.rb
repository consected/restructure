# frozen_string_literal: true

class UpdateDefaultSchemaNameInAppType < ActiveRecord::Migration[5.2]
  def self.up
    Admin::AppType.update_all("default_schema_name = replace(name, '-', '_')")
  end
end
