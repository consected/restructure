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

ActiveRecord::Schema.define(version: 20150924183936) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

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
  end

  add_index "masters", ["msid"], name: "index_masters_on_msid", using: :btree
  add_index "masters", ["pro_id"], name: "index_masters_on_proid", using: :btree
  add_index "masters", ["pro_info_id"], name: "index_masters_on_pro_info_id", using: :btree
  add_index "masters", ["user_id"], name: "index_masters_on_user_id", using: :btree

  create_table "ml_copy", id: false, force: :cascade do |t|
    t.integer "procontactid"
    t.string  "fill_in_addresses",           limit: 255
    t.string  "in_survey",                   limit: 255
    t.string  "verify_survey_participation", limit: 255
    t.string  "verify_player_and_or_match",  limit: 255
    t.string  "accuracy",                    limit: 255
    t.string  "accuracy_score",              limit: 255
    t.integer "contactid"
    t.integer "pro_id"
    t.text    "separator_a"
    t.string  "first_name",                  limit: 255
    t.string  "middle_name",                 limit: 255
    t.string  "last_name",                   limit: 255
    t.string  "nick_name",                   limit: 255
    t.text    "separator_b"
    t.string  "pro_first_name",              limit: 255
    t.string  "pro_middle_name",             limit: 255
    t.string  "pro_last_name",               limit: 255
    t.string  "pro_nick_name",               limit: 255
    t.string  "birthdate",                   limit: 255
    t.string  "pro_dob",                     limit: 255
    t.string  "pro_dod",                     limit: 255
    t.string  "startyear",                   limit: 255
    t.string  "pro_start_year",              limit: 255
    t.integer "accruedseasons"
    t.string  "pro_end_year",                limit: 255
    t.string  "first_contract",              limit: 255
    t.string  "second_contract",             limit: 255
    t.string  "third_contract",              limit: 255
    t.string  "pro_career_info",             limit: 255
    t.string  "pro_birthplace",              limit: 255
    t.string  "pro_college",                 limit: 255
    t.string  "email",                       limit: 255
    t.string  "homecity",                    limit: 255
    t.string  "homestate",                   limit: 50
    t.string  "homezipcode",                 limit: 10
    t.string  "homestreet",                  limit: 255
    t.string  "homestreet2",                 limit: 255
    t.string  "homestreet3",                 limit: 255
    t.string  "businesscity",                limit: 255
    t.string  "businessstate",               limit: 50
    t.string  "businesszipcode",             limit: 10
    t.string  "businessstreet",              limit: 255
    t.string  "businessstreet2",             limit: 255
    t.string  "businessstreet3",             limit: 255
    t.integer "changed"
    t.string  "changed_column",              limit: 255
    t.integer "verified"
    t.text    "notes"
    t.string  "email2",                      limit: 255
    t.string  "email3",                      limit: 255
    t.string  "updatehomestreet",            limit: 255
    t.string  "updatehomestreet2",           limit: 255
    t.string  "updatehomecity",              limit: 255
    t.string  "updatehomestate",             limit: 50
    t.string  "updatehomezipcode",           limit: 10
    t.string  "lastmod",                     limit: 255
    t.string  "sourc",                       limit: 255
    t.string  "changed_by",                  limit: 255
    t.integer "msid"
    t.string  "mailing",                     limit: 255
    t.string  "outreach_vfy",                limit: 255
    t.text    "lastupdate"
    t.text    "lastupdateby"
    t.string  "cprefs",                      limit: 255
    t.integer "scantronid"
    t.text    "insertauditkey"
  end

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
  add_index "protocol_events", ["sub_process_id"], name: "index_protocol_events_on_sub_process_id", using: :btree

  create_table "protocols", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
    t.integer  "position"
  end

  add_index "protocols", ["admin_id"], name: "index_protocols_on_admin_id", using: :btree

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

  create_table "sub_processes", force: :cascade do |t|
    t.string   "name"
    t.boolean  "disabled"
    t.integer  "protocol_id"
    t.integer  "admin_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sub_processes", ["admin_id"], name: "index_sub_processes_on_admin_id", using: :btree
  add_index "sub_processes", ["protocol_id"], name: "index_sub_processes_on_protocol_id", using: :btree

  create_table "tracker_history", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "protocol_id"
    t.integer  "tracker_id"
    t.datetime "event_date"
    t.integer  "user_id"
    t.string   "notes"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
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
    t.integer  "protocol_id"
    t.datetime "event_date"
    t.integer  "user_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "notes"
    t.integer  "sub_process_id"
    t.integer  "protocol_event_id"
    t.integer  "item_id"
    t.string   "item_type"
  end

  add_index "trackers", ["master_id"], name: "index_trackers_on_master_id", using: :btree
  add_index "trackers", ["protocol_event_id"], name: "index_trackers_on_protocol_event_id", using: :btree
  add_index "trackers", ["protocol_id"], name: "index_trackers_on_protocol_id", using: :btree
  add_index "trackers", ["sub_process_id"], name: "index_trackers_on_sub_process_id", using: :btree
  add_index "trackers", ["user_id"], name: "index_trackers_on_user_id", using: :btree

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

  add_foreign_key "accuracy_scores", "admins"
  add_foreign_key "address_history", "addresses", name: "fk_address_history_addresses"
  add_foreign_key "address_history", "masters", name: "fk_address_history_masters"
  add_foreign_key "address_history", "users", name: "fk_address_history_users"
  add_foreign_key "addresses", "masters"
  add_foreign_key "addresses", "users"
  add_foreign_key "colleges", "admins"
  add_foreign_key "colleges", "users"
  add_foreign_key "general_selections", "admins"
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
  add_foreign_key "protocol_events", "admins"
  add_foreign_key "protocol_events", "sub_processes"
  add_foreign_key "protocols", "admins"
  add_foreign_key "scantron_history", "masters", name: "fk_scantron_history_masters"
  add_foreign_key "scantron_history", "scantrons", column: "scantron_table_id", name: "fk_scantron_history_scantrons"
  add_foreign_key "scantron_history", "users", name: "fk_scantron_history_users"
  add_foreign_key "scantrons", "masters"
  add_foreign_key "scantrons", "users"
  add_foreign_key "sub_processes", "admins"
  add_foreign_key "sub_processes", "protocols"
  add_foreign_key "tracker_history", "masters"
  add_foreign_key "tracker_history", "protocol_events"
  add_foreign_key "tracker_history", "protocols"
  add_foreign_key "tracker_history", "sub_processes"
  add_foreign_key "tracker_history", "trackers"
  add_foreign_key "tracker_history", "users"
  add_foreign_key "trackers", "masters"
  add_foreign_key "trackers", "protocol_events"
  add_foreign_key "trackers", "protocols"
  add_foreign_key "trackers", "sub_processes"
  add_foreign_key "trackers", "users"
  add_foreign_key "users", "admins"
end
