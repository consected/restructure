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

ActiveRecord::Schema.define(version: 20180822093429) do

  create_table "app_types", force: :cascade do |t|
    t.string "name"
  end

  create_table "nfs_store_archived_files", force: :cascade do |t|
    t.string   "file_hash"
    t.string   "file_name",              null: false
    t.string   "content_type",           null: false
    t.string   "archive_file",           null: false
    t.string   "path",                   null: false
    t.integer  "file_size",              null: false
    t.datetime "file_updated_at"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "nfs_store_container_id"
    t.integer  "user_id"
  end

  add_index "nfs_store_archived_files", ["nfs_store_container_id"], name: "index_nfs_store_archived_files_on_nfs_store_container_id"

  create_table "nfs_store_containers", force: :cascade do |t|
    t.string  "name"
    t.integer "user_id"
    t.integer "app_type_id"
    t.integer "nfs_store_container_id"
  end

  add_index "nfs_store_containers", ["nfs_store_container_id"], name: "index_nfs_store_containers_on_nfs_store_container_id"

  create_table "nfs_store_downloads", force: :cascade do |t|
    t.integer  "user_groups"
    t.string   "path"
    t.string   "retrieval_path"
    t.string   "retrieved_items"
    t.integer  "user_id",                null: false
    t.integer  "nfs_store_container_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nfs_store_stored_files", force: :cascade do |t|
    t.string   "file_hash",              null: false
    t.string   "file_name",              null: false
    t.string   "content_type",           null: false
    t.integer  "file_size",              null: false
    t.string   "path"
    t.datetime "file_updated_at"
    t.integer  "user_id"
    t.integer  "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nfs_store_stored_files", ["nfs_store_container_id", "file_hash", "file_name", "path"], name: "nfs_store_stored_files_unique_file", unique: true
  add_index "nfs_store_stored_files", ["nfs_store_container_id"], name: "index_nfs_store_stored_files_on_nfs_store_container_id"

  create_table "nfs_store_uploads", force: :cascade do |t|
    t.string   "file_hash",              null: false
    t.string   "file_name",              null: false
    t.string   "content_type",           null: false
    t.integer  "file_size",              null: false
    t.integer  "chunk_count"
    t.boolean  "completed"
    t.datetime "file_updated_at"
    t.integer  "user_id"
    t.integer  "nfs_store_container_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path"
  end

  add_index "nfs_store_uploads", [nil, "file_hash", "file_name"], name: "nfs_store_uploads_unique_file", unique: true

  create_table "user_access_controls", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer  "app_type"
    t.string   "role_name"
    t.integer  "user_id"
    t.integer  "admin"
    t.boolean  "disabled",   default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "app_type_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
