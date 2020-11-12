class AddAdminToProtocols < ActiveRecord::Migration
  def change
    add_reference :protocols, :admin, index: true, foreign_key: true
  end
end
