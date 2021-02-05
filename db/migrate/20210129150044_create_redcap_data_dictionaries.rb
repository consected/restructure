require 'active_record/migration/sql_helpers'

class CreateRedcapDataDictionaries < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    table_comment = 'Retrieved Redcap Data Dictionaries (metadata)'
    history_table_comment = "#{table_comment} - history"

    create_table('ref_data.redcap_data_dictionaries', comment: table_comment) do |t|
      t.belongs_to :redcap_project_admin, foreign_key: true,
                                          index: { name: 'idx_on_redcap_admin_id' }
      t.string :dynamic_model_res_name
      t.integer :field_count
      t.jsonb :captured_metadata
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.timestamps
    end

    create_table('ref_data.redcap_data_dictionary_history', comment: history_table_comment) do |t|
      t.belongs_to :redcap_data_dictionary, foreign_key: true,
                                            index: { name: 'idx_history_on_redcap_data_dictionary_id' }
      t.belongs_to :redcap_project_admin, foreign_key: true,
                                          index: { name: 'idx_h_on_redcap_admin_id' }

      t.string :dynamic_model_res_name
      t.integer :field_count
      t.jsonb :captured_metadata
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.timestamps
    end

    create_general_admin_history_trigger('ref_data',
                                         :redcap_data_dictionaries,
                                         %i[
                                           redcap_project_admin_id
                                           dynamic_model_res_name
                                           field_count
                                           captured_metadata
                                         ])
  end
end
