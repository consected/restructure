class AddTermsOfUseToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :terms_of_use_accepted, :string
  end
end
