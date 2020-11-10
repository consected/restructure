class AddDisabledToColleges < ActiveRecord::Migration
  def change
    add_column :colleges, :disabled, :boolean
  end
end
