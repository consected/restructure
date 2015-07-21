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

ActiveRecord::Schema.define(version: 20150721204937) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accuracy_scores", force: :cascade do |t|
    t.string   "name"
    t.integer  "value"
    t.integer  "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "disabled"
  end

  add_index "accuracy_scores", ["admin_id"], name: "index_accuracy_scores_on_admin_id", using: :btree

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
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at", default: '2015-07-17 14:00:33'
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
  end

  create_table "colleges", force: :cascade do |t|
    t.string  "name"
    t.integer "synonym_for_id"
    t.boolean "disabled"
  end

  create_table "general_selections", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.string   "item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "disabled"
    t.integer  "admin_id"
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
  end

  create_table "player_contacts", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "rec_type"
    t.string   "data"
    t.string   "source"
    t.integer  "rank"
    t.boolean  "active"
    t.integer  "user_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at", default: '2015-07-17 14:00:33'
  end

  add_index "player_contacts", ["master_id"], name: "index_player_contacts_on_master_id", using: :btree
  add_index "player_contacts", ["user_id"], name: "index_player_contacts_on_user_id", using: :btree

  create_table "player_infos", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "middle_name"
    t.string   "nick_name"
    t.date     "birth_date"
    t.date     "death_date"
    t.string   "occupation_category"
    t.string   "company"
    t.string   "company_description"
    t.string   "transaction_status"
    t.string   "transaction_substatus"
    t.integer  "user_id"
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                      default: '2015-07-17 14:00:33'
    t.string   "contact_pref"
    t.integer  "start_year"
    t.string   "in_survey",             limit: 1
    t.integer  "rank"
    t.string   "notes"
    t.integer  "contact_id"
    t.integer  "pro_info_id"
    t.string   "college"
    t.integer  "end_year"
  end

  add_index "player_infos", ["master_id"], name: "index_player_infos_on_master_id", using: :btree
  add_index "player_infos", ["pro_info_id"], name: "index_player_infos_on_pro_info_id", using: :btree
  add_index "player_infos", ["user_id"], name: "index_player_infos_on_user_id", using: :btree

  create_table "pro_infos", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "pro_id"
    t.string   "in_survey"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "nick_name"
    t.string   "last_name"
    t.date     "birth_date"
    t.date     "death_date"
    t.integer  "start_year"
    t.integer  "end_year"
    t.decimal  "accrued_seasons"
    t.string   "college"
    t.string   "first_contract"
    t.string   "second_contract"
    t.string   "third_contract"
    t.string   "career_info"
    t.string   "birthplace"
    t.integer  "user_id"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",      default: '2015-07-17 14:00:33'
    t.integer  "rank"
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

  create_table "scantrons", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "scantron_id"
    t.string   "source"
    t.integer  "rank"
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
    t.string   "event"
    t.datetime "event_date"
    t.string   "c_method"
    t.string   "outcome"
    t.datetime "outcome_date"
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
    t.string   "event"
    t.datetime "event_date"
    t.string   "c_method"
    t.string   "outcome"
    t.datetime "outcome_date"
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
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "accuracy_scores", "admins"
  add_foreign_key "addresses", "masters"
  add_foreign_key "addresses", "users"
  add_foreign_key "general_selections", "admins"
  add_foreign_key "item_flag_names", "admins"
  add_foreign_key "item_flags", "item_flag_names"
  add_foreign_key "item_flags", "users"
  add_foreign_key "player_contacts", "masters"
  add_foreign_key "player_contacts", "users"
  add_foreign_key "player_infos", "masters"
  add_foreign_key "player_infos", "pro_infos"
  add_foreign_key "player_infos", "users"
  add_foreign_key "pro_infos", "masters"
  add_foreign_key "pro_infos", "users"
  add_foreign_key "protocol_events", "admins"
  add_foreign_key "protocol_events", "sub_processes"
  add_foreign_key "protocols", "admins"
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
end
