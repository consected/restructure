require 'active_record/migration/sql_helpers'
class AddStorageVarnameToDatadicVariables < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers
  def change
    add_column 'ref_data.datadic_variables', :storage_varname, :string
    add_column 'ref_data.datadic_variable_history', :storage_varname, :string

    create_general_admin_history_trigger('ref_data',
                                         :datadic_variables,
                                         %i[
                                           study
                                           source_name
                                           source_type
                                           domain
                                           form_name
                                           variable_name
                                           variable_type
                                           presentation_type
                                           label
                                           label_note
                                           annotation
                                           is_required
                                           valid_type
                                           valid_min
                                           valid_max
                                           multi_valid_choices
                                           is_identifier
                                           is_derived_var
                                           multi_derived_from_id
                                           doc_url
                                           target_type
                                           owner_email
                                           classification
                                           other_classification
                                           multi_timepoints
                                           equivalent_to_id
                                           storage_type
                                           db_or_fs
                                           schema_or_path
                                           table_or_file
                                           storage_varname
                                           redcap_data_dictionary_id
                                           position
                                           section_id
                                           sub_section_id
                                           title
                                         ])
  end
end
