class AddContributorToDatadicVariables < ActiveRecord::Migration[5.2]
  def change
    add_column :datadic_variables, :contributor_type, :string, comment: 'Type of contributor this variable was provided by'
  end
end
