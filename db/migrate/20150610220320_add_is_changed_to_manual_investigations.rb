class AddIsChangedToManualInvestigations < ActiveRecord::Migration
  def change
    add_column :manual_investigations, :is_changed, :integer
  end
end
