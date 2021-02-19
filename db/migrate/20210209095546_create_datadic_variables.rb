require 'active_record/migration/sql_helpers'
class CreateDatadicVariables < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    create_table 'ref_data.datadic_variables' do |t|
      t.string :study
      t.string :source_name
      t.string :source_type
      t.string :domain
      t.string :form_name
      t.string :variable_name
      t.string :variable_type
      t.string :presentation_type
      t.string :label
      t.string :label_note
      t.string :annotation

      t.boolean :is_required
      t.string :valid_type
      t.string :valid_min
      t.string :valid_max
      t.string :multi_valid_choices, array: true
      t.boolean :is_identifier
      t.boolean :is_derived_var
      t.bigint :multi_derived_from_id, array: true
      t.string :doc_url
      t.string :target_type
      t.string :owner_email
      t.string :classification
      t.string :other_classification
      t.string :multi_timepoints, array: true
      t.references :equivalent_to, index: { name: 'idx_dv_equiv' },
                                   foreign_key: { to_table: 'ref_data.datadic_variables' }

      t.string :storage_type
      t.string :db_or_fs
      t.string :schema_or_path
      t.string :table_or_file
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.belongs_to :redcap_data_dictionary, foreign_key: true
      t.timestamps
    end

    create_table 'ref_data.datadic_variable_history' do |t|
      t.belongs_to :datadic_variable, foreign_key: true,
                                      index: { name: 'idx_h_on_datadic_variable_id' }

      t.string :study
      t.string :source_name
      t.string :source_type
      t.string :domain
      t.string :form_name
      t.string :variable_name
      t.string :variable_type
      t.string :presentation_type
      t.string :label
      t.string :label_note
      t.string :annotation

      t.boolean :is_required
      t.string :valid_type
      t.string :valid_min
      t.string :valid_max
      t.string :multi_valid_choices, array: true
      t.boolean :is_identifier
      t.boolean :is_derived_var
      t.bigint :multi_derived_from_id, array: true
      t.string :doc_url
      t.string :target_type
      t.string :owner_email
      t.string :classification
      t.string :other_classification
      t.string :multi_timepoints, array: true
      t.references :equivalent_to, index: { name: 'idx_dvh_equiv' },
                                   foreign_key: { to_table: 'ref_data.datadic_variables' }

      t.string :storage_type
      t.string :db_or_fs
      t.string :schema_or_path
      t.string :table_or_file
      t.boolean :disabled
      t.belongs_to :admin, foreign_key: true
      t.belongs_to :redcap_data_dictionary, foreign_key: true,
                                            index: { name: 'idx_dvh_on_redcap_dd_id' }

      t.timestamps
    end

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
                                           redcap_data_dictionary_id
                                         ])
  end
end
