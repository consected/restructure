class CreateProInfos < ActiveRecord::Migration
  def change
    create_table :pro_infos do |t|
      t.belongs_to :master, index: true, foreign_key: true
      t.integer :pro_id
      t.string :in_survey
      t.string :first_name
      t.string :middle_name
      t.string :nick_name
      t.string :last_name
      t.string :birth_date
      t.string :death_date
      t.integer :start_year
      t.integer :end_year
      t.decimal :accrued_seasons
      t.string :college
      t.string :first_contract
      t.string :second_contract
      t.string :third_contract
      t.string :career_info
      t.string :birthplace
      
    
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
