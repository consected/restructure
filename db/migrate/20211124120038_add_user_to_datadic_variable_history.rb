class AddUserToDatadicVariableHistory < ActiveRecord::Migration[5.2]
  def change
    history_cols = ActiveRecord::Base.connection.columns('ref_data.datadic_variable_history')
    res = history_cols.find { |c| c.name == 'user_id' }
    if res
      puts 'user_id exists in datadic_variable_history'
      return
    end
    add_reference :datadic_variable_history, :user, foreign_key: true
  end
end
