class CreateManualInvestigations < ActiveRecord::Migration
  def change
    create_table :manual_investigations do |t|
      t.string :fill_in_addresses, limit: 1
      t.string :in_survey, limit: 1
      t.string :verify_survey_participation, limit: 1
      t.string :verify_player_and_or_match, limit: 1
      t.string :accuracy, limit: 15
      t.integer :accuracy_score
      t.integer :changed
      t.string :changed_column
      t.integer :verified
      t.integer :pilotq1
      t.integer :mailing
      t.integer :outreach_vfy
      t.integer :insert_audit_key
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
