class AddAdminMaster < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~END_SQL
          insert into ml_app.masters (id) values (-2);
        END_SQL
      end
    end
  end
end
