require 'active_record/migration/app_generator'
class UpdateDatadicVariablesR2ma0p < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ref_data'
    self.table_name = 'datadic_variables'
    self.class_name = 'DynamicModel::DatadicVariable'
    self.fields = %i[study source_name source_type domain form_name variable_name variable_type presentation_type label label_note annotation is_required valid_type valid_min valid_max multi_valid_choices is_identifier is_derived_var multi_derived_from_id doc_url target_type owner_email classification other_classification multi_timepoints equivalent_to_id storage_type db_or_fs schema_or_path table_or_file disabled admin_id redcap_data_dictionary_id position section_id sub_section_id title storage_varname contributor_type]
    self.table_comment = 'Dynamicmodel: User Variables'
    self.fields_comments = { study: 'Study name', source_name: 'Source of variable', source_type: 'Source type', domain: 'Domain', form_name: 'Form name (if the source was a type of form)', variable_name: 'Variable name', variable_type: 'Variable type', presentation_type: 'Data type for presentation purposes', label: 'Primary label or title (if source was a form, the label presented for the field)', label_note: 'Description (if source was a form, a note presented for the field)', annotation: 'Annotations (if source was a form, annotations not presented to the user)', is_required: 'Was required in source', valid_type: 'Source data type', valid_min: 'Minimum value', valid_max: 'Maximum value', multi_valid_choices: 'List of valid choices for categorical variables', is_identifier: 'Represents identifiable information', is_derived_var: 'Is a derived variable', multi_derived_from_id: 'If a derived variable, ids of variables used to calculate it', doc_url: 'URL to additional documentation', target_type: 'Type of participant this variable relates to', owner_email: 'Owner, especially for derived variables', classification: 'Category of sensitivity from a privacy perspective', other_classification: 'Additional information regarding classification', multi_timepoints: 'Timepoints this data is collected (in longitudinal studies)', equivalent_to_id: 'Primary variable id this is equivalent to', storage_type: 'Type of storage for dataset', db_or_fs: 'Database or Filesystem name', schema_or_path: 'Database schema or Filesystem directory path', table_or_file: 'Database table (or view, if derived or equivalent to another variable), or filename in directory', redcap_data_dictionary_id: 'Reference to REDCap data dictionary representation', position: 'Relative position (for source forms or other variables where order of collection matters)', section_id: 'Section this belongs to', sub_section_id: 'Sub-section this belongs to', title: 'Section caption', storage_varname: 'Database field name, or variable name in data file', contributor_type: 'Type of contributor this variable was provided by' }
    self.db_configs = { id: { type: 'integer' }, study: { type: 'string' }, source_name: { type: 'string' }, source_type: { type: 'string' }, domain: { type: 'string' }, form_name: { type: 'string' }, variable_name: { type: 'string' }, variable_type: { type: 'string' }, presentation_type: { type: 'string' }, label: { type: 'string' }, label_note: { type: 'string' }, annotation: { type: 'string' }, is_required: { type: 'boolean' }, valid_type: { type: 'string' }, valid_min: { type: 'string' }, valid_max: { type: 'string' }, multi_valid_choices: { type: 'string' }, is_identifier: { type: 'boolean' }, is_derived_var: { type: 'boolean' }, multi_derived_from_id: { type: 'integer' }, doc_url: { type: 'string' }, target_type: { type: 'string' }, owner_email: { type: 'string' }, classification: { type: 'string' }, other_classification: { type: 'string' }, multi_timepoints: { type: 'string' }, equivalent_to_id: { type: 'integer' }, storage_type: { type: 'string' }, db_or_fs: { type: 'string' }, schema_or_path: { type: 'string' }, table_or_file: { type: 'string' }, disabled: { type: 'boolean' }, admin_id: { type: 'integer' }, redcap_data_dictionary_id: { type: 'integer' }, created_at: { type: 'datetime' }, updated_at: { type: 'datetime' }, position: { type: 'integer' }, section_id: { type: 'integer' }, sub_section_id: { type: 'integer' }, title: { type: 'string' }, storage_varname: { type: 'string' }, user_id: { type: 'integer' }, contributor_type: { type: 'string' } }
    self.no_master_association = true
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    self.prev_fields = %i[study source_name source_type domain form_name variable_name variable_type presentation_type label label_note annotation is_required valid_type valid_min valid_max multi_valid_choices is_identifier is_derived_var multi_derived_from_id doc_url target_type owner_email classification other_classification multi_timepoints equivalent_to_id storage_type db_or_fs schema_or_path table_or_file disabled redcap_data_dictionary_id position section_id sub_section_id title storage_varname contributor_type]
    # added: []
    # removed: []
    # changed type: {"created_at"=>:datetime, "updated_at"=>:datetime}
    # new table comment: Dynamicmodel: User Variables

    update_fields

    create_dynamic_model_trigger
  end
end
