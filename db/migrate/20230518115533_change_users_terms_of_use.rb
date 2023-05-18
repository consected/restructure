class ChangeUsersTermsOfUse < ActiveRecord::Migration[6.1]
  def change
    change_column :users, :terms_of_use, :string
  end
end
