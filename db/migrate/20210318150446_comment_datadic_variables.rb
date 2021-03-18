require 'active_record/migration/sql_helpers'
class CommentDatadicVariables < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    schema = 'ref_data'
    table_name = 'datadic_variables'
    history_table_name = 'datadic_variable_history'

    comments = {
      study: 'Study name',
      source_name: 'Source of variable',
      source_type: 'Source type',
      domain: 'Domain',
      form_name: 'Form name (if the source was a type of form)',
      variable_name: 'Variable name (as stored)',
      variable_type: 'Variable type',
      presentation_type: 'Data type for presentation purposes',
      label: 'Primary label or title (if source was a form, the label presented for the field)',
      label_note: 'Description (if source was a form, a note presented for the field)',
      annotation: 'Annotations (if source was a form, annotations not presented to the user)',
      is_required: 'Was required in source',
      valid_type: 'Source data type',
      valid_min: 'Minimum value',
      valid_max: 'Maximum value',
      multi_valid_choices: 'List of valid choices for categorical variables',
      is_identifier: 'Represents identifiable information',
      is_derived_var: 'Is a derived variable',
      multi_derived_from_id: 'If a derived variable, ids of variables used to calculate it',
      doc_url: 'URL to additional documentation',
      target_type: 'Type of participant this variable relates to',
      owner_email: 'Owner, especially for derived variables',
      classification: 'Category of sensitivity from a privacy perspective',
      other_classification: 'Additional information regarding classification',
      multi_timepoints: 'Timepoints this data is collected (in longitudinal studies)',
      equivalent_to_id: 'Primary variable id this is equivalent to',
      storage_type: 'Type of storage for dataset',
      db_or_fs: 'Database or Filesystem name',
      schema_or_path: 'Database schema or Filesystem directory path',
      table_or_file: 'Database table (or view, if derived or equivalent to another variable), or filename in directory',
      storage_varname: 'Database field name, or variable name in data file',
      redcap_data_dictionary_id: 'Reference to REDCap data dictionary representation',
      position: 'Relative position (for source forms or other variables where order of collection matters)',
      section_id: 'Section this belongs to',
      sub_section_id: 'Sub-section this belongs to',
      title: 'Section caption'
    }

    comments.each do |c, new_comment|
      change_column_comment "#{schema}.#{table_name}", c, new_comment
      change_column_comment "#{schema}.#{history_table_name}", c, new_comment
    end
  end
end
