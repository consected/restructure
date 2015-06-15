class CreatePlayerInfos < ActiveRecord::Migration
  def change
    create_table :player_infos do |t|
      t.belongs_to :master, index: true, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :middle_name
      t.string :nick_name
      t.date :birth_date
      t.date :death_date
      t.string :occupation_category
      t.string :company
      t.string :company_description
      t.string :transaction_status
      t.string :transaction_substatus
      t.string :website
      t.string :alternate_website
      t.string :twitter_id
      t.belongs_to :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
