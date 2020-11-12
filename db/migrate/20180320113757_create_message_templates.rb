class CreateMessageTemplates < ActiveRecord::Migration
  def change
    create_table :message_templates do |t|
      t.string :name
      t.string :message_type
      t.string :template_type
      t.string :template
      t.references :admin, index: true, foreign_key: true
      t.boolean :disabled

      t.timestamps null: false
    end
  end
end
