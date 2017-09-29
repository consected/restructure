# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 0) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accuracy_score_history", force: :cascade do |t|
    t.string   "name"
    t.integer  "value"
    t.integer  "admin_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.boolean  "disabled"
    t.integer  "accuracy_score_id"
  end

  add_index "accuracy_score_history", ["accuracy_score_id"], name: "index_accuracy_score_history_on_accuracy_score_id", using: :btree

  create_table "accuracy_scores", force: :cascade do |t|
    t.string   "name"
    t.integer  "value"
    t.integer  "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "disabled"
  end

  add_index "accuracy_scores", ["admin_id"], name: "index_accuracy_scores_on_admin_id", using: :btree

  create_table "address_history", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "street"
    t.string   "street2"
    t.string   "street3"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "source"
    t.integer  "rank"
    t.string   "rec_type"
    t.integer  "user_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",            default: "now()"
    t.string   "country",     limit: 3
    t.string   "postal_code"
    t.string   "region"
    t.integer  "address_id"
  end

  add_index "address_history", ["address_id"], name: "index_address_history_on_address_id", using: :btree
  add_index "address_history", ["master_id"], name: "index_address_history_on_master_id", using: :btree
  add_index "address_history", ["user_id"], name: "index_address_history_on_user_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "street"
    t.string   "street2"
    t.string   "street3"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "source"
    t.integer  "rank"
    t.string   "rec_type"
    t.integer  "user_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",            default: "now()"
    t.string   "country",     limit: 3
    t.string   "postal_code"
    t.string   "region"
  end

  add_index "addresses", ["master_id"], name: "index_addresses_on_master_id", using: :btree
  add_index "addresses", ["user_id"], name: "index_addresses_on_user_id", using: :btree

  create_table "admin_history", force: :cascade do |t|
    t.string   "email",              default: "", null: false
    t.string   "encrypted_password", default: "", null: false
    t.integer  "sign_in_count",      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",    default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "disabled"
    t.integer  "admin_id"
  end

  add_index "admin_history", ["admin_id"], name: "index_admin_history_on_admin_id", using: :btree

  create_table "admins", force: :cascade do |t|
    t.string   "email",              default: "", null: false
    t.string   "encrypted_password", default: "", null: false
    t.integer  "sign_in_count",      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",    default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "disabled"
  end

  create_table "college_history", force: :cascade do |t|
    t.string   "name"
    t.integer  "synonym_for_id"
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "college_id"
  end

  add_index "college_history", ["college_id"], name: "index_college_history_on_college_id", using: :btree

  create_table "colleges", force: :cascade do |t|
    t.string   "name"
    t.integer  "synonym_for_id"
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "colleges", ["admin_id"], name: "index_colleges_on_admin_id", using: :btree
  add_index "colleges", ["user_id"], name: "index_colleges_on_user_id", using: :btree

  create_table "copy_player_infos", id: false, force: :cascade do |t|
    t.integer  "id"
    t.integer  "master_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "middle_name"
    t.string   "nick_name"
    t.date     "birth_date"
    t.date     "death_date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contact_pref"
    t.integer  "start_year"
    t.integer  "rank"
    t.string   "notes"
    t.integer  "contactid"
    t.string   "college"
    t.integer  "end_year"
    t.string   "source"
  end

  create_table "dynamic_model_history", force: :cascade do |t|
    t.string   "name"
    t.string   "table_name"
    t.string   "schema_name"
    t.string   "primary_key_name"
    t.string   "foreign_key_name"
    t.string   "description"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.integer  "position"
    t.string   "category"
    t.string   "table_key_name"
    t.string   "field_list"
    t.string   "result_order"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "dynamic_model_id"
  end

  add_index "dynamic_model_history", ["dynamic_model_id"], name: "index_dynamic_model_history_on_dynamic_model_id", using: :btree

  create_table "dynamic_models", force: :cascade do |t|
    t.string   "name"
    t.string   "table_name"
    t.string   "schema_name"
    t.string   "primary_key_name"
    t.string   "foreign_key_name"
    t.string   "description"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "position"
    t.string   "category"
    t.string   "table_key_name"
    t.string   "field_list"
    t.string   "result_order"
  end

  add_index "dynamic_models", ["admin_id"], name: "index_dynamic_models_on_admin_id", using: :btree

  create_table "external_link_history", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "external_link_id"
  end

  add_index "external_link_history", ["external_link_id"], name: "index_external_link_history_on_external_link_id", using: :btree

  create_table "external_links", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "external_links", ["admin_id"], name: "index_external_links_on_admin_id", using: :btree

  create_table "general_selection_history", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.string   "item_type"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.boolean  "create_with"
    t.boolean  "edit_if_set"
    t.boolean  "edit_always"
    t.integer  "position"
    t.string   "description"
    t.boolean  "lock"
    t.integer  "general_selection_id"
  end

  add_index "general_selection_history", ["general_selection_id"], name: "index_general_selection_history_on_general_selection_id", using: :btree

  create_table "general_selections", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.string   "item_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.boolean  "create_with"
    t.boolean  "edit_if_set"
    t.boolean  "edit_always"
    t.integer  "position"
    t.string   "description"
    t.boolean  "lock"
  end

  add_index "general_selections", ["admin_id"], name: "index_general_selections_on_admin_id", using: :btree

  create_table "item_flag_history", force: :cascade do |t|
    t.integer  "item_id"
    t.string   "item_type"
    t.integer  "item_flag_name_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "user_id"
    t.integer  "item_flag_id"
    t.boolean  "disabled"
  end

  add_index "item_flag_history", ["item_flag_id"], name: "index_item_flag_history_on_item_flag_id", using: :btree

  create_table "item_flag_name_history", force: :cascade do |t|
    t.string   "name"
    t.string   "item_type"
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "item_flag_name_id"
  end

  add_index "item_flag_name_history", ["item_flag_name_id"], name: "index_item_flag_name_history_on_item_flag_name_id", using: :btree

  create_table "item_flag_names", force: :cascade do |t|
    t.string   "name"
    t.string   "item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
  end

  add_index "item_flag_names", ["admin_id"], name: "index_item_flag_names_on_admin_id", using: :btree

  create_table "item_flags", force: :cascade do |t|
    t.integer  "item_id"
    t.string   "item_type"
    t.integer  "item_flag_name_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "user_id"
    t.boolean  "disabled"
  end

  add_index "item_flags", ["item_flag_name_id"], name: "index_item_flags_on_item_flag_name_id", using: :btree
  add_index "item_flags", ["user_id"], name: "index_item_flags_on_user_id", using: :btree

  create_table "manage_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "masters", force: :cascade do |t|
    t.integer  "msid"
    t.integer  "pro_id"
    t.integer  "pro_info_id"
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "contact_id"
  end

  add_index "masters", ["msid"], name: "index_masters_on_msid", using: :btree
  add_index "masters", ["pro_id"], name: "index_masters_on_proid", using: :btree
  add_index "masters", ["pro_info_id"], name: "index_masters_on_pro_info_id", using: :btree
  add_index "masters", ["user_id"], name: "index_masters_on_user_id", using: :btree

  create_table "player_contact_history", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "rec_type"
    t.string   "data"
    t.string   "source"
    t.integer  "rank"
    t.integer  "user_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",        default: "now()"
    t.integer  "player_contact_id"
  end

  add_index "player_contact_history", ["master_id"], name: "index_player_contact_history_on_master_id", using: :btree
  add_index "player_contact_history", ["player_contact_id"], name: "index_player_contact_history_on_player_contact_id", using: :btree
  add_index "player_contact_history", ["user_id"], name: "index_player_contact_history_on_user_id", using: :btree

  create_table "player_contacts", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "rec_type"
    t.string   "data"
    t.string   "source"
    t.integer  "rank"
    t.integer  "user_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at", default: "now()"
  end

  add_index "player_contacts", ["master_id"], name: "index_player_contacts_on_master_id", using: :btree
  add_index "player_contacts", ["user_id"], name: "index_player_contacts_on_user_id", using: :btree

  create_table "player_info_history", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "middle_name"
    t.string   "nick_name"
    t.date     "birth_date"
    t.date     "death_date"
    t.integer  "user_id"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",     default: "now()"
    t.string   "contact_pref"
    t.integer  "start_year"
    t.integer  "rank"
    t.string   "notes"
    t.integer  "contact_id"
    t.string   "college"
    t.integer  "end_year"
    t.string   "source"
    t.integer  "player_info_id"
  end

  add_index "player_info_history", ["master_id"], name: "index_player_info_history_on_master_id", using: :btree
  add_index "player_info_history", ["player_info_id"], name: "index_player_info_history_on_player_info_id", using: :btree
  add_index "player_info_history", ["user_id"], name: "index_player_info_history_on_user_id", using: :btree

  create_table "player_infos", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "middle_name"
    t.string   "nick_name"
    t.date     "birth_date"
    t.date     "death_date"
    t.integer  "user_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",   default: "now()"
    t.string   "contact_pref"
    t.integer  "start_year"
    t.integer  "rank"
    t.string   "notes"
    t.integer  "contact_id"
    t.string   "college"
    t.integer  "end_year"
    t.string   "source"
  end

  add_index "player_infos", ["master_id"], name: "index_player_infos_on_master_id", using: :btree
  add_index "player_infos", ["user_id"], name: "index_player_infos_on_user_id", using: :btree

  create_table "pro_infos", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "pro_id"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "nick_name"
    t.string   "last_name"
    t.date     "birth_date"
    t.date     "death_date"
    t.integer  "start_year"
    t.integer  "end_year"
    t.string   "college"
    t.string   "birthplace"
    t.integer  "user_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",  default: "now()"
  end

  add_index "pro_infos", ["master_id"], name: "index_pro_infos_on_master_id", using: :btree
  add_index "pro_infos", ["user_id"], name: "index_pro_infos_on_user_id", using: :btree

  create_table "protocol_event_history", force: :cascade do |t|
    t.string   "name"
    t.integer  "admin_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.boolean  "disabled"
    t.integer  "sub_process_id"
    t.string   "milestone"
    t.string   "description"
    t.integer  "protocol_event_id"
  end

  add_index "protocol_event_history", ["protocol_event_id"], name: "index_protocol_event_history_on_protocol_event_id", using: :btree

  create_table "protocol_events", force: :cascade do |t|
    t.string   "name"
    t.integer  "admin_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.boolean  "disabled"
    t.integer  "sub_process_id"
    t.string   "milestone"
    t.string   "description"
  end

  add_index "protocol_events", ["admin_id"], name: "index_protocol_events_on_admin_id", using: :btree
  add_index "protocol_events", ["sub_process_id", "id"], name: "unique_sub_process_and_id", unique: true, using: :btree
  add_index "protocol_events", ["sub_process_id"], name: "index_protocol_events_on_sub_process_id", using: :btree

  create_table "protocol_history", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.integer  "position"
    t.integer  "protocol_id"
  end

  add_index "protocol_history", ["protocol_id"], name: "index_protocol_history_on_protocol_id", using: :btree

  create_table "protocols", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.integer  "position"
  end

  add_index "protocols", ["admin_id"], name: "index_protocols_on_admin_id", using: :btree

  create_table "rc_cis", force: :cascade do |t|
    t.string   "fname"
    t.string   "lname"
    t.string   "status"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
    t.integer  "user_id"
    t.integer  "master_id"
    t.string   "street"
    t.string   "street2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone"
    t.string   "email"
    t.datetime "form_date"
  end

  create_table "rc_cis2", id: false, force: :cascade do |t|
    t.integer  "id"
    t.string   "fname"
    t.string   "lname"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "rc_stage_cif_copy", force: :cascade do |t|
    t.integer  "record_id"
    t.integer  "redcap_survey_identifier"
    t.datetime "time_stamp"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "nick_name"
    t.string   "street"
    t.string   "street2"
    t.string   "city"
    t.string   "state"
    t.string   "zipcode"
    t.string   "phone"
    t.string   "email"
    t.string   "hearabout"
    t.integer  "completed"
    t.string   "status"
    t.datetime "created_at",               default: "now()"
    t.integer  "user_id"
    t.integer  "master_id"
    t.datetime "updated_at",               default: "now()"
    t.boolean  "added_tracker"
  end

  create_table "report_history", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "sql"
    t.string   "search_attrs"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.string   "report_type"
    t.boolean  "auto"
    t.boolean  "searchable"
    t.integer  "position"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "report_id"
    t.string   "item_type"
    t.string   "edit_model"
    t.string   "edit_field_names"
    t.string   "selection_fields"
  end

  add_index "report_history", ["report_id"], name: "index_report_history_on_report_id", using: :btree

  create_table "reports", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "sql"
    t.string   "search_attrs"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "report_type"
    t.boolean  "auto"
    t.boolean  "searchable"
    t.integer  "position"
    t.string   "edit_model"
    t.string   "edit_field_names"
    t.string   "selection_fields"
    t.string   "item_type"
  end

  add_index "reports", ["admin_id"], name: "index_reports_on_admin_id", using: :btree

  create_table "sage_assignments", force: :cascade do |t|
    t.string   "sage_id",     limit: 10
    t.string   "assigned_by"
    t.integer  "user_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "master_id"
    t.integer  "admin_id"
  end

  add_index "sage_assignments", ["admin_id"], name: "index_sage_assignments_on_admin_id", using: :btree
  add_index "sage_assignments", ["master_id"], name: "index_sage_assignments_on_master_id", using: :btree
  add_index "sage_assignments", ["sage_id"], name: "index_sage_assignments_on_sage_id", unique: true, using: :btree
  add_index "sage_assignments", ["user_id"], name: "index_sage_assignments_on_user_id", using: :btree

  create_table "scantron_history", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "scantron_id"
    t.integer  "user_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "scantron_table_id"
  end

  add_index "scantron_history", ["master_id"], name: "index_scantron_history_on_master_id", using: :btree
  add_index "scantron_history", ["scantron_table_id"], name: "index_scantron_history_on_scantron_table_id", using: :btree
  add_index "scantron_history", ["user_id"], name: "index_scantron_history_on_user_id", using: :btree

  create_table "scantrons", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "scantron_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "scantrons", ["master_id"], name: "index_scantrons_on_master_id", using: :btree
  add_index "scantrons", ["user_id"], name: "index_scantrons_on_user_id", using: :btree

  create_table "smback", id: false, force: :cascade do |t|
    t.string "version"
  end

  create_table "sub_process_history", force: :cascade do |t|
    t.string   "name"
    t.boolean  "disabled"
    t.integer  "protocol_id"
    t.integer  "admin_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "sub_process_id"
  end

  add_index "sub_process_history", ["sub_process_id"], name: "index_sub_process_history_on_sub_process_id", using: :btree

  create_table "sub_processes", force: :cascade do |t|
    t.string   "name"
    t.boolean  "disabled"
    t.integer  "protocol_id"
    t.integer  "admin_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sub_processes", ["admin_id"], name: "index_sub_processes_on_admin_id", using: :btree
  add_index "sub_processes", ["protocol_id", "id"], name: "unique_protocol_and_id", unique: true, using: :btree
  add_index "sub_processes", ["protocol_id"], name: "index_sub_processes_on_protocol_id", using: :btree

  create_table "tracker_history", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "protocol_id"
    t.integer  "tracker_id"
    t.datetime "event_date"
    t.integer  "user_id"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sub_process_id"
    t.integer  "protocol_event_id"
    t.integer  "item_id"
    t.string   "item_type"
  end

  add_index "tracker_history", ["master_id"], name: "index_tracker_history_on_master_id", using: :btree
  add_index "tracker_history", ["protocol_event_id"], name: "index_tracker_history_on_protocol_event_id", using: :btree
  add_index "tracker_history", ["protocol_id"], name: "index_tracker_history_on_protocol_id", using: :btree
  add_index "tracker_history", ["sub_process_id"], name: "index_tracker_history_on_sub_process_id", using: :btree
  add_index "tracker_history", ["tracker_id"], name: "index_tracker_history_on_tracker_id", using: :btree
  add_index "tracker_history", ["user_id"], name: "index_tracker_history_on_user_id", using: :btree

  create_table "trackers", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "protocol_id",                                     null: false
    t.datetime "event_date"
    t.integer  "user_id",           default: "current_user_id()"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "notes"
    t.integer  "sub_process_id",                                  null: false
    t.integer  "protocol_event_id"
    t.integer  "item_id"
    t.string   "item_type"
  end

  add_index "trackers", ["master_id", "protocol_id", "id"], name: "unique_master_protocol_id", unique: true, using: :btree
  add_index "trackers", ["master_id", "protocol_id"], name: "unique_master_protocol", unique: true, using: :btree
  add_index "trackers", ["master_id"], name: "index_trackers_on_master_id", using: :btree
  add_index "trackers", ["protocol_event_id"], name: "index_trackers_on_protocol_event_id", using: :btree
  add_index "trackers", ["protocol_id"], name: "index_trackers_on_protocol_id", using: :btree
  add_index "trackers", ["sub_process_id"], name: "index_trackers_on_sub_process_id", using: :btree
  add_index "trackers", ["user_id"], name: "index_trackers_on_user_id", using: :btree

  create_table "user_authorization_history", force: :cascade do |t|
    t.string   "user_id"
    t.string   "has_authorization"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "user_authorization_id"
  end

  add_index "user_authorization_history", ["user_authorization_id"], name: "index_user_authorization_history_on_user_authorization_id", using: :btree

  create_table "user_authorizations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "has_authorization"
    t.integer  "admin_id"
    t.boolean  "disabled"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "user_history", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.integer  "user_id"
  end

  add_index "user_history", ["user_id"], name: "index_user_history_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.boolean  "disabled"
    t.integer  "admin_id"
  end

  add_index "users", ["admin_id"], name: "index_users_on_admin_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "accuracy_score_history", "accuracy_scores", name: "fk_accuracy_score_history_accuracy_scores"
  add_foreign_key "accuracy_scores", "admins"
  add_foreign_key "address_history", "addresses", name: "fk_address_history_addresses"
  add_foreign_key "address_history", "masters", name: "fk_address_history_masters"
  add_foreign_key "address_history", "users", name: "fk_address_history_users"
  add_foreign_key "addresses", "masters"
  add_foreign_key "addresses", "users"
  add_foreign_key "admin_history", "admins", name: "fk_admin_history_admins"
  add_foreign_key "college_history", "colleges", name: "fk_college_history_colleges"
  add_foreign_key "colleges", "admins"
  add_foreign_key "colleges", "users"
  add_foreign_key "dynamic_model_history", "dynamic_models", name: "fk_dynamic_model_history_dynamic_models"
  add_foreign_key "dynamic_models", "admins"
  add_foreign_key "external_link_history", "external_links", name: "fk_external_link_history_external_links"
  add_foreign_key "external_links", "admins"
  add_foreign_key "general_selection_history", "general_selections", name: "fk_general_selection_history_general_selections"
  add_foreign_key "general_selections", "admins"
  add_foreign_key "item_flag_history", "item_flags", name: "fk_item_flag_history_item_flags"
  add_foreign_key "item_flag_name_history", "item_flag_names", name: "fk_item_flag_name_history_item_flag_names"
  add_foreign_key "item_flag_names", "admins"
  add_foreign_key "item_flags", "item_flag_names"
  add_foreign_key "item_flags", "users"
  add_foreign_key "masters", "pro_infos"
  add_foreign_key "masters", "users"
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
  add_foreign_key "rc_cis", "masters", name: "rc_cis_master_id_fkey"
  add_foreign_key "report_history", "reports", name: "fk_report_history_reports"
  add_foreign_key "reports", "admins"
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
  add_foreign_key "user_authorization_history", "user_authorizations", name: "fk_user_authorization_history_user_authorizations"
  add_foreign_key "user_history", "users", name: "fk_user_history_users"
  add_foreign_key "users", "admins"
end
