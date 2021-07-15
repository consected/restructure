# frozen_string_literal: true

require 'active_record/migration/sql_helpers'

class CreateUserDescriptions < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    create_table :user_descriptions do |t|
      t.belongs_to :app_type, foreign_key: true
      t.string :role_name
      t.string :role_template
      t.string :name
      t.string :description
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.timestamps
    end

    create_table :user_description_history do |t|
      t.belongs_to :user_description, foreign_key: true,
                                      index: { name: 'idx_h_on_user_descriptions_id' }

      t.belongs_to :app_type, foreign_key: true
      t.string :role_name
      t.string :role_template
      t.string :name
      t.string :description
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.timestamps
    end

    create_general_admin_history_trigger('ml_app',
                                         :user_descriptions,
                                         %i[
                                           app_type_id role_name role_template name description
                                         ])
  end
end
