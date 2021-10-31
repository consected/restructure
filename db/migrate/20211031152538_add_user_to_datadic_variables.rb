class AddUserToDatadicVariables < ActiveRecord::Migration[5.2]
  def change
    add_reference :datadic_variables, :user, foreign_key: true
  end
end
