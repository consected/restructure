require 'active_record/migration/sql_helpers'
class CreateRedcapDataCollectionInstrument < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    create_table 'ref_data.redcap_data_collection_instruments' do |t|
      t.string :name
      t.string :label
      t.boolean :disabled
      t.belongs_to :redcap_project_admin, index: { name: 'idx_rdci_pa' }
      t.belongs_to :admin, foreign_key: true
      t.timestamps null: false
    end

    create_table 'ref_data.redcap_data_collection_instrument_history' do |t|
      t.belongs_to :redcap_data_collection_instrument, foreign_key: true,
                                                       index: { name: 'idx_h_on_rdci_id' }

      t.belongs_to :redcap_project_admin, foreign_key: true,
                                          index: { name: 'idx_rdcih_on_proj_admin_id' }

      t.string :name
      t.string :label
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true,
                           index: { name: 'idx_rdcih_on_admin_id' }
      t.timestamps
    end

    create_general_admin_history_trigger('ref_data',
                                         :redcap_data_collection_instruments,
                                         %i[
                                           redcap_project_admin_id
                                           name
                                           label
                                         ])
  end
end
