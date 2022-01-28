# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_01_21_143719) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accuracy_score_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "value"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "accuracy_score_id"
    t.index ["accuracy_score_id"], name: "index_accuracy_score_history_on_accuracy_score_id"
  end

  create_table "accuracy_scores", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "value"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.index ["admin_id"], name: "index_accuracy_scores_on_admin_id"
  end

  create_table "activity_log_history", id: :serial, force: :cascade do |t|
    t.integer "activity_log_id"
    t.string "name"
    t.string "item_type"
    t.string "rec_type"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "action_when_attribute"
    t.string "field_list"
    t.string "blank_log_field_list"
    t.string "blank_log_name"
    t.string "extra_log_types"
    t.boolean "hide_item_list_panel"
    t.string "main_log_name"
    t.string "process_name"
    t.string "table_name"
    t.string "category"
    t.string "schema_name"
    t.index ["activity_log_id"], name: "index_activity_log_history_on_activity_log_id"
  end

  create_table "activity_log_player_contact_phone_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "player_contact_id"
    t.string "data"
    t.string "select_call_direction"
    t.string "select_who"
    t.date "called_when"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.string "notes"
    t.integer "protocol_id"
    t.string "set_related_player_contact_rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_player_contact_phone_id"
    t.string "extra_log_type"
    t.index ["activity_log_player_contact_phone_id"], name: "index_activity_log_player_contact_phone_history_on_activity_log"
    t.index ["master_id"], name: "index_activity_log_player_contact_phone_history_on_master_id"
    t.index ["player_contact_id"], name: "index_activity_log_player_contact_phone_history_on_player_conta"
    t.index ["user_id"], name: "index_activity_log_player_contact_phone_history_on_user_id"
  end

  create_table "activity_log_player_contact_phones", id: :serial, force: :cascade do |t|
    t.string "data"
    t.string "select_call_direction"
    t.string "select_who"
    t.date "called_when"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.integer "protocol_id"
    t.string "notes"
    t.integer "user_id"
    t.integer "player_contact_id"
    t.integer "master_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "set_related_player_contact_rank"
    t.string "extra_log_type"
    t.index ["master_id"], name: "index_activity_log_player_contact_phones_on_master_id"
    t.index ["player_contact_id"], name: "index_activity_log_player_contact_phones_on_player_contact_id"
    t.index ["protocol_id"], name: "index_activity_log_player_contact_phones_on_protocol_id"
    t.index ["user_id"], name: "index_activity_log_player_contact_phones_on_user_id"
  end

  create_table "activity_logs", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "item_type"
    t.string "rec_type"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "action_when_attribute"
    t.string "field_list"
    t.string "blank_log_field_list"
    t.string "blank_log_name"
    t.string "extra_log_types"
    t.boolean "hide_item_list_panel"
    t.string "main_log_name"
    t.string "process_name"
    t.string "table_name"
    t.string "category"
    t.string "schema_name"
  end

  create_table "address_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "street"
    t.string "street2"
    t.string "street3"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "source"
    t.integer "rank"
    t.string "rec_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.string "country", limit: 3
    t.string "postal_code"
    t.string "region"
    t.integer "address_id"
    t.index ["address_id"], name: "index_address_history_on_address_id"
    t.index ["master_id"], name: "index_address_history_on_master_id"
    t.index ["user_id"], name: "index_address_history_on_user_id"
  end

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "street"
    t.string "street2"
    t.string "street3"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "source"
    t.integer "rank"
    t.string "rec_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.string "country", limit: 3
    t.string "postal_code"
    t.string "region"
    t.index ["master_id"], name: "index_addresses_on_master_id"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "admin_action_logs", id: :serial, force: :cascade do |t|
    t.integer "admin_id"
    t.string "item_type"
    t.integer "item_id"
    t.string "action"
    t.string "url"
    t.json "prev_value"
    t.json "new_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_admin_action_logs_on_admin_id"
  end

  create_table "admin_history", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "disabled"
    t.integer "admin_id"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.datetime "reset_password_sent_at"
    t.datetime "password_updated_at"
    t.integer "updated_by_admin_id"
    t.index ["admin_id"], name: "index_admin_history_on_admin_id"
    t.index ["updated_by_admin_id"], name: "index_admin_history_on_upd_admin_id"
  end

  create_table "admins", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "disabled"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.datetime "reset_password_sent_at"
    t.datetime "password_updated_at"
    t.string "first_name"
    t.string "last_name"
    t.boolean "do_not_email", default: false
    t.bigint "admin_id"
    t.index ["admin_id"], name: "index_admins_on_admin_id"
  end

  create_table "app_configuration_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.bigint "app_type_id"
    t.bigint "user_id"
    t.string "role_name"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "app_configuration_id"
    t.index ["admin_id"], name: "index_app_configuration_history_on_admin_id"
    t.index ["app_configuration_id"], name: "index_app_configuration_history_on_app_configuration_id"
  end

  create_table "app_configurations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "user_id"
    t.integer "app_type_id"
    t.string "role_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["admin_id"], name: "index_app_configurations_on_admin_id"
    t.index ["app_type_id"], name: "index_app_configurations_on_app_type_id"
    t.index ["user_id"], name: "index_app_configurations_on_user_id"
  end

  create_table "app_type_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "app_type_id"
    t.index ["admin_id"], name: "index_app_type_history_on_admin_id"
    t.index ["app_type_id"], name: "index_app_type_history_on_app_type_id"
  end

  create_table "app_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.boolean "disabled"
    t.integer "admin_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "default_schema_name"
    t.index ["admin_id"], name: "index_app_types_on_admin_id"
  end

  create_table "college_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "synonym_for_id"
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "college_id"
    t.index ["college_id"], name: "index_college_history_on_college_id"
  end

  create_table "colleges", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "synonym_for_id"
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["admin_id"], name: "index_colleges_on_admin_id"
    t.index ["user_id"], name: "index_colleges_on_user_id"
  end

  create_table "config_libraries", id: :serial, force: :cascade do |t|
    t.string "category"
    t.string "name"
    t.string "options"
    t.string "format"
    t.boolean "disabled", default: false
    t.integer "admin_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["admin_id"], name: "index_config_libraries_on_admin_id"
  end

  create_table "config_library_history", id: :serial, force: :cascade do |t|
    t.string "category"
    t.string "name"
    t.string "options"
    t.string "format"
    t.boolean "disabled", default: false
    t.integer "admin_id"
    t.integer "config_library_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["admin_id"], name: "index_config_library_history_on_admin_id"
    t.index ["config_library_id"], name: "index_config_library_history_on_config_library_id"
  end

  create_table "copy_player_infos", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "nick_name"
    t.date "birth_date"
    t.date "death_date"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "contact_pref"
    t.integer "start_year"
    t.integer "rank"
    t.string "notes"
    t.integer "contactid"
    t.string "college"
    t.integer "end_year"
    t.string "source"
  end

  create_table "datadic_choice_history", force: :cascade do |t|
    t.bigint "datadic_choice_id"
    t.string "source_name"
    t.string "source_type"
    t.string "form_name"
    t.string "field_name"
    t.string "value"
    t.string "label"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.bigint "redcap_data_dictionary_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.datadic_choice_history_on_admin_id"
    t.index ["datadic_choice_id"], name: "idx_history_on_datadic_choice_id"
    t.index ["redcap_data_dictionary_id"], name: "idx_dch_on_redcap_dd_id"
  end

  create_table "datadic_choices", force: :cascade do |t|
    t.string "source_name"
    t.string "source_type"
    t.string "form_name"
    t.string "field_name"
    t.string "value"
    t.string "label"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.bigint "redcap_data_dictionary_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.datadic_choices_on_admin_id"
    t.index ["redcap_data_dictionary_id"], name: "index_ref_data.datadic_choices_on_redcap_data_dictionary_id"
  end

  create_table "datadic_variable_history", force: :cascade do |t|
    t.bigint "datadic_variable_id"
    t.string "study", comment: "Study name"
    t.string "source_name", comment: "Source of variable"
    t.string "source_type", comment: "Source type"
    t.string "domain", comment: "Domain"
    t.string "form_name", comment: "Form name (if the source was a type of form)"
    t.string "variable_name", comment: "Variable name"
    t.string "variable_type", comment: "Variable type"
    t.string "presentation_type", comment: "Data type for presentation purposes"
    t.string "label", comment: "Primary label or title (if source was a form, the label presented for the field)"
    t.string "label_note", comment: "Description (if source was a form, a note presented for the field)"
    t.string "annotation", comment: "Annotations (if source was a form, annotations not presented to the user)"
    t.boolean "is_required", comment: "Was required in source"
    t.string "valid_type", comment: "Source data type"
    t.string "valid_min", comment: "Minimum value"
    t.string "valid_max", comment: "Maximum value"
    t.string "multi_valid_choices", comment: "List of valid choices for categorical variables", array: true
    t.boolean "is_identifier", comment: "Represents identifiable information"
    t.boolean "is_derived_var", comment: "Is a derived variable"
    t.bigint "multi_derived_from_id", comment: "If a derived variable, ids of variables used to calculate it", array: true
    t.string "doc_url", comment: "URL to additional documentation"
    t.string "target_type", comment: "Type of participant this variable relates to"
    t.string "owner_email", comment: "Owner, especially for derived variables"
    t.string "classification", comment: "Category of sensitivity from a privacy perspective"
    t.string "other_classification", comment: "Additional information regarding classification"
    t.string "multi_timepoints", comment: "Timepoints this data is collected (in longitudinal studies)", array: true
    t.bigint "equivalent_to_id", comment: "Primary variable id this is equivalent to"
    t.string "storage_type", comment: "Type of storage for dataset"
    t.string "db_or_fs", comment: "Database or Filesystem name"
    t.string "schema_or_path", comment: "Database schema or Filesystem directory path"
    t.string "table_or_file", comment: "Database table (or view, if derived or equivalent to another variable), or filename in directory"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.bigint "redcap_data_dictionary_id", comment: "Reference to REDCap data dictionary representation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", comment: "Relative position (for source forms or other variables where order of collection matters)"
    t.integer "section_id", comment: "Section this belongs to"
    t.integer "sub_section_id", comment: "Sub-section this belongs to"
    t.string "title", comment: "Section caption"
    t.string "storage_varname", comment: "Database field name, or variable name in data file"
    t.string "contributor_type", comment: "Type of contributor this variable was provided by"
    t.jsonb "n_for_timepoints", comment: "For each named timepoint (name:), the population or count of responses (n:), with notes (notes:)"
    t.string "notes", comment: "Notes"
    t.bigint "user_id"
    t.index ["admin_id"], name: "index_ref_data.datadic_variable_history_on_admin_id"
    t.index ["datadic_variable_id"], name: "idx_h_on_datadic_variable_id"
    t.index ["equivalent_to_id"], name: "idx_dvh_equiv"
    t.index ["redcap_data_dictionary_id"], name: "idx_dvh_on_redcap_dd_id"
    t.index ["user_id"], name: "index_datadic_variable_history_on_user_id"
  end

  create_table "datadic_variables", comment: "Dynamicmodel: User Variables", force: :cascade do |t|
    t.string "study", comment: "Study name"
    t.string "source_name", comment: "Source of variable"
    t.string "source_type", comment: "Source type"
    t.string "domain", comment: "Domain"
    t.string "form_name", comment: "Form name (if the source was a type of form)"
    t.string "variable_name", comment: "Variable name"
    t.string "variable_type", comment: "Variable type"
    t.string "presentation_type", comment: "Data type for presentation purposes"
    t.string "label", comment: "Primary label or title (if source was a form, the label presented for the field)"
    t.string "label_note", comment: "Description (if source was a form, a note presented for the field)"
    t.string "annotation", comment: "Annotations (if source was a form, annotations not presented to the user)"
    t.boolean "is_required", comment: "Was required in source"
    t.string "valid_type", comment: "Source data type"
    t.string "valid_min", comment: "Minimum value"
    t.string "valid_max", comment: "Maximum value"
    t.string "multi_valid_choices", comment: "List of valid choices for categorical variables", array: true
    t.boolean "is_identifier", comment: "Represents identifiable information"
    t.boolean "is_derived_var", comment: "Is a derived variable"
    t.bigint "multi_derived_from_id", comment: "If a derived variable, ids of variables used to calculate it", array: true
    t.string "doc_url", comment: "URL to additional documentation"
    t.string "target_type", comment: "Type of participant this variable relates to"
    t.string "owner_email", comment: "Owner, especially for derived variables"
    t.string "classification", comment: "Category of sensitivity from a privacy perspective"
    t.string "other_classification", comment: "Additional information regarding classification"
    t.string "multi_timepoints", comment: "Timepoints this data is collected (in longitudinal studies)", array: true
    t.bigint "equivalent_to_id", comment: "Primary variable id this is equivalent to"
    t.string "storage_type", comment: "Type of storage for dataset"
    t.string "db_or_fs", comment: "Database or Filesystem name"
    t.string "schema_or_path", comment: "Database schema or Filesystem directory path"
    t.string "table_or_file", comment: "Database table (or view, if derived or equivalent to another variable), or filename in directory"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.bigint "redcap_data_dictionary_id", comment: "Reference to REDCap data dictionary representation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", comment: "Relative position (for source forms or other variables where order of collection matters)"
    t.integer "section_id", comment: "Section this belongs to"
    t.integer "sub_section_id", comment: "Sub-section this belongs to"
    t.string "title", comment: "Section caption"
    t.string "storage_varname", comment: "Database field name, or variable name in data file"
    t.bigint "user_id"
    t.string "contributor_type", comment: "Type of contributor this variable was provided by"
    t.jsonb "n_for_timepoints", comment: "For each named timepoint (name:), the population or count of responses (n:), with notes (notes:)"
    t.string "notes", comment: "Notes"
    t.index ["admin_id"], name: "index_ref_data.datadic_variables_on_admin_id"
    t.index ["equivalent_to_id"], name: "idx_dv_equiv"
    t.index ["redcap_data_dictionary_id"], name: "index_ref_data.datadic_variables_on_redcap_data_dictionary_id"
    t.index ["user_id"], name: "index_datadic_variables_on_user_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "dynamic_model_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "table_name"
    t.string "schema_name"
    t.string "primary_key_name"
    t.string "foreign_key_name"
    t.string "description"
    t.integer "admin_id"
    t.boolean "disabled"
    t.integer "position"
    t.string "category"
    t.string "table_key_name"
    t.string "field_list"
    t.string "result_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dynamic_model_id"
    t.string "options"
    t.index ["dynamic_model_id"], name: "index_dynamic_model_history_on_dynamic_model_id"
  end

  create_table "dynamic_models", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "table_name"
    t.string "schema_name"
    t.string "primary_key_name"
    t.string "foreign_key_name"
    t.string "description"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.string "category"
    t.string "table_key_name"
    t.string "field_list"
    t.string "result_order"
    t.string "options"
    t.index ["admin_id"], name: "index_dynamic_models_on_admin_id"
  end

  create_table "exception_logs", id: :serial, force: :cascade do |t|
    t.string "message"
    t.string "main"
    t.string "backtrace"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_exception_logs_on_admin_id"
    t.index ["user_id"], name: "index_exception_logs_on_user_id"
  end

  create_table "external_identifier_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.string "external_id_attribute"
    t.string "external_id_view_formatter"
    t.string "external_id_edit_pattern"
    t.boolean "prevent_edit"
    t.boolean "pregenerate_ids"
    t.bigint "min_id"
    t.bigint "max_id"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "external_identifier_id"
    t.string "extra_fields"
    t.boolean "alphanumeric"
    t.string "schema_name"
    t.string "options"
    t.index ["admin_id"], name: "index_external_identifier_history_on_admin_id"
    t.index ["external_identifier_id"], name: "index_external_identifier_history_on_external_identifier_id"
  end

  create_table "external_identifiers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.string "external_id_attribute"
    t.string "external_id_view_formatter"
    t.string "external_id_edit_pattern"
    t.boolean "prevent_edit"
    t.boolean "pregenerate_ids"
    t.bigint "min_id"
    t.bigint "max_id"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "alphanumeric"
    t.string "extra_fields"
    t.string "category"
    t.string "schema_name"
    t.string "options"
    t.index ["admin_id"], name: "index_external_identifiers_on_admin_id"
  end

  create_table "external_link_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "external_link_id"
    t.index ["external_link_id"], name: "index_external_link_history_on_external_link_id"
  end

  create_table "external_links", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.boolean "disabled"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_external_links_on_admin_id"
  end

  create_table "general_selection_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "admin_id"
    t.boolean "create_with"
    t.boolean "edit_if_set"
    t.boolean "edit_always"
    t.integer "position"
    t.string "description"
    t.boolean "lock"
    t.integer "general_selection_id"
    t.index ["general_selection_id"], name: "index_general_selection_history_on_general_selection_id"
  end

  create_table "general_selections", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.string "item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "admin_id"
    t.boolean "create_with"
    t.boolean "edit_if_set"
    t.boolean "edit_always"
    t.integer "position"
    t.string "description"
    t.boolean "lock"
    t.index ["admin_id"], name: "index_general_selections_on_admin_id"
  end

  create_table "imports", id: :serial, force: :cascade do |t|
    t.string "primary_table"
    t.integer "item_count"
    t.string "filename"
    t.integer "imported_items", array: true
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_imports_on_user_id"
  end

  create_table "imports_model_generators", force: :cascade do |t|
    t.string "name"
    t.string "dynamic_model_table"
    t.json "options"
    t.string "description"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_imports_model_generators_on_admin_id"
  end

  create_table "item_flag_history", id: :serial, force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type"
    t.integer "item_flag_name_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "item_flag_id"
    t.boolean "disabled"
    t.index ["item_flag_id"], name: "index_item_flag_history_on_item_flag_id"
  end

  create_table "item_flag_name_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "item_type"
    t.boolean "disabled"
    t.integer "admin_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "item_flag_name_id"
    t.index ["item_flag_name_id"], name: "index_item_flag_name_history_on_item_flag_name_id"
  end

  create_table "item_flag_names", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "admin_id"
    t.index ["admin_id"], name: "index_item_flag_names_on_admin_id"
  end

  create_table "item_flags", id: :serial, force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type"
    t.integer "item_flag_name_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "disabled"
    t.index ["item_flag_name_id"], name: "index_item_flags_on_item_flag_name_id"
    t.index ["user_id"], name: "index_item_flags_on_user_id"
  end

  create_table "manage_users", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "masters", id: :serial, force: :cascade do |t|
    t.integer "msid"
    t.integer "pro_id"
    t.integer "pro_info_id"
    t.integer "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "contact_id"
    t.index ["msid"], name: "index_masters_on_msid"
    t.index ["pro_id"], name: "index_masters_on_proid"
    t.index ["pro_info_id"], name: "index_masters_on_pro_info_id"
    t.index ["user_id"], name: "index_masters_on_user_id"
  end

  create_table "message_notifications", id: :serial, force: :cascade do |t|
    t.integer "app_type_id"
    t.integer "master_id"
    t.integer "user_id"
    t.integer "item_id"
    t.string "item_type"
    t.string "message_type"
    t.integer "recipient_user_ids", array: true
    t.string "layout_template_name"
    t.string "content_template_name"
    t.string "generated_content"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status_changed"
    t.string "subject"
    t.json "data"
    t.string "recipient_data", array: true
    t.string "from_user_email"
    t.string "role_name"
    t.string "content_template_text"
    t.string "importance"
    t.string "extra_substitutions"
    t.string "content_hash"
    t.index ["app_type_id"], name: "index_message_notifications_on_app_type_id"
    t.index ["master_id"], name: "index_message_notifications_on_master_id"
    t.index ["status"], name: "index_message_notifications_status"
    t.index ["user_id"], name: "index_message_notifications_on_user_id"
  end

  create_table "message_template_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "template_type"
    t.string "template"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "message_template_id"
    t.string "message_type"
    t.string "category"
    t.index ["admin_id"], name: "index_message_template_history_on_admin_id"
    t.index ["message_template_id"], name: "index_message_template_history_on_message_template_id"
  end

  create_table "message_templates", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "message_type"
    t.string "template_type"
    t.string "template"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.index ["admin_id"], name: "index_message_templates_on_admin_id"
  end

  create_table "model_references", id: :serial, force: :cascade do |t|
    t.string "from_record_type"
    t.integer "from_record_id"
    t.integer "from_record_master_id"
    t.string "to_record_type"
    t.integer "to_record_id"
    t.integer "to_record_master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.index ["from_record_master_id"], name: "index_model_references_on_from_record_master_id"
    t.index ["from_record_type", "from_record_id"], name: "index_model_references_on_from_record_type_and_from_record_id"
    t.index ["to_record_master_id"], name: "index_model_references_on_to_record_master_id"
    t.index ["to_record_type", "to_record_id"], name: "index_model_references_on_to_record_type_and_to_record_id"
    t.index ["user_id"], name: "index_model_references_on_user_id"
  end

  create_table "nfs_store_archived_file_history", id: :serial, force: :cascade do |t|
    t.string "file_hash"
    t.string "file_name"
    t.string "content_type"
    t.string "archive_file"
    t.string "path"
    t.string "file_size"
    t.string "file_updated_at"
    t.bigint "nfs_store_container_id"
    t.string "title"
    t.string "description"
    t.string "file_metadata"
    t.bigint "nfs_store_stored_file_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nfs_store_archived_file_id"
    t.index ["nfs_store_archived_file_id"], name: "index_nfs_store_archived_file_history_on_nfs_store_archived_fil"
    t.index ["user_id"], name: "index_nfs_store_archived_file_history_on_user_id"
  end

  create_table "nfs_store_archived_files", id: :serial, force: :cascade do |t|
    t.string "file_hash"
    t.string "file_name", null: false
    t.string "content_type", null: false
    t.string "archive_file", null: false
    t.string "path", null: false
    t.bigint "file_size", null: false
    t.datetime "file_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "nfs_store_container_id"
    t.integer "user_id"
    t.string "title"
    t.string "description"
    t.integer "nfs_store_stored_file_id"
    t.jsonb "file_metadata"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_archived_files_on_nfs_store_container_id"
    t.index ["nfs_store_stored_file_id"], name: "index_nfs_store_archived_files_on_nfs_store_stored_file_id"
  end

  create_table "nfs_store_container_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "name"
    t.bigint "app_type_id"
    t.bigint "orig_nfs_store_container_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nfs_store_container_id"
    t.index ["master_id"], name: "index_nfs_store_container_history_on_master_id"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_container_history_on_nfs_store_container_id"
    t.index ["user_id"], name: "index_nfs_store_container_history_on_user_id"
  end

  create_table "nfs_store_containers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.integer "app_type_id"
    t.integer "nfs_store_container_id"
    t.integer "master_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["master_id"], name: "index_nfs_store_containers_on_master_id"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_containers_on_nfs_store_container_id"
  end

  create_table "nfs_store_downloads", id: :serial, force: :cascade do |t|
    t.integer "user_groups", default: [], array: true
    t.string "path"
    t.string "retrieval_path"
    t.string "retrieved_items"
    t.integer "user_id", null: false
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nfs_store_container_ids", array: true
  end

  create_table "nfs_store_filter_history", id: :serial, force: :cascade do |t|
    t.bigint "app_type_id"
    t.string "role_name"
    t.bigint "user_id"
    t.string "resource_name"
    t.string "filter"
    t.string "description"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nfs_store_filter_id"
    t.index ["admin_id"], name: "index_nfs_store_filter_history_on_admin_id"
    t.index ["nfs_store_filter_id"], name: "index_nfs_store_filter_history_on_nfs_store_filter_id"
  end

  create_table "nfs_store_filters", id: :serial, force: :cascade do |t|
    t.integer "app_type_id"
    t.string "role_name"
    t.integer "user_id"
    t.string "resource_name"
    t.string "filter"
    t.string "description"
    t.boolean "disabled"
    t.integer "admin_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["admin_id"], name: "index_nfs_store_filters_on_admin_id"
    t.index ["app_type_id"], name: "index_nfs_store_filters_on_app_type_id"
    t.index ["user_id"], name: "index_nfs_store_filters_on_user_id"
  end

  create_table "nfs_store_imports", id: :serial, force: :cascade do |t|
    t.string "file_hash"
    t.string "file_name"
    t.integer "user_id"
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "path"
  end

  create_table "nfs_store_move_actions", id: :serial, force: :cascade do |t|
    t.integer "user_groups", array: true
    t.string "path"
    t.string "new_path"
    t.string "retrieval_path"
    t.string "moved_items"
    t.integer "nfs_store_container_ids", array: true
    t.integer "user_id", null: false
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nfs_store_stored_file_history", id: :serial, force: :cascade do |t|
    t.string "file_hash"
    t.string "file_name"
    t.string "content_type"
    t.string "path"
    t.string "file_size"
    t.string "file_updated_at"
    t.bigint "nfs_store_container_id"
    t.string "title"
    t.string "description"
    t.string "file_metadata"
    t.string "last_process_name_run"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nfs_store_stored_file_id"
    t.index ["nfs_store_stored_file_id"], name: "index_nfs_store_stored_file_history_on_nfs_store_stored_file_id"
    t.index ["user_id"], name: "index_nfs_store_stored_file_history_on_user_id"
  end

  create_table "nfs_store_stored_files", id: :serial, force: :cascade do |t|
    t.string "file_hash", null: false
    t.string "file_name", null: false
    t.string "content_type", null: false
    t.bigint "file_size", null: false
    t.string "path"
    t.datetime "file_updated_at"
    t.integer "user_id"
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title"
    t.string "description"
    t.string "last_process_name_run"
    t.jsonb "file_metadata"
    t.index ["nfs_store_container_id", "file_hash", "file_name", "path"], name: "nfs_store_stored_files_unique_file", unique: true
    t.index ["nfs_store_container_id"], name: "index_nfs_store_stored_files_on_nfs_store_container_id"
  end

  create_table "nfs_store_trash_actions", id: :serial, force: :cascade do |t|
    t.integer "user_groups", default: [], array: true
    t.string "path"
    t.string "retrieval_path"
    t.string "trashed_items"
    t.integer "nfs_store_container_ids", array: true
    t.integer "user_id", null: false
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nfs_store_uploads", id: :serial, force: :cascade do |t|
    t.string "file_hash", null: false
    t.string "file_name", null: false
    t.string "content_type", null: false
    t.bigint "file_size", null: false
    t.integer "chunk_count"
    t.boolean "completed"
    t.datetime "file_updated_at"
    t.integer "user_id"
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "path"
    t.integer "nfs_store_stored_file_id"
    t.string "upload_set"
    t.index ["nfs_store_stored_file_id"], name: "index_nfs_store_uploads_on_nfs_store_stored_file_id"
    t.index ["upload_set"], name: "index_nfs_store_uploads_on_upload_set"
  end

  create_table "nfs_store_user_file_actions", id: :serial, force: :cascade do |t|
    t.integer "user_groups", array: true
    t.string "path"
    t.string "new_path"
    t.string "action"
    t.string "retrieval_path"
    t.string "action_items"
    t.integer "nfs_store_container_ids", array: true
    t.integer "user_id", null: false
    t.integer "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_layout_history", id: :serial, force: :cascade do |t|
    t.string "layout_name"
    t.string "panel_name"
    t.string "panel_label"
    t.string "panel_position"
    t.string "options"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "page_layout_id"
    t.string "app_type_id"
    t.string "description"
    t.index ["admin_id"], name: "index_page_layout_history_on_admin_id"
    t.index ["page_layout_id"], name: "index_page_layout_history_on_page_layout_id"
  end

  create_table "page_layouts", id: :serial, force: :cascade do |t|
    t.integer "app_type_id"
    t.string "layout_name"
    t.string "panel_name"
    t.string "panel_label"
    t.integer "panel_position"
    t.string "options"
    t.boolean "disabled"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["admin_id"], name: "index_page_layouts_on_admin_id"
    t.index ["app_type_id"], name: "index_page_layouts_on_app_type_id"
  end

  create_table "player_contact_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "source"
    t.integer "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.integer "player_contact_id"
    t.index ["master_id"], name: "index_player_contact_history_on_master_id"
    t.index ["player_contact_id"], name: "index_player_contact_history_on_player_contact_id"
    t.index ["user_id"], name: "index_player_contact_history_on_user_id"
  end

  create_table "player_contacts", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "source"
    t.integer "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.index ["master_id"], name: "index_player_contacts_on_master_id"
    t.index ["user_id"], name: "index_player_contacts_on_user_id"
  end

  create_table "player_info_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "nick_name"
    t.date "birth_date"
    t.date "death_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.string "contact_pref"
    t.integer "start_year"
    t.integer "rank"
    t.string "notes"
    t.integer "contact_id"
    t.string "college"
    t.integer "end_year"
    t.string "source"
    t.integer "player_info_id"
    t.index ["master_id"], name: "index_player_info_history_on_master_id"
    t.index ["player_info_id"], name: "index_player_info_history_on_player_info_id"
    t.index ["user_id"], name: "index_player_info_history_on_user_id"
  end

  create_table "player_infos", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "nick_name"
    t.date "birth_date"
    t.date "death_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.string "contact_pref"
    t.integer "start_year"
    t.integer "rank"
    t.string "notes"
    t.integer "contact_id"
    t.string "college"
    t.integer "end_year"
    t.string "source"
    t.index ["master_id"], name: "index_player_infos_on_master_id"
    t.index ["user_id"], name: "index_player_infos_on_user_id"
  end

  create_table "pro_infos", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "pro_id"
    t.string "first_name"
    t.string "middle_name"
    t.string "nick_name"
    t.string "last_name"
    t.date "birth_date"
    t.date "death_date"
    t.integer "start_year"
    t.integer "end_year"
    t.string "college"
    t.string "birthplace"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "now()" }
    t.index ["master_id"], name: "index_pro_infos_on_master_id"
    t.index ["user_id"], name: "index_pro_infos_on_user_id"
  end

  create_table "protocol_event_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "sub_process_id"
    t.string "milestone"
    t.string "description"
    t.integer "protocol_event_id"
    t.index ["protocol_event_id"], name: "index_protocol_event_history_on_protocol_event_id"
  end

  create_table "protocol_events", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "sub_process_id"
    t.string "milestone"
    t.string "description"
    t.index ["admin_id"], name: "index_protocol_events_on_admin_id"
    t.index ["sub_process_id", "id"], name: "unique_sub_process_and_id", unique: true
    t.index ["sub_process_id"], name: "index_protocol_events_on_sub_process_id"
  end

  create_table "protocol_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "position"
    t.integer "protocol_id"
    t.index ["protocol_id"], name: "index_protocol_history_on_protocol_id"
  end

  create_table "protocols", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "position"
    t.bigint "app_type_id"
    t.index ["admin_id"], name: "index_protocols_on_admin_id"
    t.index ["app_type_id"], name: "index_protocols_on_app_type_id"
  end

  create_table "rc_cis", id: :serial, force: :cascade do |t|
    t.string "fname"
    t.string "lname"
    t.string "status"
    t.datetime "created_at", default: -> { "now()" }
    t.datetime "updated_at", default: -> { "now()" }
    t.integer "user_id"
    t.integer "master_id"
    t.string "street"
    t.string "street2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "phone"
    t.string "email"
    t.datetime "form_date"
  end

  create_table "rc_cis2", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "fname"
    t.string "lname"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "rc_stage_cif_copy", id: :serial, force: :cascade do |t|
    t.integer "record_id"
    t.integer "redcap_survey_identifier"
    t.datetime "time_stamp"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "nick_name"
    t.string "street"
    t.string "street2"
    t.string "city"
    t.string "state"
    t.string "zipcode"
    t.string "phone"
    t.string "email"
    t.string "hearabout"
    t.integer "completed"
    t.string "status"
    t.datetime "created_at", default: -> { "now()" }
    t.integer "user_id"
    t.integer "master_id"
    t.datetime "updated_at", default: -> { "now()" }
    t.boolean "added_tracker"
  end

  create_table "redcap_client_requests", comment: "Redcap client requests", force: :cascade do |t|
    t.bigint "redcap_project_admin_id"
    t.string "action"
    t.string "name"
    t.string "server_url"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "result"
    t.index ["admin_id"], name: "index_ref_data.redcap_client_requests_on_admin_id"
    t.index ["redcap_project_admin_id"], name: "idx_rcr_on_redcap_admin_id"
  end

  create_table "redcap_data_collection_instrument_history", force: :cascade do |t|
    t.bigint "redcap_data_collection_instrument_id"
    t.bigint "redcap_project_admin_id"
    t.string "name"
    t.string "label"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "idx_rdcih_on_admin_id"
    t.index ["redcap_data_collection_instrument_id"], name: "idx_h_on_rdci_id"
    t.index ["redcap_project_admin_id"], name: "idx_rdcih_on_proj_admin_id"
  end

  create_table "redcap_data_collection_instruments", force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.boolean "disabled"
    t.bigint "redcap_project_admin_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.redcap_data_collection_instruments_on_admin_id"
    t.index ["redcap_project_admin_id"], name: "idx_rdci_pa"
  end

  create_table "redcap_data_dictionaries", comment: "Retrieved Redcap Data Dictionaries (metadata)", force: :cascade do |t|
    t.bigint "redcap_project_admin_id"
    t.integer "field_count"
    t.jsonb "captured_metadata"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.redcap_data_dictionaries_on_admin_id"
    t.index ["redcap_project_admin_id"], name: "idx_on_redcap_admin_id"
  end

  create_table "redcap_data_dictionary_history", comment: "Retrieved Redcap Data Dictionaries (metadata) - history", force: :cascade do |t|
    t.bigint "redcap_data_dictionary_id"
    t.bigint "redcap_project_admin_id"
    t.integer "field_count"
    t.jsonb "captured_metadata"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.redcap_data_dictionary_history_on_admin_id"
    t.index ["redcap_data_dictionary_id"], name: "idx_history_on_redcap_data_dictionary_id"
    t.index ["redcap_project_admin_id"], name: "idx_h_on_redcap_admin_id"
  end

  create_table "redcap_project_admin_history", comment: "Redcap project administration - history", force: :cascade do |t|
    t.bigint "redcap_project_admin_id"
    t.string "name"
    t.string "api_key"
    t.string "server_url"
    t.jsonb "captured_project_info"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transfer_mode"
    t.string "frequency"
    t.string "status"
    t.string "post_transfer_pipeline", default: [], array: true
    t.string "notes"
    t.string "study"
    t.string "dynamic_model_table"
    t.index ["admin_id"], name: "index_ref_data.redcap_project_admin_history_on_admin_id"
    t.index ["redcap_project_admin_id"], name: "idx_history_on_redcap_project_admin_id"
  end

  create_table "redcap_project_admins", comment: "Redcap project administration", force: :cascade do |t|
    t.string "name"
    t.string "api_key"
    t.string "server_url"
    t.jsonb "captured_project_info"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transfer_mode"
    t.string "frequency"
    t.string "status"
    t.string "post_transfer_pipeline", default: [], array: true
    t.string "notes"
    t.string "study"
    t.string "dynamic_model_table"
    t.string "options"
    t.index ["admin_id"], name: "index_ref_data.redcap_project_admins_on_admin_id"
  end

  create_table "redcap_project_user_history", force: :cascade do |t|
    t.bigint "redcap_project_user_id"
    t.bigint "redcap_project_admin_id"
    t.string "username"
    t.string "email"
    t.string "expiration"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.redcap_project_user_history_on_admin_id"
    t.index ["redcap_project_admin_id"], name: "idx_h_on_proj_admin_id"
    t.index ["redcap_project_user_id"], name: "idx_h_on_redcap_project_user_id"
  end

  create_table "redcap_project_users", force: :cascade do |t|
    t.bigint "redcap_project_admin_id"
    t.string "username"
    t.string "email"
    t.string "expiration"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ref_data.redcap_project_users_on_admin_id"
    t.index ["redcap_project_admin_id"], name: "index_ref_data.redcap_project_users_on_redcap_project_admin_id"
  end

  create_table "report_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "sql"
    t.string "search_attrs"
    t.integer "admin_id"
    t.boolean "disabled"
    t.string "report_type"
    t.boolean "auto"
    t.boolean "searchable"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "report_id"
    t.string "item_type"
    t.string "edit_model"
    t.string "edit_field_names"
    t.string "selection_fields"
    t.string "short_name"
    t.string "options"
    t.index ["report_id"], name: "index_report_history_on_report_id"
  end

  create_table "reports", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "sql"
    t.string "search_attrs"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "report_type"
    t.boolean "auto"
    t.boolean "searchable"
    t.integer "position"
    t.string "edit_model"
    t.string "edit_field_names"
    t.string "selection_fields"
    t.string "item_type"
    t.string "short_name"
    t.string "options"
    t.index ["admin_id"], name: "index_reports_on_admin_id"
  end

  create_table "role_description_history", force: :cascade do |t|
    t.bigint "role_description_id"
    t.bigint "app_type_id"
    t.string "role_name"
    t.string "role_template"
    t.string "name"
    t.string "description"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_role_description_history_on_admin_id"
    t.index ["app_type_id"], name: "index_role_description_history_on_app_type_id"
    t.index ["role_description_id"], name: "idx_h_on_role_descriptions_id"
  end

  create_table "role_descriptions", force: :cascade do |t|
    t.bigint "app_type_id"
    t.string "role_name"
    t.string "role_template"
    t.string "name"
    t.string "description"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_role_descriptions_on_admin_id"
    t.index ["app_type_id"], name: "index_role_descriptions_on_app_type_id"
  end

  create_table "sage_assignments", id: :serial, force: :cascade do |t|
    t.string "sage_id", limit: 10
    t.string "assigned_by"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "master_id"
    t.integer "admin_id"
    t.index ["admin_id"], name: "index_sage_assignments_on_admin_id"
    t.index ["master_id"], name: "index_sage_assignments_on_master_id"
    t.index ["sage_id"], name: "index_sage_assignments_on_sage_id", unique: true
    t.index ["user_id"], name: "index_sage_assignments_on_user_id"
  end

  create_table "scantron_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "scantron_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scantron_table_id"
    t.index ["master_id"], name: "index_scantron_history_on_master_id"
    t.index ["scantron_table_id"], name: "index_scantron_history_on_scantron_table_id"
    t.index ["user_id"], name: "index_scantron_history_on_user_id"
  end

  create_table "scantrons", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "scantron_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_scantrons_on_master_id"
    t.index ["user_id"], name: "index_scantrons_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "smback", id: false, force: :cascade do |t|
    t.string "version"
  end

  create_table "sub_process_history", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "disabled"
    t.integer "protocol_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sub_process_id"
    t.index ["sub_process_id"], name: "index_sub_process_history_on_sub_process_id"
  end

  create_table "sub_processes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "disabled"
    t.integer "protocol_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_sub_processes_on_admin_id"
    t.index ["protocol_id", "id"], name: "unique_protocol_and_id", unique: true
    t.index ["protocol_id"], name: "index_sub_processes_on_protocol_id"
  end

  create_table "tracker_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "protocol_id"
    t.integer "tracker_id"
    t.datetime "event_date"
    t.integer "user_id"
    t.string "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "sub_process_id"
    t.integer "protocol_event_id"
    t.integer "item_id"
    t.string "item_type"
    t.index ["master_id"], name: "index_tracker_history_on_master_id"
    t.index ["protocol_event_id"], name: "index_tracker_history_on_protocol_event_id"
    t.index ["protocol_id"], name: "index_tracker_history_on_protocol_id"
    t.index ["sub_process_id"], name: "index_tracker_history_on_sub_process_id"
    t.index ["tracker_id"], name: "index_tracker_history_on_tracker_id"
    t.index ["user_id"], name: "index_tracker_history_on_user_id"
  end

  create_table "trackers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "protocol_id", null: false
    t.datetime "event_date"
    t.integer "user_id", default: -> { "current_user_id()" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notes"
    t.integer "sub_process_id", null: false
    t.integer "protocol_event_id"
    t.integer "item_id"
    t.string "item_type"
    t.index ["master_id", "protocol_id", "id"], name: "unique_master_protocol_id", unique: true
    t.index ["master_id", "protocol_id"], name: "unique_master_protocol", unique: true
    t.index ["master_id"], name: "index_trackers_on_master_id"
    t.index ["protocol_event_id"], name: "index_trackers_on_protocol_event_id"
    t.index ["protocol_id"], name: "index_trackers_on_protocol_id"
    t.index ["sub_process_id"], name: "index_trackers_on_sub_process_id"
    t.index ["user_id"], name: "index_trackers_on_user_id"
  end

  create_table "user_access_control_history", id: :serial, force: :cascade do |t|
    t.bigint "user_id"
    t.string "resource_type"
    t.string "resource_name"
    t.string "options"
    t.string "access"
    t.bigint "app_type_id"
    t.string "role_name"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_access_control_id"
    t.index ["admin_id"], name: "index_user_access_control_history_on_admin_id"
    t.index ["user_access_control_id"], name: "index_user_access_control_history_on_user_access_control_id"
  end

  create_table "user_access_controls", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "resource_type"
    t.string "resource_name"
    t.string "options"
    t.string "access"
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "app_type_id"
    t.string "role_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["app_type_id"], name: "index_user_access_controls_on_app_type_id"
  end

  create_table "user_action_logs", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "app_type_id"
    t.integer "master_id"
    t.string "item_type"
    t.integer "item_id"
    t.integer "index_action_ids", array: true
    t.string "action"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_type_id"], name: "index_user_action_logs_on_app_type_id"
    t.index ["master_id"], name: "index_user_action_logs_on_master_id"
    t.index ["user_id"], name: "index_user_action_logs_on_user_id"
  end

  create_table "user_authorization_history", id: :serial, force: :cascade do |t|
    t.string "user_id"
    t.string "has_authorization"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_authorization_id"
    t.index ["user_authorization_id"], name: "index_user_authorization_history_on_user_authorization_id"
  end

  create_table "user_authorizations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "has_authorization"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_description_history", force: :cascade do |t|
    t.bigint "user_description_id"
    t.bigint "app_type_id"
    t.string "role_name"
    t.string "role_template"
    t.string "name"
    t.string "description"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_user_description_history_on_admin_id"
    t.index ["app_type_id"], name: "index_user_description_history_on_app_type_id"
    t.index ["user_description_id"], name: "idx_h_on_user_descriptions_id"
  end

  create_table "user_descriptions", force: :cascade do |t|
    t.bigint "app_type_id"
    t.string "role_name"
    t.string "role_template"
    t.string "name"
    t.string "description"
    t.boolean "disabled"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_user_descriptions_on_admin_id"
    t.index ["app_type_id"], name: "index_user_descriptions_on_app_type_id"
  end

  create_table "user_history", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "user_id"
    t.integer "app_type_id"
    t.string "authentication_token"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.datetime "password_updated_at"
    t.string "first_name"
    t.string "last_name"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.index ["app_type_id"], name: "index_user_history_on_app_type_id"
    t.index ["user_id"], name: "index_user_history_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id"
    t.string "date_format"
    t.string "date_time_format"
    t.string "pattern_for_date_format"
    t.string "pattern_for_date_time_format"
    t.string "pattern_for_time_format"
    t.string "time_format"
    t.string "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "user_role_history", id: :serial, force: :cascade do |t|
    t.bigint "app_type_id"
    t.string "role_name"
    t.bigint "user_id"
    t.integer "admin_id"
    t.boolean "disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_role_id"
    t.index ["admin_id"], name: "index_user_role_history_on_admin_id"
    t.index ["user_role_id"], name: "index_user_role_history_on_user_role_id"
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "app_type_id"
    t.string "role_name"
    t.integer "user_id"
    t.integer "admin_id"
    t.boolean "disabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_user_roles_on_admin_id"
    t.index ["app_type_id"], name: "index_user_roles_on_app_type_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "disabled"
    t.integer "admin_id"
    t.integer "app_type_id"
    t.string "authentication_token", limit: 30
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.datetime "password_updated_at"
    t.string "first_name"
    t.string "last_name"
    t.boolean "do_not_email", default: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.index ["admin_id"], name: "index_users_on_admin_id"
    t.index ["app_type_id"], name: "index_users_on_app_type_id"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "users_contact_infos", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "sms_number"
    t.string "phone_number"
    t.string "alt_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin_id"
    t.boolean "disabled"
    t.index ["admin_id"], name: "index_users_contact_infos_on_admin_id"
    t.index ["user_id"], name: "index_users_contact_infos_on_user_id"
  end

  add_foreign_key "accuracy_score_history", "accuracy_scores", name: "fk_accuracy_score_history_accuracy_scores"
  add_foreign_key "accuracy_scores", "admins"
  add_foreign_key "activity_log_history", "activity_logs"
  add_foreign_key "activity_log_player_contact_phone_history", "activity_log_player_contact_phones", name: "fk_activity_log_player_contact_phone_history_activity_log_playe"
  add_foreign_key "activity_log_player_contact_phone_history", "masters", name: "fk_activity_log_player_contact_phone_history_masters"
  add_foreign_key "activity_log_player_contact_phone_history", "player_contacts", name: "fk_activity_log_player_contact_phone_history_player_contact_pho"
  add_foreign_key "activity_log_player_contact_phone_history", "users", name: "fk_activity_log_player_contact_phone_history_users"
  add_foreign_key "activity_log_player_contact_phones", "masters"
  add_foreign_key "activity_log_player_contact_phones", "player_contacts"
  add_foreign_key "activity_log_player_contact_phones", "protocols"
  add_foreign_key "activity_log_player_contact_phones", "users"
  add_foreign_key "address_history", "addresses", name: "fk_address_history_addresses"
  add_foreign_key "address_history", "masters", name: "fk_address_history_masters"
  add_foreign_key "address_history", "users", name: "fk_address_history_users"
  add_foreign_key "addresses", "masters"
  add_foreign_key "addresses", "users"
  add_foreign_key "admin_action_logs", "admins"
  add_foreign_key "admin_history", "admins", column: "updated_by_admin_id", name: "fk_admin_history_upd_admins"
  add_foreign_key "admin_history", "admins", name: "fk_admin_history_admins"
  add_foreign_key "admins", "admins"
  add_foreign_key "app_configuration_history", "admins", name: "fk_app_configuration_history_admins"
  add_foreign_key "app_configuration_history", "app_configurations", name: "fk_app_configuration_history_app_configurations"
  add_foreign_key "app_configurations", "admins"
  add_foreign_key "app_configurations", "app_types"
  add_foreign_key "app_configurations", "users"
  add_foreign_key "app_type_history", "admins", name: "fk_app_type_history_admins"
  add_foreign_key "app_type_history", "app_types", name: "fk_app_type_history_app_types"
  add_foreign_key "app_types", "admins"
  add_foreign_key "college_history", "colleges", name: "fk_college_history_colleges"
  add_foreign_key "colleges", "admins"
  add_foreign_key "colleges", "users"
  add_foreign_key "config_libraries", "admins"
  add_foreign_key "config_library_history", "admins"
  add_foreign_key "config_library_history", "config_libraries"
  add_foreign_key "datadic_choice_history", "admins"
  add_foreign_key "datadic_choice_history", "datadic_choices"
  add_foreign_key "datadic_choice_history", "redcap_data_dictionaries"
  add_foreign_key "datadic_choices", "admins"
  add_foreign_key "datadic_choices", "redcap_data_dictionaries"
  add_foreign_key "datadic_variable_history", "admins"
  add_foreign_key "datadic_variable_history", "datadic_variables"
  add_foreign_key "datadic_variable_history", "datadic_variables", column: "equivalent_to_id"
  add_foreign_key "datadic_variable_history", "redcap_data_dictionaries"
  add_foreign_key "datadic_variable_history", "users"
  add_foreign_key "datadic_variables", "admins"
  add_foreign_key "datadic_variables", "datadic_variables", column: "equivalent_to_id"
  add_foreign_key "datadic_variables", "redcap_data_dictionaries"
  add_foreign_key "datadic_variables", "users"
  add_foreign_key "dynamic_model_history", "dynamic_models", name: "fk_dynamic_model_history_dynamic_models"
  add_foreign_key "dynamic_models", "admins"
  add_foreign_key "exception_logs", "admins"
  add_foreign_key "exception_logs", "users"
  add_foreign_key "external_identifier_history", "admins"
  add_foreign_key "external_identifier_history", "external_identifiers"
  add_foreign_key "external_identifiers", "admins"
  add_foreign_key "external_link_history", "external_links", name: "fk_external_link_history_external_links"
  add_foreign_key "external_links", "admins"
  add_foreign_key "general_selection_history", "general_selections", name: "fk_general_selection_history_general_selections"
  add_foreign_key "general_selections", "admins"
  add_foreign_key "imports", "users"
  add_foreign_key "imports_model_generators", "admins"
  add_foreign_key "item_flag_history", "item_flags", name: "fk_item_flag_history_item_flags"
  add_foreign_key "item_flag_name_history", "item_flag_names", name: "fk_item_flag_name_history_item_flag_names"
  add_foreign_key "item_flag_names", "admins"
  add_foreign_key "item_flags", "item_flag_names"
  add_foreign_key "item_flags", "users"
  add_foreign_key "masters", "users"
  add_foreign_key "message_notifications", "app_types"
  add_foreign_key "message_notifications", "masters"
  add_foreign_key "message_notifications", "users"
  add_foreign_key "message_template_history", "admins", name: "fk_message_template_history_admins"
  add_foreign_key "message_template_history", "message_templates", name: "fk_message_template_history_message_templates"
  add_foreign_key "message_templates", "admins"
  add_foreign_key "model_references", "masters", column: "from_record_master_id"
  add_foreign_key "model_references", "masters", column: "to_record_master_id"
  add_foreign_key "model_references", "users"
  add_foreign_key "nfs_store_archived_file_history", "nfs_store_archived_files", name: "fk_nfs_store_archived_file_history_nfs_store_archived_files"
  add_foreign_key "nfs_store_archived_file_history", "users", name: "fk_nfs_store_archived_file_history_users"
  add_foreign_key "nfs_store_archived_files", "nfs_store_containers"
  add_foreign_key "nfs_store_archived_files", "nfs_store_stored_files"
  add_foreign_key "nfs_store_archived_files", "users"
  add_foreign_key "nfs_store_container_history", "masters", name: "fk_nfs_store_container_history_masters"
  add_foreign_key "nfs_store_container_history", "nfs_store_containers", name: "fk_nfs_store_container_history_nfs_store_containers"
  add_foreign_key "nfs_store_container_history", "users", name: "fk_nfs_store_container_history_users"
  add_foreign_key "nfs_store_containers", "app_types"
  add_foreign_key "nfs_store_containers", "masters"
  add_foreign_key "nfs_store_containers", "nfs_store_containers"
  add_foreign_key "nfs_store_containers", "users"
  add_foreign_key "nfs_store_downloads", "nfs_store_containers"
  add_foreign_key "nfs_store_downloads", "users"
  add_foreign_key "nfs_store_filter_history", "admins", name: "fk_nfs_store_filter_history_admins"
  add_foreign_key "nfs_store_filter_history", "nfs_store_filters", name: "fk_nfs_store_filter_history_nfs_store_filters"
  add_foreign_key "nfs_store_filters", "admins"
  add_foreign_key "nfs_store_filters", "app_types"
  add_foreign_key "nfs_store_filters", "users"
  add_foreign_key "nfs_store_imports", "nfs_store_containers"
  add_foreign_key "nfs_store_imports", "users"
  add_foreign_key "nfs_store_move_actions", "nfs_store_containers"
  add_foreign_key "nfs_store_move_actions", "users"
  add_foreign_key "nfs_store_stored_file_history", "nfs_store_stored_files", name: "fk_nfs_store_stored_file_history_nfs_store_stored_files"
  add_foreign_key "nfs_store_stored_file_history", "users", name: "fk_nfs_store_stored_file_history_users"
  add_foreign_key "nfs_store_stored_files", "nfs_store_containers"
  add_foreign_key "nfs_store_stored_files", "users"
  add_foreign_key "nfs_store_trash_actions", "nfs_store_containers"
  add_foreign_key "nfs_store_trash_actions", "users"
  add_foreign_key "nfs_store_uploads", "nfs_store_containers"
  add_foreign_key "nfs_store_uploads", "nfs_store_stored_files"
  add_foreign_key "nfs_store_uploads", "users"
  add_foreign_key "nfs_store_user_file_actions", "nfs_store_containers"
  add_foreign_key "nfs_store_user_file_actions", "users"
  add_foreign_key "page_layout_history", "admins", name: "fk_page_layout_history_admins"
  add_foreign_key "page_layout_history", "page_layouts", name: "fk_page_layout_history_page_layouts"
  add_foreign_key "page_layouts", "admins"
  add_foreign_key "page_layouts", "app_types"
  add_foreign_key "player_contact_history", "masters", name: "fk_player_contact_history_masters"
  add_foreign_key "player_contact_history", "player_contacts", name: "fk_player_contact_history_player_contacts"
  add_foreign_key "player_contact_history", "users", name: "fk_player_contact_history_users"
  add_foreign_key "player_contacts", "masters"
  add_foreign_key "player_contacts", "users"
  add_foreign_key "player_info_history", "masters", name: "fk_player_info_history_masters"
  add_foreign_key "player_info_history", "player_infos", name: "fk_player_info_history_player_infos"
  add_foreign_key "player_info_history", "users", name: "fk_player_info_history_users"
  add_foreign_key "player_infos", "masters"
  add_foreign_key "player_infos", "users"
  add_foreign_key "pro_infos", "masters"
  add_foreign_key "pro_infos", "users"
  add_foreign_key "protocol_event_history", "protocol_events", name: "fk_protocol_event_history_protocol_events"
  add_foreign_key "protocol_events", "admins"
  add_foreign_key "protocol_events", "sub_processes"
  add_foreign_key "protocol_history", "protocols", name: "fk_protocol_history_protocols"
  add_foreign_key "protocols", "admins"
  add_foreign_key "protocols", "app_types"
  add_foreign_key "rc_cis", "masters", name: "rc_cis_master_id_fkey"
  add_foreign_key "redcap_client_requests", "redcap_project_admins"
  add_foreign_key "redcap_data_collection_instrument_history", "admins"
  add_foreign_key "redcap_data_collection_instrument_history", "redcap_data_collection_instruments"
  add_foreign_key "redcap_data_collection_instrument_history", "redcap_project_admins"
  add_foreign_key "redcap_data_collection_instruments", "admins"
  add_foreign_key "redcap_data_dictionaries", "admins"
  add_foreign_key "redcap_data_dictionaries", "redcap_project_admins"
  add_foreign_key "redcap_data_dictionary_history", "admins"
  add_foreign_key "redcap_data_dictionary_history", "redcap_data_dictionaries"
  add_foreign_key "redcap_data_dictionary_history", "redcap_project_admins"
  add_foreign_key "redcap_project_admin_history", "redcap_project_admins"
  add_foreign_key "redcap_project_user_history", "admins"
  add_foreign_key "redcap_project_user_history", "redcap_project_admins"
  add_foreign_key "redcap_project_user_history", "redcap_project_users"
  add_foreign_key "redcap_project_users", "admins"
  add_foreign_key "redcap_project_users", "redcap_project_admins"
  add_foreign_key "report_history", "reports", name: "fk_report_history_reports"
  add_foreign_key "reports", "admins"
  add_foreign_key "role_description_history", "admins"
  add_foreign_key "role_description_history", "app_types"
  add_foreign_key "role_description_history", "role_descriptions"
  add_foreign_key "role_descriptions", "admins"
  add_foreign_key "role_descriptions", "app_types"
  add_foreign_key "sage_assignments", "admins"
  add_foreign_key "sage_assignments", "masters"
  add_foreign_key "sage_assignments", "users"
  add_foreign_key "scantron_history", "masters", name: "fk_scantron_history_masters"
  add_foreign_key "scantron_history", "scantrons", column: "scantron_table_id", name: "fk_scantron_history_scantrons"
  add_foreign_key "scantron_history", "users", name: "fk_scantron_history_users"
  add_foreign_key "scantrons", "masters"
  add_foreign_key "scantrons", "users"
  add_foreign_key "sub_process_history", "sub_processes", name: "fk_sub_process_history_sub_processes"
  add_foreign_key "sub_processes", "admins"
  add_foreign_key "sub_processes", "protocols"
  add_foreign_key "tracker_history", "masters"
  add_foreign_key "tracker_history", "protocol_events"
  add_foreign_key "tracker_history", "protocol_events", column: "sub_process_id", primary_key: "sub_process_id", name: "valid_sub_process_event"
  add_foreign_key "tracker_history", "protocols"
  add_foreign_key "tracker_history", "sub_processes"
  add_foreign_key "tracker_history", "sub_processes", column: "protocol_id", primary_key: "protocol_id", name: "valid_protocol_sub_process"
  add_foreign_key "tracker_history", "trackers"
  add_foreign_key "tracker_history", "trackers", column: "master_id", primary_key: "master_id", name: "unique_master_protocol_tracker_id"
  add_foreign_key "tracker_history", "users"
  add_foreign_key "trackers", "masters"
  add_foreign_key "trackers", "protocol_events"
  add_foreign_key "trackers", "protocol_events", column: "sub_process_id", primary_key: "sub_process_id", name: "valid_sub_process_event"
  add_foreign_key "trackers", "protocols"
  add_foreign_key "trackers", "sub_processes"
  add_foreign_key "trackers", "sub_processes", column: "protocol_id", primary_key: "protocol_id", name: "valid_protocol_sub_process"
  add_foreign_key "trackers", "users"
  add_foreign_key "user_access_control_history", "admins", name: "fk_user_access_control_history_admins"
  add_foreign_key "user_access_control_history", "user_access_controls", name: "fk_user_access_control_history_user_access_controls"
  add_foreign_key "user_access_controls", "app_types"
  add_foreign_key "user_action_logs", "app_types"
  add_foreign_key "user_action_logs", "masters"
  add_foreign_key "user_action_logs", "users"
  add_foreign_key "user_authorization_history", "user_authorizations", name: "fk_user_authorization_history_user_authorizations"
  add_foreign_key "user_description_history", "admins"
  add_foreign_key "user_description_history", "app_types"
  add_foreign_key "user_description_history", "user_descriptions"
  add_foreign_key "user_descriptions", "admins"
  add_foreign_key "user_descriptions", "app_types"
  add_foreign_key "user_history", "app_types"
  add_foreign_key "user_history", "users", name: "fk_user_history_users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_role_history", "admins", name: "fk_user_role_history_admins"
  add_foreign_key "user_role_history", "user_roles", name: "fk_user_role_history_user_roles"
  add_foreign_key "user_roles", "admins"
  add_foreign_key "user_roles", "app_types"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "admins"
  add_foreign_key "users", "app_types"
  add_foreign_key "users_contact_infos", "admins"
  add_foreign_key "users_contact_infos", "users"
end
