class SetupItemFlagNameConstraint < ActiveRecord::Migration[5.2]
  def change
    execute <<~END_SQL
      alter table ml_app.item_flags
      alter column item_flag_name_id set not null;
    END_SQL
  end
end
