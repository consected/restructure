class RemoveSourceFromScantron < ActiveRecord::Migration
  def change
    remove_column :scantrons, :source, :string
  end
end
