require 'active_record/migration/sql_helpers'

class DropDynamicModelResNameFromRedcapDataDictionaries < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers
  def change
    remove_column 'ref_data.redcap_data_dictionaries', :dynamic_model_res_name, :string
    remove_column 'ref_data.redcap_data_dictionary_history', :dynamic_model_res_name, :string

    create_general_admin_history_trigger('ref_data',
                                         :redcap_data_dictionaries,
                                         %i[
                                           redcap_project_admin_id
                                           field_count
                                           captured_metadata
                                         ])
  end
end
