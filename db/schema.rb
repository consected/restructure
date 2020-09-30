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

ActiveRecord::Schema.define(version: 2020_09_29_165700) do

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

  create_table "activity_log_bhs_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "bhs_assignment_id"
    t.string "select_record_from_player_contact_phones"
    t.string "return_call_availability_notes"
    t.string "questions_from_call_notes"
    t.string "results_link"
    t.string "select_result"
    t.string "completed_q1_no_yes"
    t.string "completed_teamstudy_no_yes"
    t.string "previous_contact_with_team_no_yes"
    t.string "previous_contact_with_team_notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_bhs_assignment_id"
    t.string "notes"
    t.string "pi_return_call_notes"
    t.index ["activity_log_bhs_assignment_id"], name: "index_activity_log_bhs_assignment_history_on_activity_log_bhs_a"
    t.index ["bhs_assignment_id"], name: "index_activity_log_bhs_assignment_history_on_bhs_assignment_id"
    t.index ["master_id"], name: "index_activity_log_bhs_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_activity_log_bhs_assignment_history_on_user_id"
  end

  create_table "activity_log_bhs_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_phones"
    t.string "return_call_availability_notes"
    t.string "questions_from_call_notes"
    t.string "results_link"
    t.string "select_result"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pi_notes_from_return_call"
    t.bigint "bhs_assignment_id"
    t.string "pi_return_call_notes"
    t.index ["bhs_assignment_id"], name: "index_ml_app.activity_log_bhs_assignments_on_bhs_assignment_id"
    t.index ["master_id"], name: "index_activity_log_bhs_assignments_on_master_id"
    t.index ["user_id"], name: "index_activity_log_bhs_assignments_on_user_id"
  end

  create_table "activity_log_data_request_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "data_request_assignment_id"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_data_request_assignment_id"
    t.integer "created_by_user_id"
    t.string "next_step"
    t.string "status"
    t.index ["activity_log_data_request_assignment_id"], name: "index_al_data_request_assignment_history_on_activity_log_data_r"
    t.index ["data_request_assignment_id"], name: "index_al_data_request_assignment_history_on_data_request_assign"
    t.index ["master_id"], name: "index_al_data_request_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_al_data_request_assignment_history_on_user_id"
  end

  create_table "activity_log_data_request_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "follow_up_date"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_user_id"
    t.string "next_step"
    t.string "status"
    t.bigint "data_request_assignment_id"
    t.index ["data_request_assignment_id"], name: "36bd4ead_bt_id_idx"
    t.index ["master_id"], name: "index_activity_log_data_request_assignments_on_master_id"
    t.index ["user_id"], name: "index_activity_log_data_request_assignments_on_user_id"
  end

  create_table "activity_log_ext_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ext_assignment_id"
    t.date "do_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ext_assignment_id"
    t.index ["activity_log_ext_assignment_id"], name: "index_activity_log_ext_assignment_history_on_activity_log_ext_a"
    t.index ["ext_assignment_id"], name: "index_activity_log_ext_assignment_history_on_ext_assignment_id"
    t.index ["master_id"], name: "index_activity_log_ext_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ext_assignment_history_on_user_id"
  end

  create_table "activity_log_ext_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ext_assignment_id"
    t.date "do_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_call_direction"
    t.string "select_who"
    t.string "extra_text"
    t.string "extra_log_type"
    t.index ["ext_assignment_id"], name: "index_activity_log_ext_assignments_on_ext_assignment_id"
    t.index ["master_id"], name: "index_activity_log_ext_assignments_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ext_assignments_on_user_id"
  end

  create_table "activity_log_femfl_assignment_femfl_comm_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "femfl_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_dynamic_model__femfl_contacts"
    t.string "select_record_from_dynamic_model__femfl_addresses"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "activity_log_femfl_assignment_femfl_comm_id"
    t.index ["activity_log_femfl_assignment_femfl_comm_id"], name: "activity_log_femfl_assignment_femfl_comm_id_h_idx"
    t.index ["femfl_assignment_id"], name: "al_femfl_assignment_id_h_idx"
    t.index ["master_id"], name: "al_femfl_assignment_master_id_h_idx"
    t.index ["user_id"], name: "al_femfl_assignment_user_id_h_idx"
  end

  create_table "activity_log_femfl_assignment_femfl_comms", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "femfl_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_dynamic_model__femfl_contacts"
    t.string "select_record_from_dynamic_model__femfl_addresses"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["femfl_assignment_id"], name: "al_femfl_assignment_id_idx"
    t.index ["master_id"], name: "al_femfl_assignment_master_id_idx"
    t.index ["user_id"], name: "al_femfl_assignment_user_id_idx"
  end

  create_table "activity_log_grit_assignment_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_grit_assignment_adverse_event_id"
    t.index ["activity_log_grit_assignment_adverse_event_id"], name: "index_al_grit_assignment_adverse_event_history_on_activity_log_"
    t.index ["grit_assignment_id"], name: "index_al_grit_assignment_adverse_event_history_on_grit_assignme"
    t.index ["master_id"], name: "index_al_grit_assignment_adverse_event_history_on_master_id"
    t.index ["user_id"], name: "index_al_grit_assignment_adverse_event_history_on_user_id"
  end

  create_table "activity_log_grit_assignment_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_adverse_events_on_grit_assig"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_adverse_events_on_master_id"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_adverse_events_on_user_id"
  end

  create_table "activity_log_grit_assignment_discussion_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "tag_select_contact_role", array: true
    t.string "notes"
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_grit_assignment_discussion_id"
    t.index ["activity_log_grit_assignment_discussion_id"], name: "index_al_grit_assignment_discussion_history_on_activity_log_gri"
    t.index ["grit_assignment_id"], name: "index_al_grit_assignment_discussion_history_on_grit_assignment_"
    t.index ["master_id"], name: "index_al_grit_assignment_discussion_history_on_master_id"
    t.index ["user_id"], name: "index_al_grit_assignment_discussion_history_on_user_id"
  end

  create_table "activity_log_grit_assignment_discussions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "tag_select_contact_role", array: true
    t.string "notes"
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_discussions_on_grit_assignme"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_discussions_on_master_id"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_discussions_on_user_id"
  end

  create_table "activity_log_grit_assignment_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_grit_assignment_followup_id"
    t.index ["activity_log_grit_assignment_followup_id"], name: "index_al_grit_assignment_followup_history_on_activity_log_grit_"
    t.index ["grit_assignment_id"], name: "index_al_grit_assignment_followup_history_on_grit_assignment_fo"
    t.index ["master_id"], name: "index_al_grit_assignment_followup_history_on_master_id"
    t.index ["user_id"], name: "index_al_grit_assignment_followup_history_on_user_id"
  end

  create_table "activity_log_grit_assignment_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_followups_on_grit_assignment"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_followups_on_master_id"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_followups_on_user_id"
  end

  create_table "activity_log_grit_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_grit_assignment_id"
    t.index ["activity_log_grit_assignment_id"], name: "index_activity_log_grit_assignment_history_on_activity_log_grit"
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_history_on_grit_assignment_i"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_history_on_user_id"
  end

  create_table "activity_log_grit_assignment_phone_screen_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "callback_required"
    t.date "callback_date"
    t.time "callback_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_grit_assignment_phone_screen_id"
    t.index ["activity_log_grit_assignment_phone_screen_id"], name: "index_activity_log_grit_assignment_phone_screen_history_on_acti"
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_phone_screen_history_on_grit"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_phone_screen_history_on_mast"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_phone_screen_history_on_user"
  end

  create_table "activity_log_grit_assignment_phone_screens", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "callback_required"
    t.date "callback_date"
    t.time "callback_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_phone_screens_on_grit_assign"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_phone_screens_on_master_id"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_phone_screens_on_user_id"
  end

  create_table "activity_log_grit_assignment_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_grit_assignment_protocol_deviation_id"
    t.index ["activity_log_grit_assignment_protocol_deviation_id"], name: "index_al_grit_assignment_protocol_deviation_history_on_activity"
    t.index ["grit_assignment_id"], name: "index_al_grit_assignment_protocol_deviation_history_on_grit_ass"
    t.index ["master_id"], name: "index_al_grit_assignment_protocol_deviation_history_on_master_i"
    t.index ["user_id"], name: "index_al_grit_assignment_protocol_deviation_history_on_user_id"
  end

  create_table "activity_log_grit_assignment_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignment_protocol_deviations_on_grit_"
    t.index ["master_id"], name: "index_activity_log_grit_assignment_protocol_deviations_on_maste"
    t.index ["user_id"], name: "index_activity_log_grit_assignment_protocol_deviations_on_user_"
  end

  create_table "activity_log_grit_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "grit_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grit_assignment_id"], name: "index_activity_log_grit_assignments_on_grit_assignment_id"
    t.index ["master_id"], name: "index_activity_log_grit_assignments_on_master_id"
    t.index ["user_id"], name: "index_activity_log_grit_assignments_on_user_id"
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
    t.index ["activity_log_id"], name: "index_activity_log_history_on_activity_log_id"
  end

  create_table "activity_log_ipa_assignment_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_adverse_event_id"
    t.index ["activity_log_ipa_assignment_adverse_event_id"], name: "index_al_ipa_assignment_adverse_event_history_on_activity_log_i"
    t.index ["ipa_assignment_id"], name: "index_al_ipa_assignment_adverse_event_history_on_ipa_assignment"
    t.index ["master_id"], name: "index_al_ipa_assignment_adverse_event_history_on_master_id"
    t.index ["user_id"], name: "index_al_ipa_assignment_adverse_event_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_adverse_events_on_ipa_assignm"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_adverse_events_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_adverse_events_on_user_id"
  end

  create_table "activity_log_ipa_assignment_discussion_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "tag_select_contact_role", array: true
    t.string "notes"
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_discussion_id"
    t.bigint "created_by_user_id"
    t.index ["activity_log_ipa_assignment_discussion_id"], name: "index_al_ipa_assignment_discussion_history_on_activity_log_ipa_"
    t.index ["created_by_user_id"], name: "8d569f72_ref_cb_user_idx_hist"
    t.index ["ipa_assignment_id"], name: "index_al_ipa_assignment_discussion_history_on_ipa_assignment_di"
    t.index ["master_id"], name: "index_al_ipa_assignment_discussion_history_on_master_id"
    t.index ["user_id"], name: "index_al_ipa_assignment_discussion_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_discussions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "tag_select_contact_role", array: true
    t.string "notes"
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "created_by_user_id"
    t.index ["created_by_user_id"], name: "8d569f72_ref_cb_user_idx"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_discussions_on_ipa_assignment"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_discussions_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_discussions_on_user_id"
  end

  create_table "activity_log_ipa_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_id"
    t.index ["activity_log_ipa_assignment_id"], name: "index_activity_log_ipa_assignment_history_on_activity_log_ipa_a"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_history_on_ipa_assignment_id"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_inex_checklist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "prev_activity_type"
    t.string "signed_no_yes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_inex_checklist_id"
    t.string "select_subject_eligibility"
    t.string "notes"
    t.string "contact_role"
    t.string "e_signed_document"
    t.string "e_signed_how"
    t.string "e_signed_at"
    t.string "e_signed_by"
    t.string "e_signed_code"
    t.string "e_signed_status"
    t.index ["activity_log_ipa_assignment_inex_checklist_id"], name: "index_activity_log_ipa_assignment_inex_checklist_history_on_act"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_inex_checklist_history_on_ipa"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_inex_checklist_history_on_mas"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_inex_checklist_history_on_use"
  end

  create_table "activity_log_ipa_assignment_inex_checklists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "prev_activity_type"
    t.string "signed_no_yes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_subject_eligibility"
    t.string "notes"
    t.string "contact_role"
    t.string "e_signed_document"
    t.string "e_signed_how"
    t.string "e_signed_at"
    t.string "e_signed_by"
    t.string "e_signed_code"
    t.string "e_signed_status"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_inex_checklists_on_ipa_assign"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_inex_checklists_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_inex_checklists_on_user_id"
  end

  create_table "activity_log_ipa_assignment_med_nav_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_med_nav_id"
    t.index ["activity_log_ipa_assignment_med_nav_id"], name: "index_al_ipa_assignment_med_nav_history_on_activity_log_ipa_ass"
    t.index ["ipa_assignment_id"], name: "index_al_ipa_assignment_med_nav_history_on_ipa_assignment_med_n"
    t.index ["master_id"], name: "index_al_ipa_assignment_med_nav_history_on_master_id"
    t.index ["user_id"], name: "index_al_ipa_assignment_med_nav_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_med_navs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_med_navs_on_ipa_assignment_me"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_med_navs_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_med_navs_on_user_id"
  end

  create_table "activity_log_ipa_assignment_minor_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.date "activity_date"
    t.date "deviation_discovered_when"
    t.date "deviation_occurred_when"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.string "select_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_minor_deviation_id"
    t.index ["activity_log_ipa_assignment_minor_deviation_id"], name: "index_activity_log_ipa_assignment_minor_deviation_history_on_ac"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_minor_deviation_history_on_ip"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_minor_deviation_history_on_ma"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_minor_deviation_history_on_us"
  end

  create_table "activity_log_ipa_assignment_minor_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.date "activity_date"
    t.date "deviation_discovered_when"
    t.date "deviation_occurred_when"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.string "select_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_minor_deviations_on_ipa_assig"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_minor_deviations_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_minor_deviations_on_user_id"
  end

  create_table "activity_log_ipa_assignment_navigation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.date "event_date"
    t.string "select_station"
    t.time "arrival_time"
    t.time "start_time"
    t.string "event_notes"
    t.time "completion_time"
    t.string "participant_feedback_notes"
    t.string "other_navigator_notes"
    t.string "add_protocol_deviation_record_no_yes"
    t.string "add_adverse_event_record_no_yes"
    t.string "select_event_type"
    t.string "other_event_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_navigation_id"
    t.string "select_status"
    t.string "select_navigator"
    t.string "select_pi"
    t.string "location"
    t.index ["activity_log_ipa_assignment_navigation_id"], name: "index_activity_log_ipa_assignment_navigation_history_on_activit"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_navigation_history_on_ipa_ass"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_navigation_history_on_master_"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_navigation_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_navigations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.date "event_date"
    t.string "select_station"
    t.time "arrival_time"
    t.time "start_time"
    t.string "event_notes"
    t.time "completion_time"
    t.string "participant_feedback_notes"
    t.string "other_navigator_notes"
    t.string "select_event_type"
    t.string "other_event_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_status"
    t.string "select_navigator"
    t.string "select_pi"
    t.string "location"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_navigations_on_ipa_assignment"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_navigations_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_navigations_on_user_id"
  end

  create_table "activity_log_ipa_assignment_phone_screen_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.date "callback_date"
    t.time "callback_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_phone_screen_id"
    t.string "callback_required"
    t.index ["activity_log_ipa_assignment_phone_screen_id"], name: "index_activity_log_ipa_assignment_phone_screen_history_on_activ"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_phone_screen_history_on_ipa_a"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_phone_screen_history_on_maste"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_phone_screen_history_on_user_"
  end

  create_table "activity_log_ipa_assignment_phone_screens", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.date "callback_date"
    t.time "callback_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "callback_required"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_phone_screens_on_ipa_assignme"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_phone_screens_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_phone_screens_on_user_id"
  end

  create_table "activity_log_ipa_assignment_post_visit_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_record_from_addresses"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_post_visit_id"
    t.index ["activity_log_ipa_assignment_post_visit_id"], name: "index_activity_log_ipa_assignment_post_visit_history_on_activit"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_post_visit_history_on_ipa_ass"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_post_visit_history_on_master_"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_post_visit_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_post_visits", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_record_from_addresses"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_post_visits_on_ipa_assignment"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_post_visits_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_post_visits_on_user_id"
  end

  create_table "activity_log_ipa_assignment_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_protocol_deviation_id"
    t.index ["activity_log_ipa_assignment_protocol_deviation_id"], name: "index_al_ipa_assignment_protocol_deviation_history_on_activity_"
    t.index ["ipa_assignment_id"], name: "index_al_ipa_assignment_protocol_deviation_history_on_ipa_assig"
    t.index ["master_id"], name: "index_al_ipa_assignment_protocol_deviation_history_on_master_id"
    t.index ["user_id"], name: "index_al_ipa_assignment_protocol_deviation_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_protocol_deviations_on_ipa_as"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_protocol_deviations_on_master"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_protocol_deviations_on_user_i"
  end

  create_table "activity_log_ipa_assignment_session_filestore_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_scanner"
    t.string "operator"
    t.string "notes"
    t.date "session_date"
    t.time "session_time"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_session_filestore_id"
    t.string "select_notify_role_name"
    t.string "select_type"
    t.string "select_status"
    t.string "select_confirm_status"
    t.index ["activity_log_ipa_assignment_session_filestore_id"], name: "index_al_ipa_assignment_session_filestore_history_on_activity_l"
    t.index ["ipa_assignment_id"], name: "index_al_ipa_assignment_session_filestore_history_on_ipa_assign"
    t.index ["master_id"], name: "index_al_ipa_assignment_session_filestore_history_on_master_id"
    t.index ["user_id"], name: "index_al_ipa_assignment_session_filestore_history_on_user_id"
  end

  create_table "activity_log_ipa_assignment_session_filestores", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_scanner"
    t.string "operator"
    t.string "notes"
    t.date "session_date"
    t.time "session_time"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_status"
    t.string "select_confirm_status"
    t.string "select_notify_role_name"
    t.string "select_type"
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_session_filestores_on_ipa_ass"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_session_filestores_on_master_"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_session_filestores_on_user_id"
  end

  create_table "activity_log_ipa_assignment_summaries", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignment_summaries_on_ipa_assignment_s"
    t.index ["master_id"], name: "index_activity_log_ipa_assignment_summaries_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignment_summaries_on_user_id"
  end

  create_table "activity_log_ipa_assignment_summary_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_assignment_summary_id"
    t.index ["activity_log_ipa_assignment_summary_id"], name: "index_al_ipa_assignment_summary_history_on_activity_log_ipa_ass"
    t.index ["ipa_assignment_id"], name: "index_al_ipa_assignment_summary_history_on_ipa_assignment_summa"
    t.index ["master_id"], name: "index_al_ipa_assignment_summary_history_on_master_id"
    t.index ["user_id"], name: "index_al_ipa_assignment_summary_history_on_user_id"
  end

  create_table "activity_log_ipa_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipa_assignment_id"], name: "index_activity_log_ipa_assignments_on_ipa_assignment_id"
    t.index ["master_id"], name: "index_activity_log_ipa_assignments_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_assignments_on_user_id"
  end

  create_table "activity_log_ipa_survey_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_survey_id"
    t.string "screened_by_who"
    t.date "screening_date"
    t.string "select_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_ipa_survey_id"
    t.index ["activity_log_ipa_survey_id"], name: "index_activity_log_ipa_survey_history_on_activity_log_ipa_surve"
    t.index ["ipa_survey_id"], name: "index_activity_log_ipa_survey_history_on_ipa_survey_id"
    t.index ["master_id"], name: "index_activity_log_ipa_survey_history_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_survey_history_on_user_id"
  end

  create_table "activity_log_ipa_surveys", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ipa_survey_id"
    t.string "screened_by_who"
    t.date "screening_date"
    t.string "select_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipa_survey_id"], name: "index_activity_log_ipa_surveys_on_ipa_survey_id"
    t.index ["master_id"], name: "index_activity_log_ipa_surveys_on_master_id"
    t.index ["user_id"], name: "index_activity_log_ipa_surveys_on_user_id"
  end

  create_table "activity_log_new_test_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "new_test_id"
    t.date "done_when"
    t.string "select_result"
    t.string "notes"
    t.integer "protocol_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_new_test_id"
    t.index ["activity_log_new_test_id"], name: "index_activity_log_new_test_history_on_activity_log_new_test_id"
    t.index ["master_id"], name: "index_activity_log_new_test_history_on_master_id"
    t.index ["new_test_id"], name: "index_activity_log_new_test_history_on_new_test_id"
    t.index ["user_id"], name: "index_activity_log_new_test_history_on_user_id"
  end

  create_table "activity_log_new_tests", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "new_test_id"
    t.date "done_when"
    t.string "select_result"
    t.string "notes"
    t.integer "protocol_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "new_test_ext_id"
    t.index ["master_id"], name: "index_activity_log_new_tests_on_master_id"
    t.index ["new_test_id"], name: "index_activity_log_new_tests_on_new_test_id"
    t.index ["user_id"], name: "index_activity_log_new_tests_on_user_id"
  end

  create_table "activity_log_persnet_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "persnet_assignment_id"
    t.string "select_record_from_player_contact_phones"
    t.string "return_call_availability_notes"
    t.string "questions_from_call_notes"
    t.string "results_link"
    t.string "select_result"
    t.string "pi_return_call_notes"
    t.string "completed_q1_no_yes"
    t.string "completed_teamstudy_no_yes"
    t.string "previous_contact_with_team_no_yes"
    t.string "previous_contact_with_team_notes"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_persnet_assignment_id"
    t.index ["activity_log_persnet_assignment_id"], name: "index_activity_log_persnet_assignment_history_on_activity_log_p"
    t.index ["master_id"], name: "index_activity_log_persnet_assignment_history_on_master_id"
    t.index ["persnet_assignment_id"], name: "index_activity_log_persnet_assignment_history_on_persnet_assign"
    t.index ["user_id"], name: "index_activity_log_persnet_assignment_history_on_user_id"
  end

  create_table "activity_log_persnet_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "persnet_assignment_id"
    t.string "select_record_from_player_contact_phones"
    t.string "return_call_availability_notes"
    t.string "questions_from_call_notes"
    t.string "results_link"
    t.string "select_result"
    t.string "pi_return_call_notes"
    t.string "completed_q1_no_yes"
    t.string "completed_teamstudy_no_yes"
    t.string "previous_contact_with_team_no_yes"
    t.string "previous_contact_with_team_notes"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_persnet_assignments_on_master_id"
    t.index ["persnet_assignment_id"], name: "index_activity_log_persnet_assignments_on_persnet_assignment_id"
    t.index ["user_id"], name: "index_activity_log_persnet_assignments_on_user_id"
  end

  create_table "activity_log_pitt_bhi_assignment_discussion_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_assignment_id"
    t.string "notes"
    t.string "tag_select_contact_role", array: true
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "activity_log_pitt_bhi_assignment_discussion_id"
    t.index ["activity_log_pitt_bhi_assignment_discussion_id"], name: "2455c589_b_id_h_idx"
    t.index ["master_id"], name: "2455c589_master_id_h_idx"
    t.index ["pitt_bhi_assignment_id"], name: "2455c589_id_h_idx"
    t.index ["user_id"], name: "2455c589_user_id_h_idx"
  end

  create_table "activity_log_pitt_bhi_assignment_discussions", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_assignment_id"
    t.string "notes"
    t.string "tag_select_contact_role", array: true
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "2455c589_master_id_idx"
    t.index ["pitt_bhi_assignment_id"], name: "2455c589_id_idx"
    t.index ["user_id"], name: "2455c589_user_id_idx"
  end

  create_table "activity_log_pitt_bhi_assignment_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_assignment_id"
    t.string "select_who"
    t.string "select_record_from_player_contacts"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.date "activity_date"
    t.string "select_activity"
    t.string "select_record_from_addresses"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "activity_log_pitt_bhi_assignment_id"
    t.index ["activity_log_pitt_bhi_assignment_id"], name: "activity_log_pitt_bhi_assignment_id_h_idx"
    t.index ["master_id"], name: "al_pitt_bhi_assignment_master_id_h_idx"
    t.index ["pitt_bhi_assignment_id"], name: "al_pitt_bhi_assignment_id_h_idx"
    t.index ["user_id"], name: "al_pitt_bhi_assignment_user_id_h_idx"
  end

  create_table "activity_log_pitt_bhi_assignment_phone_screen_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_assignment_id"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "activity_log_pitt_bhi_assignment_phone_screen_id"
    t.index ["activity_log_pitt_bhi_assignment_phone_screen_id"], name: "5h1r4d_id_h_idx"
    t.index ["master_id"], name: "e0brzq_master_id_h_idx"
    t.index ["pitt_bhi_assignment_id"], name: "cgv8p7_id_h_idx"
    t.index ["user_id"], name: "97fdth_user_id_h_idx"
  end

  create_table "activity_log_pitt_bhi_assignment_phone_screens", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_assignment_id"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "a3i2cl_master_id_idx"
    t.index ["pitt_bhi_assignment_id"], name: "cio0cq_id_idx"
    t.index ["user_id"], name: "fr0v7t_user_id_idx"
  end

  create_table "activity_log_pitt_bhi_assignments", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_assignment_id"
    t.string "select_who"
    t.string "select_record_from_player_contacts"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.date "activity_date"
    t.string "select_activity"
    t.string "select_record_from_addresses"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.string "extra_log_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "al_pitt_bhi_assignment_master_id_idx"
    t.index ["pitt_bhi_assignment_id"], name: "al_pitt_bhi_assignment_id_idx"
    t.index ["user_id"], name: "al_pitt_bhi_assignment_user_id_idx"
  end

  create_table "activity_log_player_contact_emails", id: :serial, force: :cascade do |t|
    t.string "data"
    t.string "select_email_direction"
    t.string "select_who"
    t.date "emailed_when"
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
    t.index ["master_id"], name: "index_activity_log_player_contact_emails_on_master_id"
    t.index ["player_contact_id"], name: "index_activity_log_player_contact_emails_on_player_contact_id"
    t.index ["protocol_id"], name: "index_activity_log_player_contact_emails_on_protocol_id"
    t.index ["user_id"], name: "index_activity_log_player_contact_emails_on_user_id"
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

  create_table "activity_log_player_contact_phones", id: :serial, comment: "Phone Log process for Zeus", force: :cascade do |t|
    t.string "data", comment: "Phone number related to this activity"
    t.string "select_call_direction", comment: "Was this call received by staff or to subject"
    t.string "select_who"
    t.date "called_when"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.integer "protocol_id"
    t.string "notes"
    t.integer "user_id"
    t.integer "master_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "set_related_player_contact_rank"
    t.string "extra_log_type"
    t.integer "player_contact_id"
    t.index ["master_id"], name: "index_activity_log_player_contact_phones_on_master_id"
    t.index ["protocol_id"], name: "index_activity_log_player_contact_phones_on_protocol_id"
    t.index ["user_id"], name: "index_activity_log_player_contact_phones_on_user_id"
  end

  create_table "activity_log_player_info_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "player_info_id"
    t.date "done_when"
    t.string "notes"
    t.integer "protocol_id"
    t.string "select_who"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_player_info_id"
    t.index ["activity_log_player_info_id"], name: "index_activity_log_player_info_history_on_activity_log_player_i"
    t.index ["master_id"], name: "index_activity_log_player_info_history_on_master_id"
    t.index ["player_info_id"], name: "index_activity_log_player_info_history_on_player_info_id"
    t.index ["user_id"], name: "index_activity_log_player_info_history_on_user_id"
  end

  create_table "activity_log_player_infos", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "player_info_id"
    t.date "done_when"
    t.string "notes"
    t.integer "protocol_id"
    t.string "select_who"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_player_infos_on_master_id"
    t.index ["player_info_id"], name: "index_activity_log_player_infos_on_player_info_id"
    t.index ["user_id"], name: "index_activity_log_player_infos_on_user_id"
  end

  create_table "activity_log_sleep_assignment_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_adverse_event_id"
    t.index ["activity_log_sleep_assignment_adverse_event_id"], name: "index_al_sleep_assignment_adverse_event_history_on_activity_log"
    t.index ["master_id"], name: "index_al_sleep_assignment_adverse_event_history_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_al_sleep_assignment_adverse_event_history_on_sleep_assign"
    t.index ["user_id"], name: "index_al_sleep_assignment_adverse_event_history_on_user_id"
  end

  create_table "activity_log_sleep_assignment_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_adverse_events_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_adverse_events_on_sleep_ass"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_adverse_events_on_user_id"
  end

  create_table "activity_log_sleep_assignment_discussion_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "tag_select_contact_role", array: true
    t.string "notes"
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_discussion_id"
    t.index ["activity_log_sleep_assignment_discussion_id"], name: "index_al_sleep_assignment_discussion_history_on_activity_log_sl"
    t.index ["master_id"], name: "index_al_sleep_assignment_discussion_history_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_al_sleep_assignment_discussion_history_on_sleep_assignmen"
    t.index ["user_id"], name: "index_al_sleep_assignment_discussion_history_on_user_id"
  end

  create_table "activity_log_sleep_assignment_discussions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "tag_select_contact_role", array: true
    t.string "notes"
    t.string "prev_activity_type"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_discussions_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_discussions_on_sleep_assign"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_discussions_on_user_id"
  end

  create_table "activity_log_sleep_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_id"
    t.bigint "protocol_id"
    t.index ["activity_log_sleep_assignment_id"], name: "index_activity_log_sleep_assignment_history_on_activity_log_sle"
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_history_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_history_on_sleep_assignment"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_history_on_user_id"
  end

  create_table "activity_log_sleep_assignment_inex_checklist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "signed_no_yes"
    t.string "notes"
    t.string "e_signed_document"
    t.string "e_signed_how"
    t.string "e_signed_at"
    t.string "e_signed_by"
    t.string "e_signed_code"
    t.string "e_signed_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_inex_checklist_id"
    t.string "select_subject_eligibility"
    t.string "contact_role"
    t.string "prev_activity_type"
    t.index ["activity_log_sleep_assignment_inex_checklist_id"], name: "index_activity_log_sleep_assignment_inex_checklist_history_on_a"
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_inex_checklist_history_on_m"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_inex_checklist_history_on_s"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_inex_checklist_history_on_u"
  end

  create_table "activity_log_sleep_assignment_inex_checklists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "signed_no_yes"
    t.string "notes"
    t.string "e_signed_document"
    t.string "e_signed_how"
    t.string "e_signed_at"
    t.string "e_signed_by"
    t.string "e_signed_code"
    t.string "e_signed_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_subject_eligibility"
    t.string "contact_role"
    t.string "prev_activity_type"
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_inex_checklists_on_master_i"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_inex_checklists_on_sleep_as"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_inex_checklists_on_user_id"
  end

  create_table "activity_log_sleep_assignment_med_nav_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_med_nav_id"
    t.index ["activity_log_sleep_assignment_med_nav_id"], name: "index_al_sleep_assignment_med_nav_history_on_activity_log_sleep"
    t.index ["master_id"], name: "index_al_sleep_assignment_med_nav_history_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_al_sleep_assignment_med_nav_history_on_sleep_assignment_m"
    t.index ["user_id"], name: "index_al_sleep_assignment_med_nav_history_on_user_id"
  end

  create_table "activity_log_sleep_assignment_med_navs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_med_navs_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_med_navs_on_sleep_assignmen"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_med_navs_on_user_id"
  end

  create_table "activity_log_sleep_assignment_phone_screen2_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_phone_screen2_id"
    t.index ["activity_log_sleep_assignment_phone_screen2_id"], name: "index_al_sleep_assignment_phone_screen2_history_on_activity_log"
    t.index ["master_id"], name: "index_al_sleep_assignment_phone_screen2_history_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_al_sleep_assignment_phone_screen2_history_on_sleep_assign"
    t.index ["user_id"], name: "index_al_sleep_assignment_phone_screen2_history_on_user_id"
  end

  create_table "activity_log_sleep_assignment_phone_screen2s", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_phone_screen2s_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_phone_screen2s_on_sleep_ass"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_phone_screen2s_on_user_id"
  end

  create_table "activity_log_sleep_assignment_phone_screen_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_phone_screen_id"
    t.string "notes"
    t.time "callback_time"
    t.date "callback_date"
    t.string "callback_required"
    t.index ["activity_log_sleep_assignment_phone_screen_id"], name: "index_activity_log_sleep_assignment_phone_screen_history_on_act"
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_phone_screen_history_on_mas"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_phone_screen_history_on_sle"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_phone_screen_history_on_use"
  end

  create_table "activity_log_sleep_assignment_phone_screens", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notes"
    t.time "callback_time"
    t.date "callback_date"
    t.string "callback_required"
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_phone_screens_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_phone_screens_on_sleep_assi"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_phone_screens_on_user_id"
  end

  create_table "activity_log_sleep_assignment_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_sleep_assignment_protocol_deviation_id"
    t.index ["activity_log_sleep_assignment_protocol_deviation_id"], name: "index_al_sleep_assignment_protocol_deviation_history_on_activit"
    t.index ["master_id"], name: "index_al_sleep_assignment_protocol_deviation_history_on_master_"
    t.index ["sleep_assignment_id"], name: "index_al_sleep_assignment_protocol_deviation_history_on_sleep_a"
    t.index ["user_id"], name: "index_al_sleep_assignment_protocol_deviation_history_on_user_id"
  end

  create_table "activity_log_sleep_assignment_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_sleep_assignment_protocol_deviations_on_mast"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignment_protocol_deviations_on_slee"
    t.index ["user_id"], name: "index_activity_log_sleep_assignment_protocol_deviations_on_user"
  end

  create_table "activity_log_sleep_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sleep_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "protocol_id"
    t.index ["master_id"], name: "index_activity_log_sleep_assignments_on_master_id"
    t.index ["sleep_assignment_id"], name: "index_activity_log_sleep_assignments_on_sleep_assignment_id"
    t.index ["user_id"], name: "index_activity_log_sleep_assignments_on_user_id"
  end

  create_table "activity_log_tbs_assignment_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_adverse_event_id"
    t.index ["activity_log_tbs_assignment_adverse_event_id"], name: "index_al_tbs_assignment_adverse_event_history_on_activity_log_t"
    t.index ["master_id"], name: "index_al_tbs_assignment_adverse_event_history_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_al_tbs_assignment_adverse_event_history_on_tbs_assignment"
    t.index ["user_id"], name: "index_al_tbs_assignment_adverse_event_history_on_user_id"
  end

  create_table "activity_log_tbs_assignment_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_adverse_events_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_adverse_events_on_tbs_assignm"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_adverse_events_on_user_id"
  end

  create_table "activity_log_tbs_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_id"
    t.index ["activity_log_tbs_assignment_id"], name: "index_activity_log_tbs_assignment_history_on_activity_log_tbs_a"
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_history_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_history_on_tbs_assignment_id"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_history_on_user_id"
  end

  create_table "activity_log_tbs_assignment_inex_checklist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "prev_activity_type"
    t.string "contact_role"
    t.string "select_subject_eligibility"
    t.string "signed_no_yes"
    t.string "notes"
    t.string "e_signed_document"
    t.string "e_signed_how"
    t.string "e_signed_at"
    t.string "e_signed_by"
    t.string "e_signed_code"
    t.string "e_signed_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_inex_checklist_id"
    t.index ["activity_log_tbs_assignment_inex_checklist_id"], name: "index_activity_log_tbs_assignment_inex_checklist_history_on_act"
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_inex_checklist_history_on_mas"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_inex_checklist_history_on_tbs"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_inex_checklist_history_on_use"
  end

  create_table "activity_log_tbs_assignment_inex_checklists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "prev_activity_type"
    t.string "contact_role"
    t.string "select_subject_eligibility"
    t.string "signed_no_yes"
    t.string "notes"
    t.string "e_signed_document"
    t.string "e_signed_how"
    t.string "e_signed_at"
    t.string "e_signed_by"
    t.string "e_signed_code"
    t.string "e_signed_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_inex_checklists_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_inex_checklists_on_tbs_assign"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_inex_checklists_on_user_id"
  end

  create_table "activity_log_tbs_assignment_med_nav_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_med_nav_id"
    t.index ["activity_log_tbs_assignment_med_nav_id"], name: "index_al_tbs_assignment_med_nav_history_on_activity_log_tbs_ass"
    t.index ["master_id"], name: "index_al_tbs_assignment_med_nav_history_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_al_tbs_assignment_med_nav_history_on_tbs_assignment_med_n"
    t.index ["user_id"], name: "index_al_tbs_assignment_med_nav_history_on_user_id"
  end

  create_table "activity_log_tbs_assignment_med_navs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_contact"
    t.string "select_direction"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_med_navs_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_med_navs_on_tbs_assignment_me"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_med_navs_on_user_id"
  end

  create_table "activity_log_tbs_assignment_navigation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.date "event_date"
    t.string "select_station"
    t.string "select_navigator"
    t.string "select_pi"
    t.string "location"
    t.time "arrival_time"
    t.time "start_time"
    t.string "event_notes"
    t.time "completion_time"
    t.string "participant_feedback_notes"
    t.string "other_navigator_notes"
    t.string "add_protocol_deviation_record_no_yes"
    t.string "add_adverse_event_record_no_yes"
    t.string "select_event_type"
    t.string "other_event_type"
    t.string "select_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_navigation_id"
    t.index ["activity_log_tbs_assignment_navigation_id"], name: "index_activity_log_tbs_assignment_navigation_history_on_activit"
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_navigation_history_on_master_"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_navigation_history_on_tbs_ass"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_navigation_history_on_user_id"
  end

  create_table "activity_log_tbs_assignment_navigations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.date "event_date"
    t.string "select_station"
    t.string "select_navigator"
    t.string "select_pi"
    t.string "location"
    t.time "arrival_time"
    t.time "start_time"
    t.string "event_notes"
    t.time "completion_time"
    t.string "participant_feedback_notes"
    t.string "other_navigator_notes"
    t.string "add_protocol_deviation_record_no_yes"
    t.string "add_adverse_event_record_no_yes"
    t.string "select_event_type"
    t.string "other_event_type"
    t.string "select_status"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_navigations_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_navigations_on_tbs_assignment"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_navigations_on_user_id"
  end

  create_table "activity_log_tbs_assignment_phone_screen_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "callback_required"
    t.date "callback_date"
    t.time "callback_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_phone_screen_id"
    t.index ["activity_log_tbs_assignment_phone_screen_id"], name: "index_activity_log_tbs_assignment_phone_screen_history_on_activ"
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_phone_screen_history_on_maste"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_phone_screen_history_on_tbs_a"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_phone_screen_history_on_user_"
  end

  create_table "activity_log_tbs_assignment_phone_screens", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "callback_required"
    t.date "callback_date"
    t.time "callback_time"
    t.string "notes"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_phone_screens_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_phone_screens_on_tbs_assignme"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_phone_screens_on_user_id"
  end

  create_table "activity_log_tbs_assignment_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_tbs_assignment_protocol_deviation_id"
    t.index ["activity_log_tbs_assignment_protocol_deviation_id"], name: "index_al_tbs_assignment_protocol_deviation_history_on_activity_"
    t.index ["master_id"], name: "index_al_tbs_assignment_protocol_deviation_history_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_al_tbs_assignment_protocol_deviation_history_on_tbs_assig"
    t.index ["user_id"], name: "index_al_tbs_assignment_protocol_deviation_history_on_user_id"
  end

  create_table "activity_log_tbs_assignment_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "extra_log_type"
    t.string "select_who"
    t.date "done_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignment_protocol_deviations_on_master"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignment_protocol_deviations_on_tbs_as"
    t.index ["user_id"], name: "index_activity_log_tbs_assignment_protocol_deviations_on_user_i"
  end

  create_table "activity_log_tbs_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tbs_assignment_id"
    t.string "select_activity"
    t.date "activity_date"
    t.string "select_record_from_player_contacts"
    t.string "select_direction"
    t.string "select_who"
    t.string "select_result"
    t.string "select_next_step"
    t.date "follow_up_when"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "protocol_id"
    t.string "select_record_from_addresses"
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_tbs_assignments_on_master_id"
    t.index ["tbs_assignment_id"], name: "index_activity_log_tbs_assignments_on_tbs_assignment_id"
    t.index ["user_id"], name: "index_activity_log_tbs_assignments_on_user_id"
  end

  create_table "activity_log_zeus_bulk_message_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "zeus_bulk_message_id"
    t.string "background_job_ref"
    t.boolean "disabled", default: false, null: false
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_log_zeus_bulk_message_id"
    t.index ["activity_log_zeus_bulk_message_id"], name: "index_al_zeus_bulk_message_history_on_activity_log_zeus_bulk_me"
    t.index ["master_id"], name: "index_al_zeus_bulk_message_history_on_master_id"
    t.index ["user_id"], name: "index_al_zeus_bulk_message_history_on_user_id"
    t.index ["zeus_bulk_message_id"], name: "index_al_zeus_bulk_message_history_on_zeus_bulk_message_id"
  end

  create_table "activity_log_zeus_bulk_messages", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "zeus_bulk_message_id"
    t.string "background_job_ref"
    t.boolean "disabled", default: false, null: false
    t.string "extra_log_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_activity_log_zeus_bulk_messages_on_master_id"
    t.index ["user_id"], name: "index_activity_log_zeus_bulk_messages_on_user_id"
    t.index ["zeus_bulk_message_id"], name: "index_activity_log_zeus_bulk_messages_on_zeus_bulk_message_id"
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
    t.datetime "updated_at", default: "2017-09-25 15:43:35"
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
    t.datetime "updated_at", default: "2017-09-25 15:43:35"
    t.string "country", limit: 3
    t.string "postal_code"
    t.string "region"
    t.index ["master_id"], name: "index_addresses_on_master_id"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "adl_screener_data", id: :serial, force: :cascade do |t|
    t.decimal "record_id"
    t.decimal "redcap_survey_identifier"
    t.datetime "adcs_npiq_timestamp"
    t.decimal "adlnpi_consent___agree"
    t.decimal "informant"
    t.decimal "adl_eat"
    t.decimal "adl_walk"
    t.decimal "adl_toilet"
    t.decimal "adl_bath"
    t.decimal "adl_groom"
    t.decimal "adl_dressa"
    t.decimal "adl_dressa_perf"
    t.decimal "adl_dressb"
    t.decimal "adl_phone"
    t.decimal "adl_phone_perf"
    t.decimal "adl_tv"
    t.decimal "adl_tva"
    t.decimal "adl_tvb"
    t.decimal "adl_tvc"
    t.decimal "adl_attnconvo"
    t.decimal "adl_attnconvo_part"
    t.decimal "adl_dishes"
    t.decimal "adl_dishes_perf"
    t.decimal "adl_belong"
    t.decimal "adl_belong_perf"
    t.decimal "adl_beverage"
    t.decimal "adl_beverage_perf"
    t.decimal "adl_snack"
    t.decimal "adl_snack_prep"
    t.decimal "adl_garbage"
    t.decimal "adl_garbage_perf"
    t.decimal "adl_travel"
    t.decimal "adl_travel_perf"
    t.decimal "adl_shop"
    t.decimal "adl_shop_select"
    t.decimal "adl_shop_pay"
    t.decimal "adl_appt"
    t.decimal "adl_appt_aware"
    t.decimal "institutionalized___1"
    t.decimal "adl_alone"
    t.decimal "adl_alone_15m"
    t.decimal "adl_alone_gt1hr"
    t.decimal "adl_alone_lt1hr"
    t.decimal "adl_currev"
    t.decimal "adl_currev_tv"
    t.decimal "adl_currev_outhome"
    t.decimal "adl_currev_inhome"
    t.decimal "adl_read"
    t.decimal "adl_read_lt1hr"
    t.decimal "adl_read_gt1hr"
    t.decimal "adl_write"
    t.decimal "adl_write_complex"
    t.decimal "adl_hob"
    t.decimal "adl_hobls___gam"
    t.decimal "adl_hobls___bing"
    t.decimal "adl_hobls___instr"
    t.decimal "adl_hobls___read"
    t.decimal "adl_hobls___tenn"
    t.decimal "adl_hobls___cword"
    t.decimal "adl_hobls___knit"
    t.decimal "adl_hobls___gard"
    t.decimal "adl_hobls___wshop"
    t.decimal "adl_hobls___art"
    t.decimal "adl_hobls___sew"
    t.decimal "adl_hobls___golf"
    t.decimal "adl_hobls___fish"
    t.decimal "adl_hobls___oth"
    t.text "adl_hobls_oth"
    t.decimal "adl_hobdc___1"
    t.decimal "adl_hob_perf"
    t.decimal "adl_appl"
    t.decimal "adl_applls___wash"
    t.decimal "adl_applls___dish"
    t.decimal "adl_applls___range"
    t.decimal "adl_applls___dry"
    t.decimal "adl_applls___toast"
    t.decimal "adl_applls___micro"
    t.decimal "adl_applls___vac"
    t.decimal "adl_applls___toven"
    t.decimal "adl_applls___fproc"
    t.decimal "adl_applls___oth"
    t.text "adl_applls_oth"
    t.decimal "adl_appl_perf"
    t.text "adl_comm"
    t.decimal "npi_infor"
    t.text "npi_inforsp"
    t.decimal "npi_delus"
    t.decimal "npi_delussev"
    t.decimal "npi_hallu"
    t.decimal "npi_hallusev"
    t.decimal "npi_agita"
    t.decimal "npi_agitasev"
    t.decimal "npi_depre"
    t.decimal "npi_depresev"
    t.decimal "npi_anxie"
    t.decimal "npi_anxiesev"
    t.decimal "npi_elati"
    t.decimal "npi_elatisev"
    t.decimal "npi_apath"
    t.decimal "npi_apathsev"
    t.decimal "npi_disin"
    t.decimal "npi_disinsev"
    t.decimal "npi_irrit"
    t.decimal "npi_irritsev"
    t.decimal "npi_motor"
    t.decimal "npi_motorsev"
    t.decimal "npi_night"
    t.decimal "npi_nightsev"
    t.decimal "npi_appet"
    t.decimal "npi_appetsev"
    t.decimal "adcs_npiq_complete"
    t.decimal "score"
    t.decimal "dk_count"
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
    t.index ["admin_id"], name: "index_admin_history_on_admin_id"
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

  create_table "bhs_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "bhs_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bhs_assignment_table_id"
    t.index ["admin_id"], name: "index_bhs_assignment_history_on_admin_id"
    t.index ["bhs_assignment_table_id"], name: "index_bhs_assignment_history_on_bhs_assignment_table_id"
    t.index ["master_id"], name: "index_bhs_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_bhs_assignment_history_on_user_id"
  end

  create_table "bhs_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "bhs_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_bhs_assignments_on_admin_id"
    t.index ["master_id"], name: "index_bhs_assignments_on_master_id"
    t.index ["user_id"], name: "index_bhs_assignments_on_user_id"
  end

  create_table "bwh_sleep_id_number_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "bwh_sleep_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bwh_sleep_id_number_table_id"
    t.index ["admin_id"], name: "index_bwh_sleep_id_number_history_on_admin_id"
    t.index ["bwh_sleep_id_number_table_id"], name: "index_bwh_sleep_id_number_history_on_bwh_sleep_id_number_table_"
    t.index ["master_id"], name: "index_bwh_sleep_id_number_history_on_master_id"
    t.index ["user_id"], name: "index_bwh_sleep_id_number_history_on_user_id"
  end

  create_table "bwh_sleep_id_numbers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "bwh_sleep_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_bwh_sleep_id_numbers_on_admin_id"
    t.index ["master_id"], name: "index_bwh_sleep_id_numbers_on_master_id"
    t.index ["user_id"], name: "index_bwh_sleep_id_numbers_on_user_id"
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

  create_table "data_request_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "data_request_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_assignment_table_id"
    t.index ["admin_id"], name: "index_data_request_assignment_history_on_admin_id"
    t.index ["data_request_assignment_table_id"], name: "index_data_request_assignment_history_on_data_request_assignmen"
    t.index ["master_id"], name: "index_data_request_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_assignment_history_on_user_id"
  end

  create_table "data_request_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "data_request_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_data_request_assignments_on_admin_id"
    t.index ["master_id"], name: "index_data_request_assignments_on_master_id"
    t.index ["user_id"], name: "index_data_request_assignments_on_user_id"
  end

  create_table "data_request_attrib_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "data_source"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_attrib_id"
    t.index ["data_request_attrib_id"], name: "index_data_request_attrib_history_on_data_request_attrib_id"
    t.index ["master_id"], name: "index_data_request_attrib_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_attrib_history_on_user_id"
  end

  create_table "data_request_attribs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "data_source"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_data_request_attribs_on_master_id"
    t.index ["user_id"], name: "index_data_request_attribs_on_user_id"
  end

  create_table "data_request_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "project_title"
    t.string "concept_sheet_approved_yes_no"
    t.string "concept_sheet_approved_by"
    t.string "full_name"
    t.string "title"
    t.string "institution"
    t.string "others_handling_data"
    t.string "pm_contact"
    t.string "other_pm_contact"
    t.string "data_use_agreement_status"
    t.string "data_use_agreement_notes"
    t.string "terms_of_use_yes_no"
    t.date "data_start_date"
    t.date "data_end_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_id"
    t.string "other_institution"
    t.integer "created_by_user_id"
    t.string "fphs_analyst_yes_no"
    t.string "fphs_server_yes_no"
    t.string "fphs_server_tools_notes"
    t.string "status"
    t.string "off_fphs_server_reason_notes"
    t.string "select_purpose"
    t.string "other_purpose"
    t.string "research_question_notes"
    t.index ["data_request_id"], name: "index_data_request_history_on_data_request_id"
    t.index ["master_id"], name: "index_data_request_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_history_on_user_id"
  end

  create_table "data_request_initial_review_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fphs_analyst_yes_no"
    t.string "fphs_server_yes_no"
    t.string "tag_select_data_classifications", array: true
    t.string "next_step"
    t.string "review_approved_yes_no"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_initial_review_id"
    t.index ["data_request_initial_review_id"], name: "index_data_request_initial_review_history_on_data_request_initi"
    t.index ["master_id"], name: "index_data_request_initial_review_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_initial_review_history_on_user_id"
  end

  create_table "data_request_initial_reviews", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fphs_analyst_yes_no"
    t.string "fphs_server_yes_no"
    t.string "tag_select_data_classifications", array: true
    t.string "next_step"
    t.string "review_approved_yes_no"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_data_request_initial_reviews_on_master_id"
    t.index ["user_id"], name: "index_data_request_initial_reviews_on_user_id"
  end

  create_table "data_request_message_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_message_id"
    t.index ["data_request_message_id"], name: "index_data_request_message_history_on_data_request_message_id"
    t.index ["master_id"], name: "index_data_request_message_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_message_history_on_user_id"
  end

  create_table "data_request_message_to_requester_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_message_to_requester_id"
    t.index ["data_request_message_to_requester_id"], name: "index_data_request_message_to_requester_history_on_data_request"
    t.index ["master_id"], name: "index_data_request_message_to_requester_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_message_to_requester_history_on_user_id"
  end

  create_table "data_request_message_to_requesters", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_data_request_message_to_requesters_on_master_id"
    t.index ["user_id"], name: "index_data_request_message_to_requesters_on_user_id"
  end

  create_table "data_request_message_to_reviewer_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_request_message_to_reviewer_id"
    t.index ["data_request_message_to_reviewer_id"], name: "index_data_request_message_to_reviewer_history_on_data_request_"
    t.index ["master_id"], name: "index_data_request_message_to_reviewer_history_on_master_id"
    t.index ["user_id"], name: "index_data_request_message_to_reviewer_history_on_user_id"
  end

  create_table "data_request_message_to_reviewers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_data_request_message_to_reviewers_on_master_id"
    t.index ["user_id"], name: "index_data_request_message_to_reviewers_on_user_id"
  end

  create_table "data_request_messages", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "message_notes"
    t.integer "created_by_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_data_request_messages_on_master_id"
    t.index ["user_id"], name: "index_data_request_messages_on_user_id"
  end

  create_table "data_requests", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "project_title"
    t.string "full_name"
    t.string "title"
    t.string "institution"
    t.string "others_handling_data"
    t.string "pm_contact"
    t.string "other_pm_contact"
    t.string "data_use_agreement_status"
    t.string "data_use_agreement_notes"
    t.string "terms_of_use_yes_no"
    t.date "data_start_date"
    t.date "data_end_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "other_institution"
    t.integer "created_by_user_id"
    t.string "fphs_analyst_yes_no"
    t.string "fphs_server_yes_no"
    t.string "fphs_server_tools_notes"
    t.string "status"
    t.string "off_fphs_server_reason_notes"
    t.string "select_purpose"
    t.string "other_purpose"
    t.string "research_question_notes"
    t.index ["master_id"], name: "index_data_requests_on_master_id"
    t.index ["user_id"], name: "index_data_requests_on_user_id"
  end

  create_table "data_requests_selected_attrib_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "record_id"
    t.integer "data_request_id"
    t.string "data"
    t.string "variable_name"
    t.boolean "disabled"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_requests_selected_attrib_id"
    t.string "record_type"
    t.index ["data_requests_selected_attrib_id"], name: "index_data_requests_selected_attrib_history_on_data_requests_se"
    t.index ["master_id"], name: "index_data_requests_selected_attrib_history_on_master_id"
    t.index ["user_id"], name: "index_data_requests_selected_attrib_history_on_user_id"
  end

  create_table "data_requests_selected_attribs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "record_id"
    t.integer "data_request_id"
    t.string "data"
    t.string "variable_name"
    t.boolean "disabled"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "record_type"
    t.index ["master_id"], name: "index_data_requests_selected_attribs_on_master_id"
    t.index ["user_id"], name: "index_data_requests_selected_attribs_on_user_id"
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

  create_table "ec", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "rec_type"
    t.string "data"
    t.string "first_name"
    t.string "last_name"
    t.string "select_relationship"
    t.string "rank"
    t.integer "user_id"
    t.integer "master_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emergency_contact_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "first_name"
    t.string "last_name"
    t.string "select_relationship"
    t.string "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "emergency_contact_id"
    t.index ["emergency_contact_id"], name: "index_emergency_contact_history_on_emergency_contact_id"
    t.index ["emergency_contact_id"], name: "index_emergency_contact_history_on_emergency_contact_id"
    t.index ["master_id"], name: "index_emergency_contact_history_on_master_id"
    t.index ["master_id"], name: "index_emergency_contact_history_on_master_id"
    t.index ["user_id"], name: "index_emergency_contact_history_on_user_id"
    t.index ["user_id"], name: "index_emergency_contact_history_on_user_id"
  end

  create_table "emergency_contact_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "first_name"
    t.string "last_name"
    t.string "select_relationship"
    t.string "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "emergency_contact_id"
    t.index ["emergency_contact_id"], name: "index_emergency_contact_history_on_emergency_contact_id"
    t.index ["emergency_contact_id"], name: "index_emergency_contact_history_on_emergency_contact_id"
    t.index ["master_id"], name: "index_emergency_contact_history_on_master_id"
    t.index ["master_id"], name: "index_emergency_contact_history_on_master_id"
    t.index ["user_id"], name: "index_emergency_contact_history_on_user_id"
    t.index ["user_id"], name: "index_emergency_contact_history_on_user_id"
  end

  create_table "emergency_contacts", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "first_name"
    t.string "last_name"
    t.string "select_relationship"
    t.string "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_emergency_contacts_on_master_id"
    t.index ["master_id"], name: "index_emergency_contacts_on_master_id"
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id"
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id"
  end

  create_table "emergency_contacts", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "first_name"
    t.string "last_name"
    t.string "select_relationship"
    t.string "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_emergency_contacts_on_master_id"
    t.index ["master_id"], name: "index_emergency_contacts_on_master_id"
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id"
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id"
  end

  create_table "env_environment_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "name"
    t.string "description"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "env_environment_id"
    t.index ["env_environment_id"], name: "3cea3c1a_id_idx"
    t.index ["master_id"], name: "3cea3c1a_history_master_id"
    t.index ["user_id"], name: "3cea3c1a_user_idx"
  end

  create_table "env_environments", force: :cascade do |t|
    t.bigint "master_id"
    t.string "name"
    t.string "description"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_environments.env_environments_on_master_id"
    t.index ["user_id"], name: "index_environments.env_environments_on_user_id"
  end

  create_table "env_hosting_account_history", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.integer "account_number"
    t.string "login_url"
    t.string "primary_admin"
    t.string "description"
    t.bigint "created_by_user_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "env_hosting_account_id"
    t.index ["created_by_user_id"], name: "d2093078_ref_cb_user_idx_hist"
    t.index ["env_hosting_account_id"], name: "d2093078_id_idx"
    t.index ["user_id"], name: "d2093078_user_idx"
  end

  create_table "env_hosting_accounts", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.integer "account_number"
    t.string "login_url"
    t.string "primary_admin"
    t.string "description"
    t.bigint "created_by_user_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "d2093078_ref_cb_user_idx"
    t.index ["user_id"], name: "index_environments.env_hosting_accounts_on_user_id"
  end

  create_table "env_server_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "name"
    t.string "server_type"
    t.string "hosting_category"
    t.string "server_hosting_name"
    t.string "server_primary_admin"
    t.string "description"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "env_server_id"
    t.bigint "hosting_account_id"
    t.index ["env_server_id"], name: "304c86bf_id_idx"
    t.index ["master_id"], name: "304c86bf_history_master_id"
    t.index ["user_id"], name: "304c86bf_user_idx"
  end

  create_table "env_servers", force: :cascade do |t|
    t.bigint "master_id"
    t.string "name"
    t.string "server_type"
    t.string "hosting_category"
    t.string "server_hosting_name"
    t.string "server_primary_admin"
    t.string "description"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hosting_account_id"
    t.index ["master_id"], name: "index_environments.env_servers_on_master_id"
    t.index ["user_id"], name: "index_environments.env_servers_on_user_id"
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

  create_table "ext_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ext_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ext_assignment_table_id"
    t.index ["ext_assignment_table_id"], name: "index_ext_assignment_history_on_ext_assignment_table_id"
    t.index ["master_id"], name: "index_ext_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_ext_assignment_history_on_user_id"
  end

  create_table "ext_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ext_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ext_assignments_on_master_id"
    t.index ["user_id"], name: "index_ext_assignments_on_user_id"
  end

  create_table "ext_gen_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ext_gen_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ext_gen_assignment_table_id"
    t.index ["admin_id"], name: "index_ext_gen_assignment_history_on_admin_id"
    t.index ["ext_gen_assignment_table_id"], name: "index_ext_gen_assignment_history_on_ext_gen_assignment_table_id"
    t.index ["master_id"], name: "index_ext_gen_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_ext_gen_assignment_history_on_user_id"
  end

  create_table "ext_gen_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "ext_gen_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ext_gen_assignments_on_admin_id"
    t.index ["master_id"], name: "index_ext_gen_assignments_on_master_id"
    t.index ["user_id"], name: "index_ext_gen_assignments_on_user_id"
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

  create_table "femfl_address_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "street"
    t.string "street2"
    t.string "street3"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "source"
    t.integer "rank"
    t.string "rec_type"
    t.string "country"
    t.string "postal_code"
    t.string "region"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "femfl_address_id"
    t.index ["femfl_address_id"], name: "femfl_address_id_idx"
    t.index ["master_id"], name: "index_femfl.femfl_address_history_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_address_history_on_user_id"
  end

  create_table "femfl_addresses", force: :cascade do |t|
    t.bigint "master_id"
    t.string "street"
    t.string "street2"
    t.string "street3"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "source"
    t.integer "rank"
    t.string "rec_type"
    t.string "country"
    t.string "postal_code"
    t.string "region"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_femfl.femfl_addresses_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_addresses_on_user_id"
  end

  create_table "femfl_assignment_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "femfl_id"
    t.bigint "user_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "femfl_assignment_table_id_id"
    t.index ["admin_id"], name: "index_femfl.femfl_assignment_history_on_admin_id"
    t.index ["femfl_assignment_table_id_id"], name: "femfl_assignment_id_idx"
    t.index ["master_id"], name: "index_femfl.femfl_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_assignment_history_on_user_id"
  end

  create_table "femfl_assignments", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "femfl_id"
    t.bigint "user_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_femfl.femfl_assignments_on_admin_id"
    t.index ["master_id"], name: "index_femfl.femfl_assignments_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_assignments_on_user_id"
  end

  create_table "femfl_contact_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "rec_type"
    t.string "data"
    t.integer "rank"
    t.string "source"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "femfl_contact_id"
    t.index ["femfl_contact_id"], name: "femfl_contact_id_idx"
    t.index ["master_id"], name: "index_femfl.femfl_contact_history_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_contact_history_on_user_id"
  end

  create_table "femfl_contacts", force: :cascade do |t|
    t.bigint "master_id"
    t.string "rec_type"
    t.string "data"
    t.integer "rank"
    t.string "source"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_femfl.femfl_contacts_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_contacts_on_user_id"
  end

  create_table "femfl_subject_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "nick_name"
    t.date "birth_date"
    t.integer "rank"
    t.string "source"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "femfl_subject_id"
    t.index ["femfl_subject_id"], name: "femfl_subject_id_idx"
    t.index ["master_id"], name: "index_femfl.femfl_subject_history_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_subject_history_on_user_id"
  end

  create_table "femfl_subjects", force: :cascade do |t|
    t.bigint "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "nick_name"
    t.date "birth_date"
    t.string "source"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rank"
    t.index ["master_id"], name: "index_femfl.femfl_subjects_on_master_id"
    t.index ["user_id"], name: "index_femfl.femfl_subjects_on_user_id"
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

  create_table "grit_access_msm_staff_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_access_msm_staff_id"
    t.index ["grit_access_msm_staff_id"], name: "index_grit_access_msm_staff_history_on_grit_access_msm_staff_id"
    t.index ["master_id"], name: "index_grit_access_msm_staff_history_on_master_id"
    t.index ["user_id"], name: "index_grit_access_msm_staff_history_on_user_id"
  end

  create_table "grit_access_msm_staffs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_access_msm_staffs_on_master_id"
    t.index ["user_id"], name: "index_grit_access_msm_staffs_on_user_id"
  end

  create_table "grit_access_pi_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_access_pi_id"
    t.index ["grit_access_pi_id"], name: "index_grit_access_pi_history_on_grit_access_pi_id"
    t.index ["master_id"], name: "index_grit_access_pi_history_on_master_id"
    t.index ["user_id"], name: "index_grit_access_pi_history_on_user_id"
  end

  create_table "grit_access_pis", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_access_pis_on_master_id"
    t.index ["user_id"], name: "index_grit_access_pis_on_user_id"
  end

  create_table "grit_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_adverse_event_id"
    t.index ["grit_adverse_event_id"], name: "index_grit_adverse_event_history_on_grit_adverse_event_id"
    t.index ["master_id"], name: "index_grit_adverse_event_history_on_master_id"
    t.index ["user_id"], name: "index_grit_adverse_event_history_on_user_id"
  end

  create_table "grit_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_adverse_events_on_master_id"
    t.index ["user_id"], name: "index_grit_adverse_events_on_user_id"
  end

  create_table "grit_appointment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "interventionist"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_appointment_id"
    t.index ["grit_appointment_id"], name: "index_grit_appointment_history_on_grit_appointment_id"
    t.index ["master_id"], name: "index_grit_appointment_history_on_master_id"
    t.index ["user_id"], name: "index_grit_appointment_history_on_user_id"
  end

  create_table "grit_appointments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "interventionist"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_appointments_on_master_id"
    t.index ["user_id"], name: "index_grit_appointments_on_user_id"
  end

  create_table "grit_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "grit_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_assignment_table_id"
    t.index ["admin_id"], name: "index_grit_assignment_history_on_admin_id"
    t.index ["admin_id"], name: "index_grit_assignment_history_on_admin_id"
    t.index ["grit_assignment_table_id"], name: "index_grit_assignment_history_on_grit_assignment_table_id"
    t.index ["grit_assignment_table_id"], name: "index_grit_assignment_history_on_grit_assignment_table_id"
    t.index ["master_id"], name: "index_grit_assignment_history_on_master_id"
    t.index ["master_id"], name: "index_grit_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_grit_assignment_history_on_user_id"
    t.index ["user_id"], name: "index_grit_assignment_history_on_user_id"
  end

  create_table "grit_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "grit_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_assignment_table_id"
    t.index ["admin_id"], name: "index_grit_assignment_history_on_admin_id"
    t.index ["admin_id"], name: "index_grit_assignment_history_on_admin_id"
    t.index ["grit_assignment_table_id"], name: "index_grit_assignment_history_on_grit_assignment_table_id"
    t.index ["grit_assignment_table_id"], name: "index_grit_assignment_history_on_grit_assignment_table_id"
    t.index ["master_id"], name: "index_grit_assignment_history_on_master_id"
    t.index ["master_id"], name: "index_grit_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_grit_assignment_history_on_user_id"
    t.index ["user_id"], name: "index_grit_assignment_history_on_user_id"
  end

  create_table "grit_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "grit_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_grit_assignments_on_admin_id"
    t.index ["admin_id"], name: "index_grit_assignments_on_admin_id"
    t.index ["master_id"], name: "index_grit_assignments_on_master_id"
    t.index ["master_id"], name: "index_grit_assignments_on_master_id"
    t.index ["user_id"], name: "index_grit_assignments_on_user_id"
    t.index ["user_id"], name: "index_grit_assignments_on_user_id"
  end

  create_table "grit_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "grit_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_grit_assignments_on_admin_id"
    t.index ["admin_id"], name: "index_grit_assignments_on_admin_id"
    t.index ["master_id"], name: "index_grit_assignments_on_master_id"
    t.index ["master_id"], name: "index_grit_assignments_on_master_id"
    t.index ["user_id"], name: "index_grit_assignments_on_user_id"
    t.index ["user_id"], name: "index_grit_assignments_on_user_id"
  end

  create_table "grit_consent_mailing_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_consent_mailing_id"
    t.index ["grit_consent_mailing_id"], name: "index_grit_consent_mailing_history_on_grit_consent_mailing_id"
    t.index ["master_id"], name: "index_grit_consent_mailing_history_on_master_id"
    t.index ["user_id"], name: "index_grit_consent_mailing_history_on_user_id"
  end

  create_table "grit_consent_mailings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_consent_mailings_on_master_id"
    t.index ["user_id"], name: "index_grit_consent_mailings_on_user_id"
  end

  create_table "grit_msm_post_testing_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "session_type"
    t.date "session_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_msm_post_testing_id"
    t.index ["grit_msm_post_testing_id"], name: "index_grit_msm_post_testing_history_on_grit_msm_post_testing_id"
    t.index ["master_id"], name: "index_grit_msm_post_testing_history_on_master_id"
    t.index ["user_id"], name: "index_grit_msm_post_testing_history_on_user_id"
  end

  create_table "grit_msm_post_testings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "session_type"
    t.date "session_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_msm_post_testings_on_master_id"
    t.index ["user_id"], name: "index_grit_msm_post_testings_on_user_id"
  end

  create_table "grit_msm_screening_detail_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "screening_date"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_msm_screening_detail_id"
    t.index ["grit_msm_screening_detail_id"], name: "index_grit_msm_screening_detail_history_on_grit_msm_screening_d"
    t.index ["master_id"], name: "index_grit_msm_screening_detail_history_on_master_id"
    t.index ["user_id"], name: "index_grit_msm_screening_detail_history_on_user_id"
  end

  create_table "grit_msm_screening_details", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "screening_date"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_msm_screening_details_on_master_id"
    t.index ["user_id"], name: "index_grit_msm_screening_details_on_user_id"
  end

  create_table "grit_pi_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "pre_call_notes"
    t.string "call_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_pi_followup_id"
    t.index ["grit_pi_followup_id"], name: "index_grit_pi_followup_history_on_grit_pi_followup_id"
    t.index ["master_id"], name: "index_grit_pi_followup_history_on_master_id"
    t.index ["user_id"], name: "index_grit_pi_followup_history_on_user_id"
  end

  create_table "grit_pi_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "pre_call_notes"
    t.string "call_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_pi_followups_on_master_id"
    t.index ["user_id"], name: "index_grit_pi_followups_on_user_id"
  end

  create_table "grit_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_protocol_deviation_id"
    t.index ["grit_protocol_deviation_id"], name: "index_grit_protocol_deviation_history_on_grit_protocol_deviatio"
    t.index ["master_id"], name: "index_grit_protocol_deviation_history_on_master_id"
    t.index ["user_id"], name: "index_grit_protocol_deviation_history_on_user_id"
  end

  create_table "grit_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_protocol_deviations_on_master_id"
    t.index ["user_id"], name: "index_grit_protocol_deviations_on_user_id"
  end

  create_table "grit_protocol_exception_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_protocol_exception_id"
    t.index ["grit_protocol_exception_id"], name: "index_grit_protocol_exception_history_on_grit_protocol_exceptio"
    t.index ["master_id"], name: "index_grit_protocol_exception_history_on_master_id"
    t.index ["user_id"], name: "index_grit_protocol_exception_history_on_user_id"
  end

  create_table "grit_protocol_exceptions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_protocol_exceptions_on_master_id"
    t.index ["user_id"], name: "index_grit_protocol_exceptions_on_user_id"
  end

  create_table "grit_ps_audit_c_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "alcohol_frequency"
    t.string "daily_alcohol"
    t.string "six_or_more_frequency"
    t.string "total_score"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_audit_c_question_id"
    t.index ["grit_ps_audit_c_question_id"], name: "index_grit_ps_audit_c_question_history_on_grit_ps_audit_c_quest"
    t.index ["master_id"], name: "index_grit_ps_audit_c_question_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_audit_c_question_history_on_user_id"
  end

  create_table "grit_ps_audit_c_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "alcohol_frequency"
    t.string "daily_alcohol"
    t.string "six_or_more_frequency"
    t.string "total_score"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_audit_c_questions_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_audit_c_questions_on_user_id"
  end

  create_table "grit_ps_basic_response_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "reliable_internet_yes_no"
    t.string "placeholder_digital_no"
    t.string "cbt_yes_no"
    t.string "cbt_how_long_ago"
    t.string "cbt_notes"
    t.string "grit_times_yes_no"
    t.string "grit_times_notes"
    t.string "work_night_shifts_yes_no"
    t.integer "number_times_per_week_work_night_shifts"
    t.string "narcolepsy_diagnosis_yes_no_dont_know"
    t.string "narcolepsy_diagnosis_notes"
    t.string "antiseizure_meds_yes_no"
    t.string "seizure_in_ten_years_yes_no"
    t.string "major_psychiatric_disorder_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_basic_response_id"
    t.index ["grit_ps_basic_response_id"], name: "index_grit_ps_basic_response_history_on_grit_ps_basic_response_"
    t.index ["master_id"], name: "index_grit_ps_basic_response_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_basic_response_history_on_user_id"
  end

  create_table "grit_ps_basic_responses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "reliable_internet_yes_no"
    t.string "placeholder_digital_no"
    t.string "cbt_yes_no"
    t.string "cbt_how_long_ago"
    t.string "cbt_notes"
    t.string "grit_times_yes_no"
    t.string "grit_times_notes"
    t.string "work_night_shifts_yes_no"
    t.integer "number_times_per_week_work_night_shifts"
    t.string "narcolepsy_diagnosis_yes_no_dont_know"
    t.string "narcolepsy_diagnosis_notes"
    t.string "antiseizure_meds_yes_no"
    t.string "seizure_in_ten_years_yes_no"
    t.string "major_psychiatric_disorder_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_basic_responses_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_basic_responses_on_user_id"
  end

  create_table "grit_ps_eligibility_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.string "any_questions_yes_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_eligibility_followup_id"
    t.index ["grit_ps_eligibility_followup_id"], name: "index_grit_ps_eligibility_followup_history_on_grit_ps_eligibili"
    t.index ["master_id"], name: "index_grit_ps_eligibility_followup_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_eligibility_followup_history_on_user_id"
  end

  create_table "grit_ps_eligibility_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.string "any_questions_yes_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_eligibility_followups_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_eligibility_followups_on_user_id"
  end

  create_table "grit_ps_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "notes"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "select_still_interested"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_eligible_id"
    t.index ["grit_ps_eligible_id"], name: "index_grit_ps_eligible_history_on_grit_ps_eligible_id"
    t.index ["master_id"], name: "index_grit_ps_eligible_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_eligible_history_on_user_id"
  end

  create_table "grit_ps_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "notes"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "select_still_interested"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_eligibles_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_eligibles_on_user_id"
  end

  create_table "grit_ps_initial_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "looked_at_website_yes_no"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_initial_screening_id"
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "still_interested_2_yes_no"
    t.index ["grit_ps_initial_screening_id"], name: "index_grit_ps_initial_screening_history_on_grit_ps_initial_scre"
    t.index ["master_id"], name: "index_grit_ps_initial_screening_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_initial_screening_history_on_user_id"
  end

  create_table "grit_ps_initial_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "looked_at_website_yes_no"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "still_interested_2_yes_no"
    t.index ["master_id"], name: "index_grit_ps_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_initial_screenings_on_user_id"
  end

  create_table "grit_ps_non_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "placeholder_any_questions_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "placeholder_additional_questions_no"
    t.string "placeholder_additional_questions_yes"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "placeholder_consent_to_pass_info_2_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_non_eligible_id"
    t.index ["grit_ps_non_eligible_id"], name: "index_grit_ps_non_eligible_history_on_grit_ps_non_eligible_id"
    t.index ["master_id"], name: "index_grit_ps_non_eligible_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_non_eligible_history_on_user_id"
  end

  create_table "grit_ps_non_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "placeholder_any_questions_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "placeholder_additional_questions_no"
    t.string "placeholder_additional_questions_yes"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "placeholder_consent_to_pass_info_2_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_non_eligibles_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_non_eligibles_on_user_id"
  end

  create_table "grit_ps_pain_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_pain_interfere"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_pain_question_id"
    t.index ["grit_ps_pain_question_id"], name: "index_grit_ps_pain_question_history_on_grit_ps_pain_question_id"
    t.index ["master_id"], name: "index_grit_ps_pain_question_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_pain_question_history_on_user_id"
  end

  create_table "grit_ps_pain_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_pain_interfere"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_pain_questions_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_pain_questions_on_user_id"
  end

  create_table "grit_ps_participation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "commit_to_attend_yes_no"
    t.string "small_group_yes_no"
    t.string "any_questions_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_participation_id"
    t.index ["grit_ps_participation_id"], name: "index_grit_ps_participation_history_on_grit_ps_participation_id"
    t.index ["master_id"], name: "index_grit_ps_participation_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_participation_history_on_user_id"
  end

  create_table "grit_ps_participations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "commit_to_attend_yes_no"
    t.string "small_group_yes_no"
    t.string "any_questions_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_participations_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_participations_on_user_id"
  end

  create_table "grit_ps_possibly_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_possibly_eligible_id"
    t.index ["grit_ps_possibly_eligible_id"], name: "index_grit_ps_possibly_eligible_history_on_grit_ps_possibly_eli"
    t.index ["master_id"], name: "index_grit_ps_possibly_eligible_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_possibly_eligible_history_on_user_id"
  end

  create_table "grit_ps_possibly_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_possibly_eligibles_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_possibly_eligibles_on_user_id"
  end

  create_table "grit_ps_screener_response_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "comm_clearly_in_english_yes_no"
    t.string "give_informed_consent_yes_no_dont_know"
    t.string "give_informed_consent_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_ps_screener_response_id"
    t.index ["grit_ps_screener_response_id"], name: "index_grit_ps_screener_response_history_on_grit_ps_screener_res"
    t.index ["master_id"], name: "index_grit_ps_screener_response_history_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_screener_response_history_on_user_id"
  end

  create_table "grit_ps_screener_responses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "comm_clearly_in_english_yes_no"
    t.string "give_informed_consent_yes_no_dont_know"
    t.string "give_informed_consent_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_ps_screener_responses_on_master_id"
    t.index ["user_id"], name: "index_grit_ps_screener_responses_on_user_id"
  end

  create_table "grit_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "requires_study_partner_blank_yes_no"
    t.string "notes"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.string "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "consent_performed_yes_no"
    t.string "did_subject_consent_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_screening_id"
    t.index ["grit_screening_id"], name: "index_grit_screening_history_on_grit_screening_id"
    t.index ["master_id"], name: "index_grit_screening_history_on_master_id"
    t.index ["user_id"], name: "index_grit_screening_history_on_user_id"
  end

  create_table "grit_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "requires_study_partner_blank_yes_no"
    t.string "notes"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.string "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "consent_performed_yes_no"
    t.string "did_subject_consent_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_screenings_on_master_id"
    t.index ["user_id"], name: "index_grit_screenings_on_user_id"
  end

  create_table "grit_secure_note_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_secure_note_id"
    t.index ["grit_secure_note_id"], name: "index_grit_secure_note_history_on_grit_secure_note_id"
    t.index ["master_id"], name: "index_grit_secure_note_history_on_master_id"
    t.index ["user_id"], name: "index_grit_secure_note_history_on_user_id"
  end

  create_table "grit_secure_notes", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_secure_notes_on_master_id"
    t.index ["user_id"], name: "index_grit_secure_notes_on_user_id"
  end

  create_table "grit_withdrawal_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grit_withdrawal_id"
    t.index ["grit_withdrawal_id"], name: "index_grit_withdrawal_history_on_grit_withdrawal_id"
    t.index ["master_id"], name: "index_grit_withdrawal_history_on_master_id"
    t.index ["user_id"], name: "index_grit_withdrawal_history_on_user_id"
  end

  create_table "grit_withdrawals", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_grit_withdrawals_on_master_id"
    t.index ["user_id"], name: "index_grit_withdrawals_on_user_id"
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

  create_table "ipa_adl_informant_screener_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_regarding_eating"
    t.string "select_regarding_walking"
    t.string "select_regarding_bowel_and_bladder"
    t.string "select_regarding_bathing"
    t.string "select_regarding_grooming"
    t.string "select_regarding_dressing"
    t.string "select_regarding_dressing_performance"
    t.string "select_regarding_getting_dressed"
    t.string "used_telephone_yes_no_dont_know"
    t.string "select_telephone_performance"
    t.string "watched_tv_yes_no_dont_know"
    t.string "selected_programs_yes_no_dont_know"
    t.string "talk_about_content_during_yes_no_dont_know"
    t.string "talk_about_content_after_yes_no_dont_know"
    t.string "pay_attention_to_conversation_yes_no_dont_know"
    t.string "select_degree_of_participation"
    t.string "clear_dishes_yes_no_dont_know"
    t.string "select_clear_dishes_performance"
    t.string "find_personal_belongings_yes_no_dont_know"
    t.string "select_find_personal_belongings_performance"
    t.string "obtain_beverage_yes_no_dont_know"
    t.string "select_obtain_beverage_performance"
    t.string "make_meal_yes_no_dont_know"
    t.string "select_make_meal_performance"
    t.string "dispose_of_garbage_yes_no_dont_know"
    t.string "select_dispose_of_garbage_performance"
    t.string "get_around_outside_yes_no_dont_know"
    t.string "select_get_around_outside_performance"
    t.string "go_shopping_yes_no_dont_know"
    t.string "select_go_shopping_performance"
    t.string "pay_for_items_yes_no_dont_know"
    t.string "keep_appointments_yes_no_dont_know"
    t.string "select_keep_appointments_performance"
    t.string "institutionalized_no_yes"
    t.string "left_on_own_yes_no_dont_know"
    t.string "away_from_home_yes_no_dont_know"
    t.string "at_home_more_than_hour_yes_no_dont_know"
    t.string "at_home_less_than_hour_yes_no_dont_know"
    t.string "talk_about_current_events_yes_no_dont_know"
    t.string "did_not_take_part_in_yes_no_dont_know"
    t.string "took_part_in_outside_home_yes_no_dont_know"
    t.string "took_part_in_at_home_yes_no_dont_know"
    t.string "read_yes_no_dont_know"
    t.string "talk_about_reading_shortly_after_yes_no_dont_know"
    t.string "talk_about_reading_later_yes_no_dont_know"
    t.string "write_yes_no_dont_know"
    t.string "select_write_performance"
    t.string "pastime_yes_no_dont_know"
    t.string "multi_select_pastimes", array: true
    t.string "pastime_other"
    t.string "pastimes_only_at_daycare_no_yes"
    t.string "select_pastimes_only_at_daycare_performance"
    t.string "use_household_appliance_yes_no_dont_know"
    t.string "multi_select_household_appliances", array: true
    t.string "household_appliance_other"
    t.string "select_household_appliance_performance"
    t.integer "npi_infor"
    t.string "npi_inforsp"
    t.integer "npi_delus"
    t.integer "npi_delussev"
    t.integer "npi_hallu"
    t.integer "npi_hallusev"
    t.integer "npi_agita"
    t.integer "npi_agitasev"
    t.integer "npi_depre"
    t.integer "npi_depresev"
    t.integer "npi_anxie"
    t.integer "npi_anxiesev"
    t.integer "npi_elati"
    t.integer "npi_elatisev"
    t.integer "npi_apath"
    t.integer "npi_apathsev"
    t.integer "npi_disin"
    t.integer "npi_disinsev"
    t.integer "npi_irrit"
    t.integer "npi_irritsev"
    t.integer "npi_motor"
    t.integer "npi_motorsev"
    t.integer "npi_night"
    t.integer "npi_nightsev"
    t.integer "npi_appet"
    t.integer "npi_appetsev"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_adl_informant_screener_id"
    t.index ["ipa_adl_informant_screener_id"], name: "index_ipa_adl_informant_screener_history_on_ipa_adl_informant_s"
    t.index ["master_id"], name: "index_ipa_adl_informant_screener_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_adl_informant_screener_history_on_user_id"
  end

  create_table "ipa_adl_informant_screeners", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_regarding_eating"
    t.string "select_regarding_walking"
    t.string "select_regarding_bowel_and_bladder"
    t.string "select_regarding_bathing"
    t.string "select_regarding_grooming"
    t.string "select_regarding_dressing"
    t.string "select_regarding_dressing_performance"
    t.string "select_regarding_getting_dressed"
    t.string "used_telephone_yes_no_dont_know"
    t.string "select_telephone_performance"
    t.string "watched_tv_yes_no_dont_know"
    t.string "selected_programs_yes_no_dont_know"
    t.string "talk_about_content_during_yes_no_dont_know"
    t.string "talk_about_content_after_yes_no_dont_know"
    t.string "pay_attention_to_conversation_yes_no_dont_know"
    t.string "select_degree_of_participation"
    t.string "clear_dishes_yes_no_dont_know"
    t.string "select_clear_dishes_performance"
    t.string "find_personal_belongings_yes_no_dont_know"
    t.string "select_find_personal_belongings_performance"
    t.string "obtain_beverage_yes_no_dont_know"
    t.string "select_obtain_beverage_performance"
    t.string "make_meal_yes_no_dont_know"
    t.string "select_make_meal_performance"
    t.string "dispose_of_garbage_yes_no_dont_know"
    t.string "select_dispose_of_garbage_performance"
    t.string "get_around_outside_yes_no_dont_know"
    t.string "select_get_around_outside_performance"
    t.string "go_shopping_yes_no_dont_know"
    t.string "select_go_shopping_performance"
    t.string "pay_for_items_yes_no_dont_know"
    t.string "keep_appointments_yes_no_dont_know"
    t.string "select_keep_appointments_performance"
    t.string "institutionalized_no_yes"
    t.string "left_on_own_yes_no_dont_know"
    t.string "away_from_home_yes_no_dont_know"
    t.string "at_home_more_than_hour_yes_no_dont_know"
    t.string "at_home_less_than_hour_yes_no_dont_know"
    t.string "talk_about_current_events_yes_no_dont_know"
    t.string "did_not_take_part_in_yes_no_dont_know"
    t.string "took_part_in_outside_home_yes_no_dont_know"
    t.string "took_part_in_at_home_yes_no_dont_know"
    t.string "read_yes_no_dont_know"
    t.string "talk_about_reading_shortly_after_yes_no_dont_know"
    t.string "talk_about_reading_later_yes_no_dont_know"
    t.string "write_yes_no_dont_know"
    t.string "select_write_performance"
    t.string "pastime_yes_no_dont_know"
    t.string "multi_select_pastimes", array: true
    t.string "pastime_other"
    t.string "pastimes_only_at_daycare_no_yes"
    t.string "select_pastimes_only_at_daycare_performance"
    t.string "use_household_appliance_yes_no_dont_know"
    t.string "multi_select_household_appliances", array: true
    t.string "household_appliance_other"
    t.string "select_household_appliance_performance"
    t.integer "npi_infor"
    t.string "npi_inforsp"
    t.integer "npi_delus"
    t.integer "npi_delussev"
    t.integer "npi_hallu"
    t.integer "npi_hallusev"
    t.integer "npi_agita"
    t.integer "npi_agitasev"
    t.integer "npi_depre"
    t.integer "npi_depresev"
    t.integer "npi_anxie"
    t.integer "npi_anxiesev"
    t.integer "npi_elati"
    t.integer "npi_elatisev"
    t.integer "npi_apath"
    t.integer "npi_apathsev"
    t.integer "npi_disin"
    t.integer "npi_disinsev"
    t.integer "npi_irrit"
    t.integer "npi_irritsev"
    t.integer "npi_motor"
    t.integer "npi_motorsev"
    t.integer "npi_night"
    t.integer "npi_nightsev"
    t.integer "npi_appet"
    t.integer "npi_appetsev"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_adl_informant_screeners_on_master_id"
    t.index ["user_id"], name: "index_ipa_adl_informant_screeners_on_user_id"
  end

  create_table "ipa_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_adverse_event_id"
    t.index ["ipa_adverse_event_id"], name: "index_ipa_adverse_event_history_on_ipa_adverse_event_id"
    t.index ["master_id"], name: "index_ipa_adverse_event_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_adverse_event_history_on_user_id"
  end

  create_table "ipa_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_adverse_events_on_master_id"
    t.index ["user_id"], name: "index_ipa_adverse_events_on_user_id"
  end

  create_table "ipa_appointment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_appointment_id"
    t.date "visit_end_date"
    t.string "select_status"
    t.string "notes"
    t.string "select_schedule"
    t.date "covid19_test_date"
    t.time "covid19_test_time"
    t.index ["ipa_appointment_id"], name: "index_ipa_appointment_history_on_ipa_appointment_id"
    t.index ["master_id"], name: "index_ipa_appointment_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_appointment_history_on_user_id"
  end

  create_table "ipa_appointments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "visit_end_date"
    t.string "select_status"
    t.string "notes"
    t.string "select_schedule"
    t.date "covid19_test_date"
    t.time "covid19_test_time"
    t.index ["master_id"], name: "index_ipa_appointments_on_master_id"
    t.index ["user_id"], name: "index_ipa_appointments_on_user_id"
    t.index ["visit_start_date"], name: "ipa_appointments_visit_start_date_key", unique: true
  end

  create_table "ipa_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "ipa_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_assignment_table_id"
    t.index ["admin_id"], name: "index_ipa_assignment_history_on_admin_id"
    t.index ["ipa_assignment_table_id"], name: "index_ipa_assignment_history_on_ipa_assignment_table_id"
    t.index ["master_id"], name: "index_ipa_assignment_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_assignment_history_on_user_id"
  end

  create_table "ipa_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "ipa_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_ipa_assignments_on_admin_id"
    t.index ["master_id"], name: "index_ipa_assignments_on_master_id"
    t.index ["user_id"], name: "index_ipa_assignments_on_user_id"
  end

  create_table "ipa_consent_mailing_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_consent_mailing_id"
    t.index ["ipa_consent_mailing_id"], name: "index_ipa_consent_mailing_history_on_ipa_consent_mailing_id"
    t.index ["master_id"], name: "index_ipa_consent_mailing_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_consent_mailing_history_on_user_id"
  end

  create_table "ipa_consent_mailings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_consent_mailings_on_master_id"
    t.index ["user_id"], name: "index_ipa_consent_mailings_on_user_id"
  end

  create_table "ipa_covid_prescreening_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "foreign_travel_yes_no"
    t.string "covid_tested_yes_no"
    t.string "select_test_result"
    t.date "test_date"
    t.string "test_location_notes"
    t.string "covid_contact_yes_no_dont_know"
    t.date "contact_date"
    t.string "household_isolation_yes_no"
    t.string "fever_yes_no"
    t.string "tag_select_symptoms"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ipa_covid_prescreening_id"
    t.index ["ipa_covid_prescreening_id"], name: "be198d9e_id_idx"
    t.index ["master_id"], name: "be198d9e_history_master_id"
    t.index ["user_id"], name: "be198d9e_user_idx"
  end

  create_table "ipa_covid_prescreenings", force: :cascade do |t|
    t.bigint "master_id"
    t.string "foreign_travel_yes_no"
    t.string "covid_tested_yes_no"
    t.string "select_test_result"
    t.date "test_date"
    t.string "test_location_notes"
    t.string "covid_contact_yes_no_dont_know"
    t.date "contact_date"
    t.string "household_isolation_yes_no"
    t.string "fever_yes_no"
    t.string "tag_select_symptoms"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_ops.ipa_covid_prescreenings_on_master_id"
    t.index ["user_id"], name: "index_ipa_ops.ipa_covid_prescreenings_on_user_id"
  end

  create_table "ipa_datadic", id: :integer, default: -> { "nextval('ipaops_datadic_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "variable_name", null: false
    t.text "domain"
    t.text "field_type_rc"
    t.text "field_type_sa"
    t.text "field_label"
    t.text "field_attributes"
    t.text "field_note"
    t.text "text_valid_type"
    t.text "text_valid_min"
    t.text "text_valid_max"
    t.text "required_field"
    t.text "field_attr_array", array: true
    t.text "source"
    t.text "form_name"
    t.text "owner"
    t.text "classification"
    t.text "display"
  end

  create_table "ipa_exit_interview_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "notes"
    t.string "labs_returned_yes_no"
    t.string "labs_notes"
    t.string "dexa_returned_yes_no"
    t.string "dexa_notes"
    t.string "brain_mri_returned_yes_no"
    t.string "brain_mri_notes"
    t.string "neuro_psych_returned_yes_no"
    t.string "neuro_psych_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_exit_interview_id"
    t.index ["ipa_exit_interview_id"], name: "index_ipa_exit_interview_history_on_ipa_exit_interview_id"
    t.index ["master_id"], name: "index_ipa_exit_interview_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_exit_interview_history_on_user_id"
  end

  create_table "ipa_exit_interviews", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "notes"
    t.string "labs_returned_yes_no"
    t.string "labs_notes"
    t.string "dexa_returned_yes_no"
    t.string "dexa_notes"
    t.string "brain_mri_returned_yes_no"
    t.string "brain_mri_notes"
    t.string "neuro_psych_returned_yes_no"
    t.string "neuro_psych_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_exit_interviews_on_master_id"
    t.index ["user_id"], name: "index_ipa_exit_interviews_on_user_id"
  end

  create_table "ipa_file_creator_history", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "staff_id_no"
    t.string "role"
    t.string "organization"
    t.string "department"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_file_creator_id"
    t.index ["ipa_file_creator_id"], name: "index_ipa_file_creator_history_on_ipa_file_creator_id"
    t.index ["user_id"], name: "index_ipa_file_creator_history_on_user_id"
  end

  create_table "ipa_file_creators", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "staff_id_no"
    t.string "role"
    t.string "organization"
    t.string "department"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_ipa_file_creators_on_user_id"
  end

  create_table "ipa_four_wk_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "select_sensory_testing_returned"
    t.string "sensory_testing_notes"
    t.string "select_liver_mri_returned"
    t.string "liver_mri_notes"
    t.string "select_physical_function_returned"
    t.string "physical_function_notes"
    t.string "select_sleep_returned"
    t.string "sleep_notes"
    t.string "select_cardiology_returned"
    t.string "cardiology_notes"
    t.string "select_xray_returned"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_four_wk_followup_id"
    t.string "select_eeg_returned"
    t.string "eeg_notes"
    t.index ["ipa_four_wk_followup_id"], name: "index_ipa_four_wk_followup_history_on_ipa_four_wk_followup_id"
    t.index ["master_id"], name: "index_ipa_four_wk_followup_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_four_wk_followup_history_on_user_id"
  end

  create_table "ipa_four_wk_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "select_sensory_testing_returned"
    t.string "sensory_testing_notes"
    t.string "select_liver_mri_returned"
    t.string "liver_mri_notes"
    t.string "select_physical_function_returned"
    t.string "physical_function_notes"
    t.string "select_sleep_returned"
    t.string "sleep_notes"
    t.string "select_cardiology_returned"
    t.string "cardiology_notes"
    t.string "select_xray_returned"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_eeg_returned"
    t.string "eeg_notes"
    t.index ["master_id"], name: "index_ipa_four_wk_followups_on_master_id"
    t.index ["user_id"], name: "index_ipa_four_wk_followups_on_user_id"
  end

  create_table "ipa_hotel_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "hotel"
    t.string "room_number"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_hotel_id"
    t.index ["ipa_hotel_id"], name: "index_ipa_hotel_history_on_ipa_hotel_id"
    t.index ["master_id"], name: "index_ipa_hotel_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_hotel_history_on_user_id"
  end

  create_table "ipa_hotels", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "hotel"
    t.string "room_number"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "check_in_date"
    t.time "check_in_time"
    t.date "check_out_date"
    t.time "check_out_time"
    t.index ["master_id"], name: "index_ipa_hotels_on_master_id"
    t.index ["user_id"], name: "index_ipa_hotels_on_user_id"
  end

  create_table "ipa_incidental_finding_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.date "anthropometrics_date"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.date "lab_results_date"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.date "dexa_date"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.date "brain_mri_date"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.date "neuro_psych_date"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.date "sensory_testing_date"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.date "liver_mri_date"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.date "physical_function_date"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.date "eeg_date"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.date "sleep_date"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.date "cardiac_date"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.date "xray_date"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_incidental_finding_id"
    t.index ["ipa_incidental_finding_id"], name: "index_ipa_incidental_finding_history_on_ipa_incidental_finding_"
    t.index ["master_id"], name: "index_ipa_incidental_finding_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_incidental_finding_history_on_user_id"
  end

  create_table "ipa_incidental_findings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.date "anthropometrics_date"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.date "lab_results_date"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.date "dexa_date"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.date "brain_mri_date"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.date "neuro_psych_date"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.date "sensory_testing_date"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.date "liver_mri_date"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.date "physical_function_date"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.date "eeg_date"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.date "sleep_date"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.date "cardiac_date"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.date "xray_date"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_incidental_findings_on_master_id"
    t.index ["user_id"], name: "index_ipa_incidental_findings_on_user_id"
  end

  create_table "ipa_inex_checklist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fixed_checklist_type"
    t.string "ix_consent_blank_yes_no"
    t.string "ix_consent_details"
    t.string "ix_not_pro_blank_yes_no"
    t.string "ix_not_pro_details"
    t.string "ix_age_range_blank_yes_no"
    t.string "ix_age_range_details"
    t.string "ix_weight_ok_blank_yes_no"
    t.string "ix_weight_ok_details"
    t.string "ix_no_seizure_blank_yes_no"
    t.string "ix_no_seizure_details"
    t.string "ix_no_device_impl_blank_yes_no"
    t.string "ix_no_device_impl_details"
    t.string "ix_no_ferromagnetic_impl_blank_yes_no"
    t.string "ix_no_ferromagnetic_impl_details"
    t.string "ix_diagnosed_sleep_apnea_blank_yes_no"
    t.string "ix_diagnosed_sleep_apnea_details"
    t.string "ix_diagnosed_heart_stroke_or_meds_blank_yes_no"
    t.string "ix_diagnosed_heart_stroke_or_meds_details"
    t.string "ix_chronic_pain_and_meds_blank_yes_no"
    t.string "ix_chronic_pain_and_meds_details"
    t.string "ix_tmoca_score_blank_yes_no"
    t.string "ix_tmoca_score_details"
    t.string "ix_no_hemophilia_blank_yes_no"
    t.string "ix_no_hemophilia_details"
    t.string "ix_raynauds_ok_blank_yes_no"
    t.string "ix_raynauds_ok_details"
    t.string "ix_mi_ok_blank_yes_no"
    t.string "ix_mi_ok_details"
    t.string "ix_bicycle_ok_blank_yes_no"
    t.string "ix_bicycle_ok_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_inex_checklist_id"
    t.string "select_subject_eligibility"
    t.index ["ipa_inex_checklist_id"], name: "index_ipa_inex_checklist_history_on_ipa_inex_checklist_id"
    t.index ["master_id"], name: "index_ipa_inex_checklist_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_inex_checklist_history_on_user_id"
  end

  create_table "ipa_inex_checklists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fixed_checklist_type"
    t.string "ix_consent_blank_yes_no"
    t.string "ix_consent_details"
    t.string "ix_not_pro_blank_yes_no"
    t.string "ix_not_pro_details"
    t.string "ix_age_range_blank_yes_no"
    t.string "ix_age_range_details"
    t.string "ix_weight_ok_blank_yes_no"
    t.string "ix_weight_ok_details"
    t.string "ix_no_seizure_blank_yes_no"
    t.string "ix_no_seizure_details"
    t.string "ix_no_device_impl_blank_yes_no"
    t.string "ix_no_device_impl_details"
    t.string "ix_no_ferromagnetic_impl_blank_yes_no"
    t.string "ix_no_ferromagnetic_impl_details"
    t.string "ix_diagnosed_sleep_apnea_blank_yes_no"
    t.string "ix_diagnosed_sleep_apnea_details"
    t.string "ix_diagnosed_heart_stroke_or_meds_blank_yes_no"
    t.string "ix_diagnosed_heart_stroke_or_meds_details"
    t.string "ix_chronic_pain_and_meds_blank_yes_no"
    t.string "ix_chronic_pain_and_meds_details"
    t.string "ix_tmoca_score_blank_yes_no"
    t.string "ix_tmoca_score_details"
    t.string "ix_no_hemophilia_blank_yes_no"
    t.string "ix_no_hemophilia_details"
    t.string "ix_raynauds_ok_blank_yes_no"
    t.string "ix_raynauds_ok_details"
    t.string "ix_mi_ok_blank_yes_no"
    t.string "ix_mi_ok_details"
    t.string "ix_bicycle_ok_blank_yes_no"
    t.string "ix_bicycle_ok_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_subject_eligibility"
    t.index ["master_id"], name: "index_ipa_inex_checklists_on_master_id"
    t.index ["user_id"], name: "index_ipa_inex_checklists_on_user_id"
  end

  create_table "ipa_initial_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_initial_screening_id"
    t.index ["ipa_initial_screening_id"], name: "index_ipa_initial_screening_history_on_ipa_initial_screening_id"
    t.index ["master_id"], name: "index_ipa_initial_screening_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_initial_screening_history_on_user_id"
  end

  create_table "ipa_initial_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_ipa_initial_screenings_on_user_id"
  end

  create_table "ipa_medical_detail_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "convulsion_or_seizure_blank_yes_no_dont_know"
    t.string "convulsion_or_seizure_details"
    t.string "sleep_disorder_blank_yes_no_dont_know"
    t.string "sleep_disorder_details"
    t.string "sleep_apnea_device_no_yes"
    t.string "sleep_apnea_device_details"
    t.string "chronic_pain_blank_yes_no"
    t.string "chronic_pain_details"
    t.string "chronic_pain_meds_blank_yes_no_dont_know"
    t.string "chronic_pain_meds_details"
    t.string "hypertension_diagnosis_blank_yes_no_dont_know"
    t.string "hypertension_medications_blank_yes_no"
    t.string "hypertension_diagnosis_details"
    t.string "diabetes_diagnosis_blank_yes_no_dont_know"
    t.string "diabetes_medications_blank_yes_no"
    t.string "diabetes_diagnosis_details"
    t.string "hemophilia_blank_yes_no_dont_know"
    t.string "hemophilia_details"
    t.string "high_cholesterol_diagnosis_blank_yes_no_dont_know"
    t.string "high_cholesterol_medications_blank_yes_no"
    t.string "high_cholesterol_diagnosis_details"
    t.string "caridiac_pacemaker_blank_yes_no_dont_know"
    t.string "caridiac_pacemaker_details"
    t.string "other_heart_conditions_blank_yes_no_dont_know"
    t.string "other_heart_conditions_details"
    t.string "memory_problems_blank_yes_no_dont_know"
    t.string "memory_problems_details"
    t.string "mental_health_conditions_blank_yes_no_dont_know"
    t.string "mental_health_conditions_details"
    t.string "mental_health_help_blank_yes_no_dont_know"
    t.string "mental_health_help_details"
    t.string "neurological_problems_blank_yes_no_dont_know"
    t.string "neurological_problems_details"
    t.string "past_mri_yes_no_dont_know"
    t.string "past_mri_details"
    t.string "dietary_restrictions_blank_yes_no_dont_know"
    t.string "dietary_restrictions_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_medical_detail_id"
    t.string "metal_implants_blank_yes_no_dont_know"
    t.string "metal_implants_details"
    t.string "metal_implants_mri_approval_details"
    t.string "radiation_details"
    t.string "radiation_blank_yes_no"
    t.string "form_version"
    t.integer "number_of_nights_sleep_apnea_device"
    t.string "sleep_apnea_travel_with_device_yes_no"
    t.string "select_radiation_type"
    t.index ["ipa_medical_detail_id"], name: "index_ipa_medical_detail_history_on_ipa_medical_detail_id"
    t.index ["master_id"], name: "index_ipa_medical_detail_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_medical_detail_history_on_user_id"
  end

  create_table "ipa_medical_details", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "convulsion_or_seizure_blank_yes_no_dont_know"
    t.string "convulsion_or_seizure_details"
    t.string "sleep_disorder_blank_yes_no_dont_know"
    t.string "sleep_disorder_details"
    t.string "sleep_apnea_device_no_yes"
    t.string "sleep_apnea_device_details"
    t.string "chronic_pain_blank_yes_no"
    t.string "chronic_pain_details"
    t.string "chronic_pain_meds_blank_yes_no_dont_know"
    t.string "chronic_pain_meds_details"
    t.string "hypertension_diagnosis_blank_yes_no_dont_know"
    t.string "hypertension_medications_blank_yes_no"
    t.string "hypertension_diagnosis_details"
    t.string "diabetes_diagnosis_blank_yes_no_dont_know"
    t.string "diabetes_medications_blank_yes_no"
    t.string "diabetes_diagnosis_details"
    t.string "hemophilia_blank_yes_no_dont_know"
    t.string "hemophilia_details"
    t.string "high_cholesterol_diagnosis_blank_yes_no_dont_know"
    t.string "high_cholesterol_medications_blank_yes_no"
    t.string "high_cholesterol_diagnosis_details"
    t.string "caridiac_pacemaker_blank_yes_no_dont_know"
    t.string "caridiac_pacemaker_details"
    t.string "other_heart_conditions_blank_yes_no_dont_know"
    t.string "other_heart_conditions_details"
    t.string "memory_problems_blank_yes_no_dont_know"
    t.string "memory_problems_details"
    t.string "mental_health_conditions_blank_yes_no_dont_know"
    t.string "mental_health_conditions_details"
    t.string "mental_health_help_blank_yes_no_dont_know"
    t.string "mental_health_help_details"
    t.string "neurological_problems_blank_yes_no_dont_know"
    t.string "neurological_problems_details"
    t.string "past_mri_yes_no_dont_know"
    t.string "past_mri_details"
    t.string "dietary_restrictions_blank_yes_no_dont_know"
    t.string "dietary_restrictions_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "metal_implants_blank_yes_no_dont_know"
    t.string "metal_implants_details"
    t.string "metal_implants_mri_approval_details"
    t.string "radiation_details"
    t.string "radiation_blank_yes_no"
    t.string "form_version"
    t.integer "number_of_nights_sleep_apnea_device"
    t.string "sleep_apnea_travel_with_device_yes_no"
    t.string "select_radiation_type"
    t.index ["master_id"], name: "index_ipa_medical_details_on_master_id"
    t.index ["user_id"], name: "index_ipa_medical_details_on_user_id"
  end

  create_table "ipa_medication_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "current_meds_blank_yes_no_dont_know"
    t.string "current_meds_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_medication_id"
    t.index ["ipa_medication_id"], name: "index_ipa_medication_history_on_ipa_medication_id"
    t.index ["master_id"], name: "index_ipa_medication_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_medication_history_on_user_id"
  end

  create_table "ipa_medications", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "current_meds_blank_yes_no_dont_know"
    t.string "current_meds_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_medications_on_master_id"
    t.index ["user_id"], name: "index_ipa_medications_on_user_id"
  end

  create_table "ipa_mednav_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_mednav_followup_id"
    t.index ["ipa_mednav_followup_id"], name: "index_ipa_mednav_followup_history_on_ipa_mednav_followup_id"
    t.index ["master_id"], name: "index_ipa_mednav_followup_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_mednav_followup_history_on_user_id"
  end

  create_table "ipa_mednav_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_mednav_followups_on_master_id"
    t.index ["user_id"], name: "index_ipa_mednav_followups_on_user_id"
  end

  create_table "ipa_mednav_provider_comm_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_mednav_provider_comm_id"
    t.index ["ipa_mednav_provider_comm_id"], name: "index_ipa_mednav_provider_comm_history_on_ipa_mednav_provider_c"
    t.index ["master_id"], name: "index_ipa_mednav_provider_comm_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_mednav_provider_comm_history_on_user_id"
  end

  create_table "ipa_mednav_provider_comms", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_mednav_provider_comms_on_master_id"
    t.index ["user_id"], name: "index_ipa_mednav_provider_comms_on_user_id"
  end

  create_table "ipa_mednav_provider_report_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "report_delivery_date"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_mednav_provider_report_id"
    t.index ["ipa_mednav_provider_report_id"], name: "index_ipa_mednav_provider_report_history_on_ipa_mednav_provider"
    t.index ["master_id"], name: "index_ipa_mednav_provider_report_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_mednav_provider_report_history_on_user_id"
  end

  create_table "ipa_mednav_provider_reports", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "report_delivery_date"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_mednav_provider_reports_on_master_id"
    t.index ["user_id"], name: "index_ipa_mednav_provider_reports_on_user_id"
  end

  create_table "ipa_payment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_type"
    t.date "sent_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_payment_id"
    t.index ["ipa_payment_id"], name: "index_ipa_payment_history_on_ipa_payment_id"
    t.index ["master_id"], name: "index_ipa_payment_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_payment_history_on_user_id"
  end

  create_table "ipa_payments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_type"
    t.date "sent_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_payments_on_master_id"
    t.index ["user_id"], name: "index_ipa_payments_on_user_id"
  end

  create_table "ipa_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_protocol_deviation_id"
    t.index ["ipa_protocol_deviation_id"], name: "index_ipa_protocol_deviation_history_on_ipa_protocol_deviation_"
    t.index ["master_id"], name: "index_ipa_protocol_deviation_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_protocol_deviation_history_on_user_id"
  end

  create_table "ipa_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_protocol_deviations_on_master_id"
    t.index ["user_id"], name: "index_ipa_protocol_deviations_on_user_id"
  end

  create_table "ipa_protocol_exception_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_protocol_exception_id"
    t.index ["ipa_protocol_exception_id"], name: "index_ipa_protocol_exception_history_on_ipa_protocol_exception_"
    t.index ["master_id"], name: "index_ipa_protocol_exception_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_protocol_exception_history_on_user_id"
  end

  create_table "ipa_protocol_exceptions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_protocol_exceptions_on_master_id"
    t.index ["user_id"], name: "index_ipa_protocol_exceptions_on_user_id"
  end

  create_table "ipa_ps_comp_review_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "how_long_notes"
    t.string "clinical_care_or_research_notes"
    t.string "two_assessments_notes"
    t.string "risks_notes"
    t.string "study_drugs_notes"
    t.string "compensation_notes"
    t.string "location_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_comp_review_id"
    t.index ["ipa_ps_comp_review_id"], name: "index_ipa_ps_comp_review_history_on_ipa_ps_comp_review_id"
    t.index ["master_id"], name: "index_ipa_ps_comp_review_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_comp_review_history_on_user_id"
  end

  create_table "ipa_ps_comp_reviews", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "how_long_notes"
    t.string "clinical_care_or_research_notes"
    t.string "two_assessments_notes"
    t.string "risks_notes"
    t.string "study_drugs_notes"
    t.string "compensation_notes"
    t.string "location_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_ps_comp_reviews_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_comp_reviews_on_user_id"
  end

  create_table "ipa_ps_covid_closing_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "contact_later_yes_no"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ipa_ps_covid_closing_id"
    t.index ["ipa_ps_covid_closing_id"], name: "be7e93a6_id_idx"
    t.index ["master_id"], name: "be7e93a6_history_master_id"
    t.index ["user_id"], name: "be7e93a6_user_idx"
  end

  create_table "ipa_ps_covid_closings", force: :cascade do |t|
    t.bigint "master_id"
    t.string "contact_later_yes_no"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_ops.ipa_ps_covid_closings_on_master_id"
    t.index ["user_id"], name: "index_ipa_ops.ipa_ps_covid_closings_on_user_id"
  end

  create_table "ipa_ps_football_experience_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "age"
    t.string "played_in_nfl_blank_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_football_experience_id"
    t.index ["ipa_ps_football_experience_id"], name: "index_ipa_ps_football_experience_history_on_ipa_ps_football_exp"
    t.index ["master_id"], name: "index_ipa_ps_football_experience_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_football_experience_history_on_user_id"
  end

  create_table "ipa_ps_football_experiences", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "age"
    t.string "played_in_nfl_blank_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_ps_football_experiences_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_football_experiences_on_user_id"
  end

  create_table "ipa_ps_health_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "physical_limitations_blank_yes_no"
    t.string "physical_limitations_details"
    t.string "sit_back_blank_yes_no"
    t.string "sit_back_details"
    t.string "cycle_blank_yes_no"
    t.string "cycle_details"
    t.string "chronic_pain_blank_yes_no"
    t.string "chronic_pain_details"
    t.string "chronic_pain_meds_blank_yes_no_dont_know"
    t.string "chronic_pain_meds_details"
    t.string "hemophilia_blank_yes_no_dont_know"
    t.string "hemophilia_details"
    t.string "raynauds_syndrome_blank_yes_no_dont_know"
    t.string "raynauds_syndrome_severity_selection"
    t.string "raynauds_syndrome_details"
    t.string "hypertension_diagnosis_blank_yes_no_dont_know"
    t.string "hypertension_diagnosis_details"
    t.string "other_heart_conditions_blank_yes_no_dont_know"
    t.string "other_heart_conditions_details"
    t.string "memory_problems_blank_yes_no_dont_know"
    t.string "memory_problems_details"
    t.string "mental_health_conditions_blank_yes_no_dont_know"
    t.string "mental_health_conditions_details"
    t.string "neurological_problems_blank_yes_no_dont_know"
    t.string "neurological_problems_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_health_id"
    t.string "diabetes_diagnosis_blank_yes_no_dont_know"
    t.string "diabetes_diagnosis_details"
    t.string "high_cholesterol_diagnosis_blank_yes_no_dont_know"
    t.string "high_cholesterol_diagnosis_details"
    t.string "heart_surgeries_blank_yes_no_dont_know"
    t.string "heart_surgeries_details"
    t.string "caridiac_pacemaker_blank_yes_no_dont_know"
    t.string "caridiac_pacemaker_details"
    t.string "mental_health_help_blank_yes_no_dont_know"
    t.string "mental_health_help_details"
    t.string "neurological_surgeries_blank_yes_no_dont_know"
    t.string "neurological_surgeries_details"
    t.string "hypertension_medications_blank_yes_no"
    t.string "diabetes_medications_blank_yes_no"
    t.string "high_cholesterol_medications_blank_yes_no"
    t.index ["ipa_ps_health_id"], name: "index_ipa_ps_health_history_on_ipa_ps_health_id"
    t.index ["master_id"], name: "index_ipa_ps_health_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_health_history_on_user_id"
  end

  create_table "ipa_ps_healths", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "physical_limitations_blank_yes_no"
    t.string "physical_limitations_details"
    t.string "sit_back_blank_yes_no"
    t.string "sit_back_details"
    t.string "cycle_blank_yes_no"
    t.string "cycle_details"
    t.string "chronic_pain_blank_yes_no"
    t.string "chronic_pain_details"
    t.string "chronic_pain_meds_blank_yes_no_dont_know"
    t.string "chronic_pain_meds_details"
    t.string "hemophilia_blank_yes_no_dont_know"
    t.string "hemophilia_details"
    t.string "raynauds_syndrome_blank_yes_no_dont_know"
    t.string "raynauds_syndrome_severity_selection"
    t.string "raynauds_syndrome_details"
    t.string "hypertension_diagnosis_blank_yes_no_dont_know"
    t.string "hypertension_diagnosis_details"
    t.string "other_heart_conditions_blank_yes_no_dont_know"
    t.string "other_heart_conditions_details"
    t.string "memory_problems_blank_yes_no_dont_know"
    t.string "memory_problems_details"
    t.string "mental_health_conditions_blank_yes_no_dont_know"
    t.string "mental_health_conditions_details"
    t.string "neurological_problems_blank_yes_no_dont_know"
    t.string "neurological_problems_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "diabetes_diagnosis_blank_yes_no_dont_know"
    t.string "diabetes_diagnosis_details"
    t.string "high_cholesterol_diagnosis_blank_yes_no_dont_know"
    t.string "high_cholesterol_diagnosis_details"
    t.string "heart_surgeries_blank_yes_no_dont_know"
    t.string "heart_surgeries_details"
    t.string "caridiac_pacemaker_blank_yes_no_dont_know"
    t.string "caridiac_pacemaker_details"
    t.string "mental_health_help_blank_yes_no_dont_know"
    t.string "mental_health_help_details"
    t.string "neurological_surgeries_blank_yes_no_dont_know"
    t.string "neurological_surgeries_details"
    t.string "hypertension_medications_blank_yes_no"
    t.string "diabetes_medications_blank_yes_no"
    t.string "high_cholesterol_medications_blank_yes_no"
    t.index ["master_id"], name: "index_ipa_ps_healths_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_healths_on_user_id"
  end

  create_table "ipa_ps_informant_detail_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "last_name"
    t.string "relationship_to_participant"
    t.string "contact_information_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_informant_detail_id"
    t.string "first_name"
    t.string "email"
    t.string "phone"
    t.index ["ipa_ps_informant_detail_id"], name: "index_ipa_ps_informant_detail_history_on_ipa_ps_informant_detai"
    t.index ["master_id"], name: "index_ipa_ps_informant_detail_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_informant_detail_history_on_user_id"
  end

  create_table "ipa_ps_informant_details", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "last_name"
    t.string "relationship_to_participant"
    t.string "contact_information_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "email"
    t.string "phone"
    t.index ["master_id"], name: "index_ipa_ps_informant_details_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_informant_details_on_user_id"
  end

  create_table "ipa_ps_initial_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_initial_screening_id"
    t.string "looked_at_website_yes_no"
    t.string "select_still_interested"
    t.string "form_version"
    t.string "same_hotel_yes_no"
    t.string "select_schedule"
    t.index ["ipa_ps_initial_screening_id"], name: "index_ipa_ps_initial_screening_history_on_ipa_ps_initial_screen"
    t.index ["master_id"], name: "index_ipa_ps_initial_screening_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_initial_screening_history_on_user_id"
  end

  create_table "ipa_ps_initial_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "any_questions_blank_yes_no"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notes"
    t.string "looked_at_website_yes_no"
    t.string "select_still_interested"
    t.string "form_version"
    t.string "same_hotel_yes_no"
    t.string "embedded_report_ipa__ipa_appointments"
    t.string "select_schedule"
    t.string "select_may_i_begin"
    t.index ["master_id"], name: "index_ipa_ps_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_initial_screenings_on_user_id"
  end

  create_table "ipa_ps_mri_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "electrical_implants_blank_yes_no_dont_know"
    t.string "electrical_implants_details"
    t.string "metal_implants_blank_yes_no_dont_know"
    t.string "metal_implants_details"
    t.string "metal_jewelry_blank_yes_no"
    t.string "hearing_aid_blank_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_mri_id"
    t.string "past_mri_yes_no_dont_know"
    t.string "past_mri_details"
    t.string "radiation_blank_yes_no"
    t.string "radiation_details"
    t.string "form_version"
    t.string "select_radiation_type"
    t.index ["ipa_ps_mri_id"], name: "index_ipa_ps_mri_history_on_ipa_ps_mri_id"
    t.index ["master_id"], name: "index_ipa_ps_mri_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_mri_history_on_user_id"
  end

  create_table "ipa_ps_mris", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "electrical_implants_blank_yes_no_dont_know"
    t.string "electrical_implants_details"
    t.string "metal_implants_blank_yes_no_dont_know"
    t.string "metal_implants_details"
    t.string "metal_jewelry_blank_yes_no"
    t.string "hearing_aid_blank_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "past_mri_yes_no_dont_know"
    t.string "past_mri_details"
    t.string "radiation_blank_yes_no"
    t.string "radiation_details"
    t.string "form_version"
    t.string "select_radiation_type"
    t.index ["master_id"], name: "index_ipa_ps_mris_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_mris_on_user_id"
  end

  create_table "ipa_ps_size_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "weight"
    t.string "height"
    t.string "hat_size"
    t.string "shirt_size"
    t.string "jacket_size"
    t.string "waist_size"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_size_id"
    t.date "birth_date"
    t.index ["ipa_ps_size_id"], name: "index_ipa_ps_size_history_on_ipa_ps_size_id"
    t.index ["master_id"], name: "index_ipa_ps_size_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_size_history_on_user_id"
  end

  create_table "ipa_ps_sizes", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "weight"
    t.string "height"
    t.string "hat_size"
    t.string "shirt_size"
    t.string "jacket_size"
    t.string "waist_size"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "birth_date"
    t.index ["master_id"], name: "index_ipa_ps_sizes_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_sizes_on_user_id"
  end

  create_table "ipa_ps_sleep_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "sleep_disorder_blank_yes_no_dont_know"
    t.string "sleep_disorder_details"
    t.string "sleep_apnea_device_no_yes"
    t.string "sleep_apnea_device_details"
    t.string "bed_and_wake_time_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_sleep_id"
    t.string "form_version"
    t.integer "number_of_nights_sleep_apnea_device"
    t.string "sleep_apnea_travel_with_device_yes_no"
    t.string "sleep_apnea_bring_device_yes_no"
    t.index ["ipa_ps_sleep_id"], name: "index_ipa_ps_sleep_history_on_ipa_ps_sleep_id"
    t.index ["master_id"], name: "index_ipa_ps_sleep_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_sleep_history_on_user_id"
  end

  create_table "ipa_ps_sleeps", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "sleep_disorder_blank_yes_no_dont_know"
    t.string "sleep_disorder_details"
    t.string "sleep_apnea_device_no_yes"
    t.string "sleep_apnea_device_details"
    t.string "bed_and_wake_time_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "form_version"
    t.integer "number_of_nights_sleep_apnea_device"
    t.string "sleep_apnea_travel_with_device_yes_no"
    t.string "sleep_apnea_bring_device_yes_no"
    t.index ["master_id"], name: "index_ipa_ps_sleeps_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_sleeps_on_user_id"
  end

  create_table "ipa_ps_tmoca_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tmoca_score"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_tmoca_id"
    t.integer "attn_digit_span"
    t.integer "attn_digit_vigilance"
    t.integer "attn_digit_calculation"
    t.integer "language_repeat"
    t.integer "language_fluency"
    t.integer "abstraction"
    t.integer "delayed_recall"
    t.integer "orientation"
    t.string "tmoca_version"
    t.index ["ipa_ps_tmoca_id"], name: "index_ipa_ps_tmoca_history_on_ipa_ps_tmoca_id"
    t.index ["master_id"], name: "index_ipa_ps_tmoca_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_tmoca_history_on_user_id"
  end

  create_table "ipa_ps_tmocas", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "tmoca_score"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attn_digit_span"
    t.integer "attn_digit_vigilance"
    t.integer "attn_digit_calculation"
    t.integer "language_repeat"
    t.integer "language_fluency"
    t.integer "abstraction"
    t.integer "delayed_recall"
    t.integer "orientation"
    t.string "tmoca_version"
    t.index ["master_id"], name: "index_ipa_ps_tmocas_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_tmocas_on_user_id"
  end

  create_table "ipa_ps_tms_test_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "convulsion_or_seizure_blank_yes_no_dont_know"
    t.string "epilepsy_blank_yes_no_dont_know"
    t.string "fainting_blank_yes_no_dont_know"
    t.string "concussion_blank_yes_no_dont_know"
    t.string "hearing_problems_blank_yes_no_dont_know"
    t.string "cochlear_implants_blank_yes_no_dont_know"
    t.string "metal_blank_yes_no_dont_know"
    t.string "metal_details"
    t.string "neurostimulator_blank_yes_no_dont_know"
    t.string "neurostimulator_details"
    t.string "med_infusion_device_blank_yes_no_dont_know"
    t.string "past_tms_blank_yes_no_dont_know"
    t.string "past_tms_details"
    t.string "current_meds_blank_yes_no_dont_know"
    t.string "current_meds_details"
    t.string "other_chronic_problems_blank_yes_no_dont_know"
    t.string "other_chronic_problems_details"
    t.string "hospital_visits_blank_yes_no_dont_know"
    t.string "hospital_visits_details"
    t.string "dietary_restrictions_blank_yes_no_dont_know"
    t.string "dietary_restrictions_details"
    t.string "anything_else_blank_yes_no"
    t.string "anything_else_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_ps_tms_test_id"
    t.string "loss_of_conciousness_details"
    t.string "med_infusion_device_details"
    t.string "convulsion_or_seizure_details"
    t.string "epilepsy_details"
    t.string "fainting_details"
    t.string "hairstyle_scalp_blank_yes_no_dont_know"
    t.string "hairstyle_scalp_details"
    t.string "form_version"
    t.string "tobacco_smoker_blank_yes_no"
    t.string "tobacco_smoker_details"
    t.string "healthcare_anxiety_blank_yes_no"
    t.string "healthcare_anxiety_details"
    t.string "covid19_test_consent_yes_no"
    t.string "covid19_concerns_yes_no"
    t.string "covid19_concerns_notes"
    t.string "wear_mask_yes_no"
    t.index ["ipa_ps_tms_test_id"], name: "index_ipa_ps_tms_test_history_on_ipa_ps_tms_test_id"
    t.index ["master_id"], name: "index_ipa_ps_tms_test_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_tms_test_history_on_user_id"
  end

  create_table "ipa_ps_tms_tests", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "convulsion_or_seizure_blank_yes_no_dont_know"
    t.string "epilepsy_blank_yes_no_dont_know"
    t.string "fainting_blank_yes_no_dont_know"
    t.string "concussion_blank_yes_no_dont_know"
    t.string "hearing_problems_blank_yes_no_dont_know"
    t.string "cochlear_implants_blank_yes_no_dont_know"
    t.string "metal_blank_yes_no_dont_know"
    t.string "metal_details"
    t.string "neurostimulator_blank_yes_no_dont_know"
    t.string "neurostimulator_details"
    t.string "med_infusion_device_blank_yes_no_dont_know"
    t.string "past_tms_blank_yes_no_dont_know"
    t.string "past_tms_details"
    t.string "current_meds_blank_yes_no_dont_know"
    t.string "current_meds_details"
    t.string "other_chronic_problems_blank_yes_no_dont_know"
    t.string "other_chronic_problems_details"
    t.string "hospital_visits_blank_yes_no_dont_know"
    t.string "hospital_visits_details"
    t.string "dietary_restrictions_blank_yes_no_dont_know"
    t.string "dietary_restrictions_details"
    t.string "anything_else_blank_yes_no"
    t.string "anything_else_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "loss_of_conciousness_details"
    t.string "med_infusion_device_details"
    t.string "convulsion_or_seizure_details"
    t.string "epilepsy_details"
    t.string "fainting_details"
    t.string "hairstyle_scalp_blank_yes_no_dont_know"
    t.string "hairstyle_scalp_details"
    t.string "form_version"
    t.string "tobacco_smoker_blank_yes_no"
    t.string "tobacco_smoker_details"
    t.string "healthcare_anxiety_blank_yes_no"
    t.string "healthcare_anxiety_details"
    t.string "covid19_test_consent_yes_no"
    t.string "covid19_concerns_yes_no"
    t.string "covid19_concerns_notes"
    t.string "wear_mask_yes_no"
    t.index ["master_id"], name: "index_ipa_ps_tms_tests_on_master_id"
    t.index ["user_id"], name: "index_ipa_ps_tms_tests_on_user_id"
  end

  create_table "ipa_recruitment_ranks", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "master_id"
    t.integer "rank"
    t.boolean "ml_app_age_eligible_for_ipa"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ipa_reimbursement_req_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "participant_requested_yes_no"
    t.date "submission_date"
    t.string "additional_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_reimbursement_req_id"
    t.index ["ipa_reimbursement_req_id"], name: "index_ipa_reimbursement_req_history_on_ipa_reimbursement_req_id"
    t.index ["master_id"], name: "index_ipa_reimbursement_req_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_reimbursement_req_history_on_user_id"
  end

  create_table "ipa_reimbursement_reqs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "participant_requested_yes_no"
    t.date "submission_date"
    t.string "additional_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_reimbursement_reqs_on_master_id"
    t.index ["user_id"], name: "index_ipa_reimbursement_reqs_on_user_id"
  end

  create_table "ipa_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_screening_id"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.time "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "requires_study_partner_blank_yes_no"
    t.string "contact_in_future_yes_no"
    t.string "form_version"
    t.index ["ipa_screening_id"], name: "index_ipa_screening_history_on_ipa_screening_id"
    t.index ["master_id"], name: "index_ipa_screening_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_screening_history_on_user_id"
  end

  create_table "ipa_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.time "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "requires_study_partner_blank_yes_no"
    t.string "contact_in_future_yes_no"
    t.string "form_version"
    t.index ["master_id"], name: "index_ipa_screenings_on_master_id"
    t.index ["user_id"], name: "index_ipa_screenings_on_user_id"
  end

  create_table "ipa_special_consideration_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "travel_with_wife_yes_no"
    t.string "travel_with_wife_details"
    t.string "mmse_yes_no"
    t.string "tmoca_score"
    t.string "bringing_cpap_yes_no"
    t.string "tms_exempt_yes_no"
    t.string "taking_med_for_mri_pet_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_special_consideration_id"
    t.string "mmse_details"
    t.string "same_hotel_yes_no"
    t.index ["ipa_special_consideration_id"], name: "index_ipa_special_consideration_history_on_ipa_special_consider"
    t.index ["master_id"], name: "index_ipa_special_consideration_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_special_consideration_history_on_user_id"
  end

  create_table "ipa_special_considerations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "travel_with_wife_yes_no"
    t.string "travel_with_wife_details"
    t.string "mmse_yes_no"
    t.string "tmoca_score"
    t.string "bringing_cpap_yes_no"
    t.string "tms_exempt_yes_no"
    t.string "taking_med_for_mri_pet_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mmse_details"
    t.string "same_hotel_yes_no"
    t.index ["master_id"], name: "index_ipa_special_considerations_on_master_id"
    t.index ["user_id"], name: "index_ipa_special_considerations_on_user_id"
  end

  create_table "ipa_station_contact_history", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "select_availability"
    t.string "phone"
    t.string "alt_phone"
    t.string "email"
    t.string "alt_email"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_station_contact_id"
    t.index ["ipa_station_contact_id"], name: "index_ipa_station_contact_history_on_ipa_station_contact_id"
    t.index ["user_id"], name: "index_ipa_station_contact_history_on_user_id"
  end

  create_table "ipa_station_contacts", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "select_availability"
    t.string "phone"
    t.string "alt_phone"
    t.string "email"
    t.string "alt_email"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_ipa_station_contacts_on_user_id"
  end

  create_table "ipa_survey_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_survey_type"
    t.date "sent_date"
    t.date "completed_date"
    t.date "send_next_survey_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_survey_id"
    t.index ["ipa_survey_id"], name: "index_ipa_survey_history_on_ipa_survey_id"
    t.index ["master_id"], name: "index_ipa_survey_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_survey_history_on_user_id"
  end

  create_table "ipa_surveys", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_survey_type"
    t.date "sent_date"
    t.date "completed_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_surveys_on_master_id"
    t.index ["user_id"], name: "index_ipa_surveys_on_user_id"
  end

  create_table "ipa_transportation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "travel_date"
    t.string "travel_confirmed_no_yes"
    t.string "select_direction"
    t.string "origin_city_and_state"
    t.string "destination_city_and_state"
    t.string "select_mode_of_transport"
    t.string "airline"
    t.string "flight_number"
    t.string "departure_time"
    t.string "arrival_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_transportation_id"
    t.index ["ipa_transportation_id"], name: "index_ipa_transportation_history_on_ipa_transportation_id"
    t.index ["master_id"], name: "index_ipa_transportation_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_transportation_history_on_user_id"
  end

  create_table "ipa_transportations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "travel_date"
    t.string "travel_confirmed_no_yes"
    t.string "select_direction"
    t.string "origin_city_and_state"
    t.string "destination_city_and_state"
    t.string "select_mode_of_transport"
    t.string "airline"
    t.string "flight_number"
    t.string "departure_time"
    t.string "arrival_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_transportations_on_master_id"
    t.index ["user_id"], name: "index_ipa_transportations_on_user_id"
  end

  create_table "ipa_two_wk_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "participant_had_qs_yes_no"
    t.string "participant_qs_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_two_wk_followup_id"
    t.index ["ipa_two_wk_followup_id"], name: "index_ipa_two_wk_followup_history_on_ipa_two_wk_followup_id"
    t.index ["master_id"], name: "index_ipa_two_wk_followup_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_two_wk_followup_history_on_user_id"
  end

  create_table "ipa_two_wk_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "participant_had_qs_yes_no"
    t.string "participant_qs_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_two_wk_followups_on_master_id"
    t.index ["user_id"], name: "index_ipa_two_wk_followups_on_user_id"
  end

  create_table "ipa_withdrawal_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ipa_withdrawal_id"
    t.index ["ipa_withdrawal_id"], name: "index_ipa_withdrawal_history_on_ipa_withdrawal_id"
    t.index ["master_id"], name: "index_ipa_withdrawal_history_on_master_id"
    t.index ["user_id"], name: "index_ipa_withdrawal_history_on_user_id"
  end

  create_table "ipa_withdrawals", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_ipa_withdrawals_on_master_id"
    t.index ["user_id"], name: "index_ipa_withdrawals_on_user_id"
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
    t.integer "item_flag_name_id"
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

  create_table "marketo_ids", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "email"
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

  create_table "ml_copy", id: false, force: :cascade do |t|
    t.integer "procontactid"
    t.string "fill_in_addresses", limit: 255
    t.string "in_survey", limit: 255
    t.string "verify_survey_participation", limit: 255
    t.string "verify_player_and_or_match", limit: 255
    t.string "accuracy", limit: 255
    t.string "accuracy_score", limit: 255
    t.integer "contactid"
    t.integer "pro_id"
    t.text "separator_a"
    t.string "first_name", limit: 255
    t.string "middle_name", limit: 255
    t.string "last_name", limit: 255
    t.string "nick_name", limit: 255
    t.text "separator_b"
    t.string "pro_first_name", limit: 255
    t.string "pro_middle_name", limit: 255
    t.string "pro_last_name", limit: 255
    t.string "pro_nick_name", limit: 255
    t.string "birthdate", limit: 255
    t.string "pro_dob", limit: 255
    t.string "pro_dod", limit: 255
    t.string "startyear", limit: 255
    t.string "pro_start_year", limit: 255
    t.integer "accruedseasons"
    t.string "pro_end_year", limit: 255
    t.string "first_contract", limit: 255
    t.string "second_contract", limit: 255
    t.string "third_contract", limit: 255
    t.string "pro_career_info", limit: 255
    t.string "pro_birthplace", limit: 255
    t.string "pro_college", limit: 255
    t.string "email", limit: 255
    t.string "homecity", limit: 255
    t.string "homestate", limit: 50
    t.string "homezipcode", limit: 10
    t.string "homestreet", limit: 255
    t.string "homestreet2", limit: 255
    t.string "homestreet3", limit: 255
    t.string "businesscity", limit: 255
    t.string "businessstate", limit: 50
    t.string "businesszipcode", limit: 10
    t.string "businessstreet", limit: 255
    t.string "businessstreet2", limit: 255
    t.string "businessstreet3", limit: 255
    t.integer "changed"
    t.string "changed_column", limit: 255
    t.integer "verified"
    t.text "notes"
    t.string "email2", limit: 255
    t.string "email3", limit: 255
    t.string "updatehomestreet", limit: 255
    t.string "updatehomestreet2", limit: 255
    t.string "updatehomecity", limit: 255
    t.string "updatehomestate", limit: 50
    t.string "updatehomezipcode", limit: 10
    t.string "lastmod", limit: 255
    t.string "sourc", limit: 255
    t.string "changed_by", limit: 255
    t.integer "msid"
    t.string "mailing", limit: 255
    t.string "outreach_vfy", limit: 255
    t.text "lastupdate"
    t.text "lastupdateby"
    t.string "cprefs", limit: 255
    t.integer "scantronid"
    t.text "insertauditkey"
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

  create_table "mrn_number_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mrn_number_table_id"
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
  end

  create_table "mrn_number_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mrn_number_table_id"
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
  end

  create_table "mrn_number_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mrn_number_table_id"
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
  end

  create_table "mrn_number_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mrn_number_table_id"
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_number_history_on_admin_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["master_id"], name: "index_mrn_number_history_on_master_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["mrn_number_table_id"], name: "index_mrn_number_history_on_mrn_number_table_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
    t.index ["user_id"], name: "index_mrn_number_history_on_user_id"
  end

  create_table "mrn_numbers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
  end

  create_table "mrn_numbers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
  end

  create_table "mrn_numbers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
  end

  create_table "mrn_numbers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "mrn_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_organization"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["admin_id"], name: "index_mrn_numbers_on_admin_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["master_id"], name: "index_mrn_numbers_on_master_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
    t.index ["user_id"], name: "index_mrn_numbers_on_user_id"
  end

  create_table "msm_grit_id_number_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "msm_grit_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "msm_grit_id_number_table_id"
    t.index ["admin_id"], name: "index_msm_grit_id_number_history_on_admin_id"
    t.index ["master_id"], name: "index_msm_grit_id_number_history_on_master_id"
    t.index ["msm_grit_id_number_table_id"], name: "index_msm_grit_id_number_history_on_msm_grit_id_number_table_id"
    t.index ["user_id"], name: "index_msm_grit_id_number_history_on_user_id"
  end

  create_table "msm_grit_id_numbers", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "msm_grit_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_msm_grit_id_numbers_on_admin_id"
    t.index ["master_id"], name: "index_msm_grit_id_numbers_on_master_id"
    t.index ["user_id"], name: "index_msm_grit_id_numbers_on_user_id"
  end

  create_table "new_test_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "new_test_ext_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "new_test_table_id"
    t.index ["admin_id"], name: "index_new_test_history_on_admin_id"
    t.index ["master_id"], name: "index_new_test_history_on_master_id"
    t.index ["new_test_table_id"], name: "index_new_test_history_on_new_test_table_id"
    t.index ["user_id"], name: "index_new_test_history_on_user_id"
  end

  create_table "new_tests", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "new_test_ext_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_new_tests_on_admin_id"
    t.index ["master_id"], name: "index_new_tests_on_master_id"
    t.index ["user_id"], name: "index_new_tests_on_user_id"
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
    t.index ["nfs_store_archived_file_id"], name: "index_nfs_store_archived_file_history_on_nfs_store_archived_fil"
    t.index ["user_id"], name: "index_nfs_store_archived_file_history_on_user_id"
    t.index ["user_id"], name: "index_nfs_store_archived_file_history_on_user_id"
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
    t.index ["nfs_store_archived_file_id"], name: "index_nfs_store_archived_file_history_on_nfs_store_archived_fil"
    t.index ["user_id"], name: "index_nfs_store_archived_file_history_on_user_id"
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
    t.index ["master_id"], name: "index_nfs_store_container_history_on_master_id"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_container_history_on_nfs_store_container_id"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_container_history_on_nfs_store_container_id"
    t.index ["user_id"], name: "index_nfs_store_container_history_on_user_id"
    t.index ["user_id"], name: "index_nfs_store_container_history_on_user_id"
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
    t.index ["master_id"], name: "index_nfs_store_container_history_on_master_id"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_container_history_on_nfs_store_container_id"
    t.index ["nfs_store_container_id"], name: "index_nfs_store_container_history_on_nfs_store_container_id"
    t.index ["user_id"], name: "index_nfs_store_container_history_on_user_id"
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
    t.index ["nfs_store_stored_file_id"], name: "index_nfs_store_stored_file_history_on_nfs_store_stored_file_id"
    t.index ["user_id"], name: "index_nfs_store_stored_file_history_on_user_id"
    t.index ["user_id"], name: "index_nfs_store_stored_file_history_on_user_id"
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
    t.index ["nfs_store_stored_file_id"], name: "index_nfs_store_stored_file_history_on_nfs_store_stored_file_id"
    t.index ["user_id"], name: "index_nfs_store_stored_file_history_on_user_id"
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

  create_table "persnet_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "persnet_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "persnet_assignment_table_id"
    t.index ["admin_id"], name: "index_persnet_assignment_history_on_admin_id"
    t.index ["master_id"], name: "index_persnet_assignment_history_on_master_id"
    t.index ["persnet_assignment_table_id"], name: "index_persnet_assignment_history_on_persnet_assignment_table_id"
    t.index ["user_id"], name: "index_persnet_assignment_history_on_user_id"
  end

  create_table "persnet_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "persnet_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_persnet_assignments_on_admin_id"
    t.index ["master_id"], name: "index_persnet_assignments_on_master_id"
    t.index ["user_id"], name: "index_persnet_assignments_on_user_id"
  end

  create_table "pitt_bhi_access_pi_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_access_pi_id"
    t.index ["master_id"], name: "6bfd97eb_history_master_id"
    t.index ["pitt_bhi_access_pi_id"], name: "6bfd97eb_id_idx"
    t.index ["user_id"], name: "6bfd97eb_user_idx"
  end

  create_table "pitt_bhi_access_pis", comment: "A record referencing a master record indicates PITT BHI PI has access to this participant", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_access_pis_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_access_pis_on_user_id"
  end

  create_table "pitt_bhi_access_pitt_staff_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_access_pitt_staff_id"
    t.index ["master_id"], name: "362cdefc_history_master_id"
    t.index ["pitt_bhi_access_pitt_staff_id"], name: "362cdefc_id_idx"
    t.index ["user_id"], name: "362cdefc_user_idx"
  end

  create_table "pitt_bhi_access_pitt_staffs", comment: "A record referencing a master record indicates PITT BHI staff have access to this participant", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_access_pitt_staffs_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_access_pitt_staffs_on_user_id"
  end

  create_table "pitt_bhi_appointment_history", force: :cascade do |t|
    t.bigint "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "select_status"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_appointment_id"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_appointment_history_on_master_id"
    t.index ["pitt_bhi_appointment_id"], name: "pitt_bhi_appointment_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_appointment_history_on_user_id"
  end

  create_table "pitt_bhi_appointments", comment: "PITT BHI study participation dates and status", force: :cascade do |t|
    t.bigint "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "select_status"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_appointments_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_appointments_on_user_id"
  end

  create_table "pitt_bhi_assignment_history", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_id"
    t.bigint "user_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_assignment_table_id"
    t.index ["admin_id"], name: "index_pitt_bhi.pitt_bhi_assignment_history_on_admin_id"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_assignment_history_on_master_id"
    t.index ["pitt_bhi_assignment_table_id"], name: "pitt_bhi_assignment_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_assignment_history_on_user_id"
  end

  create_table "pitt_bhi_assignments", force: :cascade do |t|
    t.bigint "master_id"
    t.bigint "pitt_bhi_id"
    t.bigint "user_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_pitt_bhi.pitt_bhi_assignments_on_admin_id"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_assignments_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_assignments_on_user_id"
  end

  create_table "pitt_bhi_ps_eligibility_followup_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "outcome"
    t.string "any_questions_yes_no"
    t.string "notes"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "select_still_interested"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_ps_eligibility_followup_id"
    t.index ["master_id"], name: "271fb131_history_master_id"
    t.index ["pitt_bhi_ps_eligibility_followup_id"], name: "271fb131_id_idx"
    t.index ["user_id"], name: "271fb131_user_idx"
  end

  create_table "pitt_bhi_ps_eligibility_followups", force: :cascade do |t|
    t.bigint "master_id"
    t.string "outcome"
    t.string "any_questions_yes_no"
    t.string "notes"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "consent_to_pass_info_to_msm_yes_no"
    t.string "consent_to_pass_info_to_msm_2_yes_no"
    t.string "contact_info_notes"
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "select_still_interested"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_ps_eligibility_followups_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_eligibility_followups_on_user_id"
  end

  create_table "pitt_bhi_ps_eligible_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "contact_info_notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_ps_eligible_id"
    t.string "consent_to_pass_info_to_pitt_yes_no"
    t.string "consent_to_pass_info_to_pitt_2_yes_no"
    t.string "not_interested_notes"
    t.index ["master_id"], name: "pitt_bhi_ps_eligible_h_m_id"
    t.index ["pitt_bhi_ps_eligible_id"], name: "pitt_bhi_ps_eligible_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_eligible_history_on_user_id"
  end

  create_table "pitt_bhi_ps_eligibles", force: :cascade do |t|
    t.bigint "master_id"
    t.string "contact_info_notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "consent_to_pass_info_to_pitt_yes_no"
    t.string "consent_to_pass_info_to_pitt_2_yes_no"
    t.string "not_interested_notes"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_ps_eligibles_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_eligibles_on_user_id"
  end

  create_table "pitt_bhi_ps_initial_screening_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "more_questions_yes_no"
    t.string "more_questions_notes"
    t.string "still_interested_2_yes_no"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_ps_initial_screening_id"
    t.index ["master_id"], name: "pitt_bhi_ps_initial_screening_h_m_id"
    t.index ["pitt_bhi_ps_initial_screening_id"], name: "pitt_bhi_ps_initial_screening_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_initial_screening_history_on_user_id"
  end

  create_table "pitt_bhi_ps_initial_screenings", force: :cascade do |t|
    t.bigint "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "question_notes"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_ps_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_initial_screenings_on_user_id"
  end

  create_table "pitt_bhi_ps_non_eligible_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_ps_non_eligible_id"
    t.index ["master_id"], name: "pitt_bhi_ps_non_eligible_h_m_id"
    t.index ["pitt_bhi_ps_non_eligible_id"], name: "pitt_bhi_ps_non_eligible_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_non_eligible_history_on_user_id"
  end

  create_table "pitt_bhi_ps_non_eligibles", force: :cascade do |t|
    t.bigint "master_id"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_ps_non_eligibles_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_non_eligibles_on_user_id"
  end

  create_table "pitt_bhi_ps_screener_response_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "comm_clearly_in_english_yes_no"
    t.string "give_informed_consent_yes_no_dont_know"
    t.string "give_informed_consent_notes"
    t.string "outcome"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_ps_screener_response_id"
    t.index ["master_id"], name: "31f4f0d0_history_master_id"
    t.index ["pitt_bhi_ps_screener_response_id"], name: "31f4f0d0_id_idx"
    t.index ["user_id"], name: "31f4f0d0_user_idx"
  end

  create_table "pitt_bhi_ps_screener_responses", force: :cascade do |t|
    t.bigint "master_id"
    t.string "comm_clearly_in_english_yes_no"
    t.string "give_informed_consent_yes_no_dont_know"
    t.string "give_informed_consent_notes"
    t.string "outcome"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_ps_screener_responses_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_screener_responses_on_user_id"
  end

  create_table "pitt_bhi_ps_suitability_question_history", force: :cascade do |t|
    t.bigint "master_id"
    t.date "birth_date"
    t.string "eligible_pension_yes_no"
    t.string "any_questions_yes_no"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_ps_suitability_question_id"
    t.integer "age"
    t.index ["master_id"], name: "history_master_id"
    t.index ["pitt_bhi_ps_suitability_question_id"], name: "id_idx"
    t.index ["user_id"], name: "user_idx"
  end

  create_table "pitt_bhi_ps_suitability_questions", comment: "Suitability assessment form for BHI phone screening, recording responses from subject\n", force: :cascade do |t|
    t.bigint "master_id"
    t.date "birth_date", comment: "Date of birth"
    t.string "eligible_pension_yes_no", comment: "Eligible for a pension from the NFL\n(At least 3 seasons with 3 games per season)\n"
    t.string "notes", comment: "Question and notes recorded by interviewer"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "age", comment: "Calculated age at the time the response was saved"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_ps_suitability_questions_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_ps_suitability_questions_on_user_id"
  end

  create_table "pitt_bhi_screening_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "good_time_to_speak_blank_yes_no"
    t.string "still_interested_blank_yes_no"
    t.date "callback_date"
    t.time "callback_time"
    t.string "consent_performed_yes_no"
    t.string "did_subject_consent_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_screening_id"
    t.index ["master_id"], name: "pitt_bhi_screening_h_m_id"
    t.index ["pitt_bhi_screening_id"], name: "pitt_bhi_screening_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_screening_history_on_user_id"
  end

  create_table "pitt_bhi_screenings", force: :cascade do |t|
    t.bigint "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "good_time_to_speak_blank_yes_no"
    t.string "still_interested_blank_yes_no"
    t.date "callback_date"
    t.time "callback_time"
    t.string "consent_performed_yes_no"
    t.string "did_subject_consent_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_screenings_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_screenings_on_user_id"
  end

  create_table "pitt_bhi_secure_note_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_secure_note_id"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_secure_note_history_on_master_id"
    t.index ["pitt_bhi_secure_note_id"], name: "pitt_bhi_secure_note_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_secure_note_history_on_user_id"
  end

  create_table "pitt_bhi_secure_notes", force: :cascade do |t|
    t.bigint "master_id"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_secure_notes_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_secure_notes_on_user_id"
  end

  create_table "pitt_bhi_withdrawal_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pitt_bhi_withdrawal_id"
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_withdrawal_history_on_master_id"
    t.index ["pitt_bhi_withdrawal_id"], name: "pitt_bhi_withdrawal_id_idx"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_withdrawal_history_on_user_id"
  end

  create_table "pitt_bhi_withdrawals", force: :cascade do |t|
    t.bigint "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_pitt_bhi.pitt_bhi_withdrawals_on_master_id"
    t.index ["user_id"], name: "index_pitt_bhi.pitt_bhi_withdrawals_on_user_id"
  end

  create_table "player_career_data", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_player_career_data_on_master_id"
    t.index ["user_id"], name: "index_player_career_data_on_user_id"
  end

  create_table "player_career_data_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "player_career_data_id"
    t.index ["master_id"], name: "index_player_career_data_history_on_master_id"
    t.index ["player_career_data_id"], name: "index_player_career_data_history_on_player_career_data_id"
    t.index ["user_id"], name: "index_player_career_data_history_on_user_id"
  end

  create_table "player_contact_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "source"
    t.integer "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: "2017-09-25 15:43:36"
    t.integer "player_contact_id"
    t.index ["master_id"], name: "index_player_contact_history_on_master_id"
    t.index ["player_contact_id"], name: "index_player_contact_history_on_player_contact_id"
    t.index ["user_id"], name: "index_player_contact_history_on_user_id"
  end

  create_table "player_contact_phone_info_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "player_contact_id"
    t.string "carrier"
    t.string "city"
    t.string "cleansed_phone_number_e164"
    t.string "cleansed_phone_number_national"
    t.string "country"
    t.string "country_code_iso_2"
    t.string "country_code_numeric"
    t.string "county"
    t.string "original_country_code_iso_2"
    t.integer "original_phone_number"
    t.string "phone_type"
    t.string "phone_type_code"
    t.string "timezone"
    t.string "zip_code"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "player_contact_phone_info_id"
    t.datetime "opted_out_at"
    t.index ["master_id"], name: "index_player_contact_phone_info_history_on_master_id"
    t.index ["player_contact_phone_info_id"], name: "index_player_contact_phone_info_history_on_player_contact_phone"
    t.index ["user_id"], name: "index_player_contact_phone_info_history_on_user_id"
  end

  create_table "player_contact_phone_infos", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "player_contact_id"
    t.string "carrier"
    t.string "city"
    t.string "cleansed_phone_number_e164"
    t.string "cleansed_phone_number_national"
    t.string "country"
    t.string "country_code_iso_2"
    t.string "country_code_numeric"
    t.string "county"
    t.string "original_country_code_iso_2"
    t.integer "original_phone_number"
    t.string "phone_type"
    t.string "phone_type_code"
    t.string "timezone"
    t.string "zip_code"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "opted_out_at"
    t.index ["master_id"], name: "index_player_contact_phone_infos_on_master_id"
    t.index ["user_id"], name: "index_player_contact_phone_infos_on_user_id"
  end

  create_table "player_contacts", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "rec_type"
    t.string "data"
    t.string "source"
    t.integer "rank"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: "2017-09-25 15:43:36"
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
    t.datetime "updated_at", default: "2017-09-25 15:43:36"
    t.string "contact_pref"
    t.integer "start_year"
    t.integer "rank"
    t.string "notes"
    t.integer "contact_id"
    t.string "college"
    t.integer "end_year"
    t.string "source"
    t.integer "player_info_id"
    t.integer "other_count"
    t.string "other_type"
    t.index ["master_id"], name: "index_player_info_history_on_master_id"
    t.index ["player_info_id"], name: "index_player_info_history_on_player_info_id"
    t.index ["user_id"], name: "index_player_info_history_on_user_id"
  end

  create_table "player_infos", id: :serial, comment: "Player biographical information", force: :cascade do |t|
    t.integer "master_id"
    t.string "first_name", comment: "First Name"
    t.string "last_name"
    t.string "middle_name"
    t.string "nick_name"
    t.date "birth_date"
    t.date "death_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: "2017-09-25 15:43:37"
    t.string "contact_pref"
    t.integer "start_year"
    t.integer "rank"
    t.string "notes"
    t.integer "contact_id"
    t.string "college"
    t.integer "end_year"
    t.string "source"
    t.integer "other_count"
    t.string "other_type"
    t.index ["master_id"], name: "index_player_infos_on_master_id"
    t.index ["user_id"], name: "index_player_infos_on_user_id"
  end

  create_table "player_severance", id: false, force: :cascade do |t|
    t.integer "contactid"
    t.date "payoutdate"
    t.string "infochangestatus", limit: 255
  end

  create_table "player_transactions", id: false, force: :cascade do |t|
    t.integer "contactid"
    t.date "transactiondate"
    t.string "transactiontype", limit: 255
    t.string "transactionstatus", limit: 255
    t.string "transactionsubstatus", limit: 255
    t.string "transactionhistoricalteamname", limit: 255
    t.string "transactioncurrentteamname", limit: 255
    t.string "infochangestatus", limit: 255
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
    t.datetime "updated_at", default: "2017-09-25 15:43:37"
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

  create_table "q1_datadic", id: :integer, default: -> { "nextval('q1datadic_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "variable_name"
    t.text "domain"
    t.text "field_type_rc"
    t.text "field_type_sa"
    t.text "field_label"
    t.text "field_attributes"
    t.text "field_note"
    t.text "text_valid_type"
    t.text "text_valid_min"
    t.text "text_valid_max"
    t.text "required_field"
    t.text "field_attr_array", array: true
    t.text "source"
    t.text "owner"
    t.text "classification"
    t.text "display"
  end

  create_table "q2_data", id: :serial, force: :cascade do |t|
    t.integer "record_id", comment: "Hidden on survey;\nSequential ID assinged by REDCap "
    t.decimal "redcap_survey_identifier", comment: "Hidden on survey; \nFPHS assigned study identification number"
    t.datetime "q2_timestamp", comment: "Hidden on survey:\nDate and time full Q2 survey was completed"
    t.date "dob", comment: "Date of birth:"
    t.decimal "current_weight", comment: "What is your current weight?"
    t.integer "domestic_status", comment: "What is your current marital status?"
    t.integer "living_situation", comment: "How would you describe your current living situation?"
    t.integer "current_employment", comment: "Are you currently employed?"
    t.integer "student_looking", comment: "If you are unemployed, are you currently a student or looking for work?"
    t.integer "current_fbjob", comment: "If you work in football, please provide additional information:"
    t.text "current_fbjob_oth", comment: "If Other, please specify:"
    t.text "job_industry", comment: "Specify your employment industry. (If you are retired, specify the last industry in which you were employed.)"
    t.integer "job_title", comment: "Select the option that best represents your job title. \n(If you are retired, indicate the title of your last job)"
    t.text "job_title_entry", comment: "Enter your job title:\n(If you are retired, enter the title of your last job)"
    t.integer "smoke", comment: "Have you ever smoked cigarettes?_x000D_\n(Smoked at least 100 cigarettes in your lifetime. Do not include pipe and cigars)"
    t.integer "smoketime___pnfl", comment: "Please indicate the time-frames during which you smoked cigarettes?_x000D_\n(Please select all that apply)\n[Before playing in the NFL]"
    t.integer "smoketime___dnfl", comment: "Please indicate the time-frames during which you smoked cigarettes?_x000D_\n(Please select all that apply)\n[While playing in the NFL]"
    t.integer "smoketime___anfl", comment: "Please indicate the time-frames during which you smoked cigarettes?_x000D_\n(Please select all that apply)\n[After playing in the NFL]"
    t.decimal "smoke_start", comment: "How old were you when you started smoking?\n"
    t.decimal "smoke_stop", comment: "How old were you when you stopped smoking?"
    t.integer "smoke_curr", comment: "On average, how many cigarettes do you currently smoke per day?"
    t.decimal "smoke_totyrs", comment: "How many years, in total, have you smoked? (if you quit more than once, estimate the total years you considered yourself an active smoker)"
    t.integer "smoke_prenfl", comment: "How many cigarettes did you smoke per day, on average, before playing in the NFL?"
    t.integer "smoke_nfl", comment: "How many cigarettes did you smoke per day, on average, while playing in the NFL?"
    t.integer "smoke_postnfl", comment: "How many cigarettes have you smoked per day, on average, since leaving the NFL? \n(If you have quit smoking, please provide the average number of cigarettes \nsmoked per day while you considered yourself an active (...)"
    t.integer "edu_player", comment: "Please provide the highest level of education attained by you, your mother, and your father:\n[You (respondent)]"
    t.integer "edu_mother", comment: "Please provide the highest level of education attained by you, your mother, and your father:\n[Mother]"
    t.integer "edu_father", comment: "Please provide the highest level of education attained by you, your mother, and your father:\n[Father]"
    t.integer "occ_mother", comment: "What kind of work did your parents do when you were a child?\n[Mother]"
    t.text "occ_mother_exp", comment: "What kind of work did your parents do when you were a child?\nPlease explain:\n[Mother occupation if Other]"
    t.integer "occ_father", comment: "What kind of work did your parents do when you were a child?\n[Father]"
    t.text "occ_father_exp", comment: "What kind of work did your parents do when you were a child?\nPlease explain:\n[Father occupation if Other]"
    t.decimal "yrsplayed_prehs", comment: "How many years did you play football before starting high school?"
    t.integer "playhsfb___no", comment: "I did not play high school football:\n(Check this box if you did not play organized football during high school)"
    t.integer "hsposition1", comment: "Please indicate the main position(s) you played during high school football\nPrimary position #1:"
    t.integer "hsposition2", comment: "Please indicate the main position(s) you played during high school football\nPrimary position #2:"
    t.integer "yrsplayed_hs", comment: "How many years did you play football during high school?"
    t.integer "collposition1", comment: "Please indicate the main positions you played during college football\nPrimary position #1:"
    t.integer "collposition2", comment: "Please indicate the main positions you played during college football\nPrimary position #2:"
    t.integer "yrsplayed_coll", comment: "How many years did you play football during college before going pro?"
    t.integer "college_div", comment: "If you played after the college division system was created, which division did you play in?"
    t.integer "collpreprac", comment: "College Playing History: Training Camp and Regular Season Practice\nDuring your college football career, on average, how often did you practice per week during pre-season?"
    t.integer "collpreprac_pads", comment: "College Playing History: Training Camp and Regular Season Practice\nDuring your college football career, on average, how many practices a week did you wear full pads or shoulder pads during pre-season?"
    t.integer "collregprac", comment: "College Playing History: Training Camp and Regular Season Practice\nDuring your college football career, on average, how often did you practice per week during the regular season?"
    t.integer "collregprac_pads", comment: "College Playing History: Training Camp and Regular Season Practice\nDuring your college football career, on average, how many practices a week did you wear full pads or shoulder pads during the regular seaso (...)"
    t.integer "collsnap_ol", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Offensive line]"
    t.integer "collsnap_wr", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Wide receiver]"
    t.integer "collsnap_dl", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Defensive line]"
    t.integer "collsnap_te", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Tight end]"
    t.integer "collsnap_lb", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Linebacker]"
    t.integer "collsnap_qb", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Quarterback]"
    t.integer "collsnap_db", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Defensive back]"
    t.integer "collsnap_kick", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Kicker/punter]"
    t.integer "collsnap_rb", comment: "During your college football career, on average, how many snaps did you play per game for the following positions?\n[Running back]"
    t.integer "collsnap_special", comment: "During your college football career, on average, how many snaps did you play per game on special teams?  If you are unsure, please take your best guess.\n[Special teams]"
    t.integer "nflpreprac", comment: "NFL Playing History: Pre-Season and Regular Season Practice\nOver your NFL career, on average, how often did you practice per week during pre-season?"
    t.integer "nflpreprac_pads", comment: "NFL Playing History: Pre-Season and Regular Season Practice\nOver your NFL career, on average, how many practices a week did you wear full pads or shoulder pads during pre-season?"
    t.integer "nflregprac", comment: "NFL Playing History: Pre-Season and Regular Season Practice\nOver your NFL career, on average, how often did you practice per week during the regular season?"
    t.integer "nflregprac_pads", comment: "NFL Playing History: Pre-Season and Regular Season Practice\nOver your NFL career, on average, how many practices a week did you wear full pads or shoulder pads during the regular season?"
    t.integer "prosnap_ol", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Offensive line]"
    t.integer "prosnap_wr", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Wide receiver]"
    t.integer "prosnap_dl", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Defensive line]"
    t.integer "prosnap_te", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Tight end]"
    t.integer "prosnap_lb", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Linebacker]"
    t.integer "prosnap_qb", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Quarterback]"
    t.integer "prosnap_db", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Defensive back]"
    t.integer "prosnap_kick", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Kicker/punter]"
    t.integer "prosnap_rb", comment: "Over your whole professional football career, on average, how many snaps did you play per game for the following positions? \n[Running back]"
    t.integer "prosnap_special", comment: "Over your whole professional football career, on average, how many snaps did you play per game on special teams? If you are unsure, please take your best guess.\n[Special teams]"
    t.decimal "gmsplyd_career", comment: "Over your whole professional football career, approximately how many games were you on an active roster?"
    t.integer "gmsplyd_season", comment: "Over your whole professional football career, on average, how many games were you on an active roster per season?"
    t.integer "prsqd", comment: "Did you ever spend time on a practice squad for an NFL team?"
    t.decimal "prsqd_seasons", comment: "Number of seasons:\n[Spent on a practice squad for an NFL team]"
    t.integer "othleague", comment: "Did you play any seasons for a professional team that was not in the NFL? (CFL, EFL, etc.)_x000D_"
    t.integer "othleague_seasons", comment: "How many seasons did you play for a professional team not in the NFL? (CFL, EFL, etc.)"
    t.integer "othleaguenm___afl", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[Arena Football League (AFL)]"
    t.integer "othleaguenm___cfl", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[Canadian Football League (CFL)]"
    t.integer "othleaguenm___efl", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[European Football League (EFL)]"
    t.integer "othleaguenm___ufl", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[United Football League (UFL)]"
    t.integer "othleaguenm___wfl", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[World Football League (WFL)]"
    t.integer "othleaguenm___xfl", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[XFL]"
    t.integer "othleaguenm___oth", comment: "Indicate the professional, non-NFL, league(s) for which you have played. Please mark all that apply:\n[Other]"
    t.text "othleague_exp", comment: "If Other, please explain:"
    t.decimal "nonnfl_seasons", comment: "How many seasons did you collectively play that were not in the NFL?"
    t.integer "prsqd_nonnfl", comment: "Did you ever spend time on a practice squad for another professional non-NFL Team?"
    t.decimal "prsqd_nonnfl_seasons", comment: "Non-NFL Practice Squad:\n[Seasons spent on practice squad for another professional non-NFL team]"
    t.decimal "firstpro_age", comment: "How old were you when you played your first professional football game (NFL, CFL, EFL, etc.)?"
    t.decimal "finalpro_age", comment: "How old were you when you played your final professional football game (NFL, CFL, EFL, etc.)?"
    t.integer "leftfb___age", comment: "Please indicate the main reason(s) why you stopped playing professional football? Select all that apply.\n[Age]"
    t.integer "leftfb___cut", comment: "Please indicate the main reason(s) why you stopped playing professional football? Select all that apply.\n[Cut]"
    t.integer "leftfb___fbinj", comment: "Please indicate the main reason(s) why you stopped playing professional football? Select all that apply.\n[Injury or health problem related to football]"
    t.integer "leftfb___inj", comment: "Please indicate the main reason(s) why you stopped playing professional football? Select all that apply.\n[Injury or health problem not related to football]"
    t.integer "leftfb___retire", comment: "Please indicate the main reason(s) why you stopped playing professional football? Select all that apply.\n[Personal decision (retired)]"
    t.integer "postfb_hlthprac", comment: "How soon after you stopped playing professional football did you...\n...First see a healthcare practitioner?"
    t.integer "postfb_degree", comment: "How soon after you stopped playing professional football did you...\n...Go back to school to complete a degree or obtain an advanced degree?"
    t.integer "postfb_charity", comment: "How soon after you stopped playing professional football did you...\n... Begin participating in volunteer or charity work?"
    t.integer "postfb_fbjob", comment: "How soon after you stopped playing professional football did you...\n... Become employed in a football related activity?(e.g. coach, scout, administration, media, television, reporting etc.)"
    t.integer "postfb_job", comment: "How soon after you stopped playing professional football did you...\n... Become employed in a non-football related activity?"
    t.integer "postfbjob_occ", comment: "What was your first job after leaving football?_x000D_\nPlease provide the job title:"
    t.text "postfbjob_occexp", comment: "Please explain:\n[If post-football job is Other]"
    t.integer "postfbex_walk", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Walking for exercise or walking to wor (...)"
    t.integer "postfbex_jog", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Jogging(slower than 10min/mile)]"
    t.integer "postfbex_run", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Running(10min/mile or faster)]"
    t.integer "postfbex_other", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Other aerobic exercise(e.g. bicycling (...)"
    t.integer "postfbex_lowint", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Low intensity exercise(e.g. yoga, pi (...)"
    t.integer "postfbex_wttrain", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Weight training(e.g. lifting free w (...)"
    t.integer "postfbex_endsprt", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Competitive endurance sports(e.g. m (...)"
    t.integer "postfbex_reclg", comment: "In the first 12 months after you no longer considered yourself a potentially active player, what was the average number of hours spent each week on the activities below?\n[Recreational team leagues(e.g. soccer (...)"
    t.integer "pastyrex_walk", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Walking for exercise or walking to work]"
    t.integer "pastyrex_jog", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Jogging(slower than 10min/mile)]"
    t.integer "pastyrex_run", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Running(10min/mile or faster)]"
    t.integer "pastyrex_oth", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Other aerobic exercise (e.g. bicycling, stationary bike, elliptical machine, stairmaster)]"
    t.integer "pastyrex_lowint", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Low intensity exercise (e.g. yoga, pilates, stretching)]"
    t.integer "pastyrex_wttrain", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Weight training (e.g. lifting free weights, using weight machines)]"
    t.integer "pastyrex_endsprt", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Competitive endurance sports (e.g. marathon, triathlon)]"
    t.integer "pastyrex_reclg", comment: "For the past year, what was the average number of hours spent each week on each activity below?\n[Recreational team leagues(e.g. soccer, basketball, flag football, volleyball)]"
    t.integer "ex150min", comment: "Do you do 2.5 hours or more of moderate intensity aerobic activity per week? \n(e.g. brisk walking, jogging, cycling, etc.)."
    t.integer "ex150min_exp", comment: "Please select the reason that best explains why you do not do at least 2.5 hours of  moderate intensity aerobic activity per week:"
    t.text "ex150min_oth", comment: "If other, please explain:\n[Other reason for not performing at least 2.5 hours of moderate intensity aerobic activity/week]"
    t.integer "demog___complete", comment: "Have you completed all questions that you intend to answer on this page? \nOnce you have advanced to the next section, you will not be able to return."
    t.datetime "demog_date", comment: "Hidden on survey,\nDate and time that the domain of Q2 survey was completed"
    t.integer "postfb_wt2yr", comment: "Had you gained or lost weight:\n2 years after leaving professional football play?"
    t.integer "postfb_wt2yrdelta", comment: "Had you gained or lost weight:\n2 years after leaving professional football play?\n[Change in weight] - pounds"
    t.integer "postfb_wt5yr", comment: "Had you gained or lost weight:\n5 years after leaving professional football play?"
    t.integer "postfb_wt5yrdelta", comment: "Had you gained or lost weight:\n5 years after leaving professional football play?\n[Change in weight] - pounds"
    t.integer "cardiac_rehab", comment: "In the last 4 years or since filling out the First Health and Wellness Questionnaire (Q1)...\nHave you participated in cardiac rehabtherapy based on a health care providers recommendation?"
    t.integer "cvtest_ecg", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\n12 lead ECG (electrocardiogram)"
    t.text "cvtest_ecg_exp", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\n12 lead ECG (electrocardiogram)\nPlease specify the diagnosis, if known:"
    t.integer "cvtest_echo", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nHeart ultrasound (echocardiogram)"
    t.text "cvtest_echo_exp", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nHeart ultrasound (echocardiogram)\nPlease specify the diagnosis, if known:"
    t.integer "cvtest_cpxt", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nExercise stress test"
    t.text "cvtest_cpxt_exp", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nExercise stress test\nPlease specify the diagnosis, if known:"
    t.integer "cvtest_cvmri", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nCardiac MRI"
    t.text "cvtest_cvmri_exp", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nCardiac MRI\nPlease specify the diagnosis, if known:"
    t.integer "cvtest_corct", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nCoronary artery CT scan"
    t.text "cvtest_corct_exp", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nCoronary artery CT scan\nPlease specify the diagnosis, if known:"
    t.integer "cvtest_cvcath", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nCardiac catheterization (coronary angiogram)"
    t.text "cvtest_cvcath_exp", comment: "In the last 4 years or since filling out Q1, have you had any of the following cardiovascular tests?\nCardiac catheterization (coronary angiogram)\nPlease specify the diagnosis, if known:"
    t.integer "cvdx_mi", comment: "Since January 1, 2015 has a healthcare provider told you that you have had any of the following?\nHeart attack"
    t.integer "cvdx_stroke", comment: "Since January 1, 2015 has a healthcare provider told you that you have had any of the following?\nStroke (CVA)"
    t.integer "cvdx_tia", comment: "Since January 1, 2015 has a healthcare provider told you that you have had any of the following?\nTIA (Transient ischemicattack/mini-stroke)"
    t.integer "cvmedrec_highbp", comment: "Since January 1, 2015 has a healthcare provider recommended or prescribed medicine for any of the following conditions?\nHigh blood pressure"
    t.integer "cvmedrec_hrtfail", comment: "Since January 1, 2015 has a healthcare provider recommended or prescribed medicine for any of the following conditions?\nHeart failure"
    t.integer "cvmedrec_afib", comment: "Since January 1, 2015 has a healthcare provider recommended or prescribed medicine for any of the following conditions?\nAtrial fibrillation"
    t.integer "cvmedrec_otharrhyth", comment: "Since January 1, 2015 has a healthcare provider recommended or prescribed medicine for any of the following conditions?\nOther arrhythmias (e.g. SVT)"
    t.integer "cvmedrec_highchol", comment: "Since January 1, 2015 has a healthcare provider recommended or prescribed medicine for any of the following conditions?\nHigh cholesterol"
    t.integer "cvmedrec_diabetes", comment: "Since January 1, 2015 has a healthcare provider recommended or prescribed medicine for any of the following conditions?\nDiabetes or high blood sugar"
    t.integer "cvsurg_bypass", comment: "Since January 1, 2015 have you had any of the following surgical procedures?\nHeart bypass, angioplasty, or stent placement"
    t.integer "cvsurg_ablation", comment: "Since January 1, 2015 have you had any of the following surgical procedures?\nAblation for atrial fibrillation"
    t.integer "cvsurg_carotidart", comment: "Since January 1, 2015 have you had any of the following surgical procedures?\nCarotid artery surgery"
    t.integer "cvmed_chol", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nStatin cholesterol lowering drugs[e.g. Mervacor (lovastatin), Pravachol (pravastatin), Xocor (simvastatin), Lipitor]"
    t.integer "cvmed_othchol", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nOther cholesterol-lowering drugs[e.g. Niaspan, Slo-Niacin (niacin), Lopid (gemfibrozil), Tricor (fenofibrate), Questran (c (...)"
    t.integer "cvmed_novchol", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nNovel cholesterol lowering drugs(PCSK-9 inhibitors) [e.g. Repatha (evolocumab), Praluent (alirocumab)]"
    t.integer "cvmed_bldthin", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nNon-aspirin blood thinners [e.g. Coumadin (warfarin)]"
    t.integer "cvmed_anticoag", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nNovel oral anti-coagulant [e.g. Eliquis (apixaban), Pradaxa(dabigatran), Xarelto (rivaroxaban)]"
    t.integer "cvmed_arrhyth", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nAnti-arrhythmia drugs foratrial fibrillation [e.g. beta blockers (Sectral, Tenormin), sotalol (Betapace, Sotylize, Sorine) (...)"
    t.integer "cvmed_digoxin", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nDigoxin [e.g. Lenoxin]"
    t.integer "cvmed_furosemide", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nFurosemide-like diuretic drug[e.g. Lasix, Bumex]"
    t.integer "cvmed_thiazide", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nThiazide diuretic[e.g. HCTZ, Microzide]"
    t.integer "cvmed_calciumblk", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nCalcium blocker[e.g. Calan (verapamil), Procardia(nifedipine), Cardizem (diltiazem)]"
    t.integer "cvmed_antihyp", comment: "Are you currently taking any of the following medications?\nCardiovascular Medications\nOther antihypertensive[e.g. Vasotec (enalapril), Capoten (captopril)]"
    t.integer "dbmed_metformin", comment: "Are you currently taking any of the following medications?\nDiabetes Medications\nMetformin [e.g.  Glumetza, Glucophage, Fortamet]"
    t.integer "dbmed_glimeperide", comment: "Are you currently taking any of the following medications?\nDiabetes Medications\nGlimeperide"
    t.integer "dbmed_insulin", comment: "Are you currently taking any of the following medications?\nDiabetes Medications\nInsulin"
    t.integer "dbmed_other", comment: "Are you currently taking any of the following medications?\nDiabetes Medications\nOther diabetes medication"
    t.integer "cardiac___complete", comment: "Have you completed all questions that you intend to answer on this page? \nOnce you have advanced to the next section, you will not be able to return."
    t.datetime "cardiac_date", comment: "Hidden on survey;\nDate and time that the domain of Q2 survey was completed"
    t.integer "ad8_1", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember,\n Yes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_2", comment: "Over the last several years, have you experienced worsening thinking and memory problems? \nRemember, Yes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_3", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember, \nYes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_4", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember, \nYes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_5", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember, \nYes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_6", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember, \nYes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_7", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember, \nYes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "ad8_8", comment: "Over the last several years, have you experienced worsening thinking and memory problems? Remember, \nYes, a change indicates that there has been a change for the worse in the last several years caused by cognitive (t (...)"
    t.integer "nqcog64q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. \nIn the past 7 days... \nI had to read something several times to understand it."
    t.integer "nqcog65q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nI had trouble keeping track of what I was doing if I was interrupted."
    t.integer "nqcog66q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nI had difficulty doing more than one thing at a time."
    t.integer "nqcog68q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nI had trouble remembering new information, like phone numbers or simple instructions."
    t.integer "nqcog72q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nI had trouble thinking clearly."
    t.integer "nqcog75q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nMy thinking was slow."
    t.integer "nqcog77q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nI had to work really hard to pay attention or I would make a mistake."
    t.integer "nqcog80q2", comment: "Please mark the response below which best describes your thinking, memory, and concentration. In the past 7 days... \nI had trouble concentrating."
    t.integer "nqper02", comment: "In the past 7 days... \nI had trouble controlling my temper."
    t.integer "nqper05", comment: "In the past 7 days... \nIt was hard to control my behavior."
    t.integer "nqper06", comment: "In the past 7 days... \nI said or did things without thinking."
    t.integer "nqper07", comment: "In the past 7 days... \nI got impatient with other people."
    t.integer "nqper11", comment: "In the past 7 days... \nI was irritable around other people."
    t.integer "nqper12", comment: "In the past 7 days... \nI was bothered by little things."
    t.integer "nqper17", comment: "In the past 7 days... \nI became easily upset."
    t.integer "nqper19", comment: "In the past 7 days... \nI was in conflict with others."
    t.integer "phq1", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nLittle interest or pleasure in doing things."
    t.integer "phq2", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nFeeling down, depressed, or hopeless."
    t.integer "phq3", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nTrouble falling or staying asleep, or sleeping too much."
    t.integer "phq4", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nFeeling tired or having little energy."
    t.integer "phq5", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nPoor appetite or overeating."
    t.integer "phq6", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nFeeling bad about yourself - or that you are a failure or have let yourself or your family down."
    t.integer "phq7", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nTrouble concentrating on things, such as reading the newspaper or watching television."
    t.integer "phq8", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nMoving or speaking so slowly that other people could have noticed. Or the opposite - being so fidgety or restless that you have  (...)"
    t.integer "phq9", comment: "Over the last 2 weeks, how often have you been bothered by any of the following problems?\nThoughts that you would be better off dead or of hurting yourself.\n(Please know that this survey is not a way to get help if yo (...)"
    t.integer "gad7_1", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nFeeling nervous, anxious or on edge."
    t.integer "gad7_2", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nNot being able to stop or control worrying."
    t.integer "gad7_3", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nWorrying too much about different things."
    t.integer "gad7_4", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nTrouble relaxing."
    t.integer "gad7_5", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nBeing so restless that it is hard to sit still."
    t.integer "gad7_6", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nBecoming easily annoyed or irritable."
    t.integer "gad7_7", comment: "Over the last 2 weeks, how often have you been bothered by the following problems? \nFeeling afraid as if something awful might happen."
    t.integer "lotr1", comment: "For the next 7 questions, please be as honest and accurate as you can throughout.\n Try not to let your response to one statement influence your responses to other statements. There are no correct or incorrect answe (...)"
    t.integer "lotr3", comment: "For the next 7 questions, please be as honest and accurate as you can throughout. \nTry not to let your response to one statement influence your responses to other statements. There are no correct or incorrect answe (...)"
    t.integer "lotr4", comment: "For the next 7 questions, please be as honest and accurate as you can throughout. \nTry not to let your response to one statement influence your responses to other statements. There are no correct or incorrect answe (...)"
    t.integer "lotr7", comment: "For the next 7 questions, please be as honest and accurate as you can throughout. \nTry not to let your response to one statement influence your responses to other statements. There are no correct or incorrect answe (...)"
    t.integer "lotr9", comment: "For the next 7 questions, please be as honest and accurate as you can throughout. \nTry not to let your response to one statement influence your responses to other statements. There are no correct or incorrect answe (...)"
    t.integer "lotr10", comment: "For the next 7 questions, please be as honest and accurate as you can throughout. \nTry not to let your response to one statement influence your responses to other statements. There are no correct or incorrect answ (...)"
    t.integer "stpbng_snore", comment: "To the best of your knowledge... \nDo you SNORE loudly (loud enough to be heard through closed doors or your bed-partner elbows you for snoring at night)?"
    t.integer "stpbng_tired", comment: "To the best of your knowledge... \nDo you often feel TIRED, fatigued, or sleepy during the daytime? (such as falling asleep during driving or talking to someone)?"
    t.integer "stpbng_obser", comment: "To the best of your knowledge... \nHas anyone observed you stop breathing or choking/gasping during your sleep?"
    t.integer "stpbng_bp", comment: "To the best of your knowledge... \nDo you have or are you being treated for high blood pressure?"
    t.integer "stpbng_neck", comment: "To the best of your knowledge... \nWhat is your neck circumference (your collarsize when buying a dress shirt)?"
    t.integer "cpapuse", comment: "Do you currently use a CPAP device for sleep apnea?"
    t.integer "cpapuse_days", comment: "About how many days per week do you use your CPAP device?"
    t.integer "ncmedrec_hdache", comment: "Since January 1, 2015 has a medical provider recommended or prescribed medicine for any of the following conditions?\nHeadaches"
    t.integer "ncmedrec_anx", comment: "Since January 1, 2015 has a medical provider recommended or prescribed medicine for any of the following conditions?\nAnxiety"
    t.integer "ncmedrec_dep", comment: "Since January 1, 2015 has a medical provider recommended or prescribed medicine for any of the following conditions?\nDepression"
    t.integer "ncmedrec_memloss", comment: "Since January 1, 2015 has a medical provider recommended or prescribed medicine for any of the following conditions?\nMemory loss"
    t.integer "ncmedrec_add", comment: "Since January 1, 2015 has a medical provider recommended or prescribed medicine for any of the following conditions?\nADD/ADHD"
    t.integer "ncdx_alz", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nAlzheimers disease"
    t.integer "ncdx_cte", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nChronic traumatic encephalopathy (CTE)"
    t.integer "ncdx_vascdem", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nVascular dementia"
    t.integer "ncdx_othdem", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nOther dementia"
    t.integer "ncdx_als", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nAmyotrophic lateral sclerosis(ALS, Lou Gehrigs disease)"
    t.integer "ncdx_parkins", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nParkinsons disease"
    t.integer "ncdx_ms", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nMultiple sclerosis (MS)"
    t.integer "ncmed_ssri", comment: "Are you currently using any of the following medications?\nProzac, Zoloft, Paxil, Celexa"
    t.integer "ncmed_tricydep", comment: "Are you currently using any of the following medications?\nTricyclic antidepressant [e.g. Elavil, Sinequan]"
    t.integer "ncmed_othdep", comment: "Are you currently using any of the following medications?\nOther antidepressant [e.g. Nardil, Marplan]"
    t.integer "ncmed_slpaid", comment: "Are you currently using any of the following medications?\nSleep aid"
    t.integer "neurocog___complete", comment: "Have you completed all questions that you intend to answer on this page? \nOnce you have advanced to the next section, you will not be able to return."
    t.datetime "neurocog_date", comment: "Hidden on survey,\nDate and time that the Neurocognitive Health domain of Q2 survey was completed"
    t.integer "bpi1", comment: "Throughout our lives, most of us have had pain from time to time (such as minor headaches, sprains, and toothaches).\nHave you had pain other than these everyday kinds of pain today?"
    t.integer "bpi2___head", comment: "Please indicate the areas where you feel pain. (Select all that apply)Head"
    t.integer "bpi2___neck", comment: "Please indicate the areas where you feel pain. (Select all that apply)Neck"
    t.integer "bpi2___shoul", comment: "Please indicate the areas where you feel pain. (Select all that apply) Shoulder"
    t.integer "bpi2___chest", comment: "Please indicate the areas where you feel pain. (Select all that apply) Chest"
    t.integer "bpi2___arm", comment: "Please indicate the areas where you feel pain. (Select all that apply) Arm"
    t.integer "bpi2___hand", comment: "Please indicate the areas where you feel pain. (Select all that apply) Hand"
    t.integer "bpi2___uback", comment: "Please indicate the areas where you feel pain. (Select all that apply) Upper back"
    t.integer "bpi2___lbak", comment: "Please indicate the areas where you feel pain. (Select all that apply) Lower back"
    t.integer "bpi2___hip", comment: "Please indicate the areas where you feel pain. (Select all that apply) Hip"
    t.integer "bpi2___leg", comment: "Please indicate the areas where you feel pain. (Select all that apply) Leg"
    t.integer "bpi2___knee", comment: "Please indicate the areas where you feel pain. (Select all that apply) Knee"
    t.integer "bpi2___ankle", comment: "Please indicate the areas where you feel pain. (Select all that apply)\nAnkle"
    t.integer "bpi2___foot", comment: "Please indicate the areas where you feel pain. (Select all that apply) Foot"
    t.integer "bpi2___oth", comment: "Please indicate the areas where you feel pain. (Select all that apply) Other"
    t.text "bpi2_othexp", comment: "Please indicate the areas where you feel pain. (Select all that apply)\nIf you selected Other, please explain:"
    t.integer "bpi2most", comment: "Please indicate the area where you feel the most pain."
    t.text "bpi2most_othexp", comment: "Please indicate the area where you feel the most pain.\nIf you selected Other, please explain:"
    t.integer "bpi3", comment: "Please rate your pain by marking the box beside the number that best describes your pain at its worst in the last 24 hours."
    t.integer "bpi4", comment: "Please rate your pain by marking the box beside the number that best describes your pain at its least in the last 24 hours."
    t.integer "bpi5", comment: "Please rate your pain by marking the box beside the number that best describes your pain on the average."
    t.integer "bpi6", comment: "Please rate your pain by marking the box beside the number that tells how much pain you have right now."
    t.integer "bpi7___none", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply)\nNone"
    t.integer "bpi7___otc", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply)\nOver the counter medication"
    t.integer "bpi7___prmed", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply) Prescribed medication"
    t.integer "bpi7___mass", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply) Massage/acupressure"
    t.integer "bpi7___pt", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply) Physical therapy"
    t.integer "bpi7___acup", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply) Acupuncture"
    t.integer "bpi7___marij", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply) Marijuana or medical marijuana"
    t.integer "bpi7___intpm", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply) Interventional pain management (nerve blocks, joint injections or radiotherapy)"
    t.integer "bpi7___oth", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply)\nOther"
    t.text "bpi7_othexp", comment: "What treatments or medications are you receiving for your pain? (Please select all that apply)\nIf you selected Other, please explain:"
    t.integer "bpi8", comment: "In the last 24 hours, how much relief have pain treatments or medications provided? Please mark the box below the percentage that most shows how much relief you have received."
    t.integer "bpi9a", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nGeneral activity"
    t.integer "bpi9b", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nMood"
    t.integer "bpi9c", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nWalking ability"
    t.integer "bpi9d", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nNormal work (includes both work outside the home and housework)"
    t.integer "bpi9e", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nRelations with other people"
    t.integer "bpi9f", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nSleep"
    t.integer "bpi9g", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nEnjoyment of life"
    t.integer "bpi9h", comment: "Mark the box beside the number that describes how, during the past 24 hours, pain has interfered with your:\nExercise for health and wellness"
    t.integer "pnmedfb_acetamin", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nDuring active professional play\nAcetaminophen[e.g. Tylenol]"
    t.integer "pnmedfb_aspirin", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nDuring active professional play\nAspirin or aspirin containing products[e.g. Excedrin Migraine, Alka-Se (...)"
    t.integer "pnmedfb_ibuprof", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nDuring active professional play\nIbuprofen [e.g. Motrin, Advil]"
    t.integer "pnmedfb_othantiinf", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nDuring active professional play\nOther anti-inflammatory analgesics[e.g. Aleve, Naprosyn, Relafen,Fr (...)"
    t.integer "pnmedfb_oralster", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nDuring active professional play\nSteroid taken orally[e.g. Prednisone, Medrol]"
    t.integer "pnmedfb_opioid", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nDuring active professional play\nOpioid-based pain medication [e.g. Percocet, Vicodin]"
    t.integer "pnmed5yr_acetamin", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nWithin 5 years after active professional play\nAcetaminophen[e.g. Tylenol]"
    t.integer "pnmed5yr_aspirin", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nWithin 5 years after active professional play\nAspirin or aspirin containing products[e.g. Excedrin Mi (...)"
    t.integer "pnmed5yr_ibuprof", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nWithin 5 years after active professional play\nIbuprofen [e.g. Motrin, Advil]"
    t.integer "pnmed5yr_antiinf", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nWithin 5 years after active professional play\nOther anti-inflammatory analgesics[e.g. Aleve, Naprosyn (...)"
    t.integer "pnmed5yr_oralster", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nWithin 5 years after active professional play\nSteroid taken orally[e.g. Prednisone, Medrol]"
    t.integer "pnmed5yr_opioid", comment: "During and after professional play, did you regularly use any of the following pain relief medications?\nWithin 5 years after active professional play\nOpioid-based pain medication [e.g. Percocet, Vicodin]"
    t.integer "pnmed_acetamin", comment: "Are you currently taking any of the following pain relief medications?\nAcetaminophen [e.g. Tylenol]"
    t.integer "pnmed_acetamin_days", comment: "Acetaminophen [e.g. Tylenol]\nDays per week"
    t.integer "pnmed_acetamin_tabs", comment: "Acetaminophen [e.g. Tylenol]\nTablets per day"
    t.integer "pnmed_acetamin_dose", comment: "Acetaminophen [e.g. Tylenol]\nUsual dose per tab"
    t.integer "pnmed_aspirin", comment: "Are you currently taking any of the following pain relief medications?\nAspirin or aspirin containing products[e.g. Excedrin Migraine, Alka-Seltzer with aspirin]"
    t.integer "pnmed_aspirin_days", comment: "Aspirin or aspirin containing products[e.g. Excedrin Migraine, Alka-Seltzer with aspirin]\nDays per week"
    t.integer "pnmed_aspirin_tabs", comment: "Aspirin or aspirin containing products[e.g. Excedrin Migraine, Alka-Seltzer with aspirin]\nTablets per day"
    t.integer "pnmed_aspirin_dose", comment: "Aspirin or aspirin containing products[e.g. Excedrin Migraine, Alka-Seltzer with aspirin]\nUsual dose per tab "
    t.integer "pnmed_ibuprof", comment: "Are you currently taking any of the following pain relief medications?\nIbuprofen [e.g. Motrin, Advil]"
    t.integer "pnmed_ibuprof_days", comment: "Ibuprofen [e.g. Motrin, Advil]\nDays per week"
    t.integer "pnmed_ibuprof_tabs", comment: "Ibuprofen [e.g. Motrin, Advil]\nTablets per day"
    t.integer "pnmed_ibuprof_dose", comment: "Ibuprofen [e.g. Motrin, Advil]\nUsual dose per tab"
    t.integer "pnmed_antiinf", comment: "Are you currently taking any of the following pain relief medications?\nOther anti-inflammatory analgesics[e.g. Aleve, Naprosyn, Relafen, Ketoprofen, Anaprox]"
    t.integer "pnmed_antiinf_days", comment: "Other anti-inflammatory analgesics[e.g. Aleve, Naprosyn, Relafen, Ketoprofen, Anaprox]\nDays per week"
    t.integer "pnmed_antiinf_tabs", comment: "Other anti-inflammatory analgesics[e.g. Aleve, Naprosyn, Relafen, Ketoprofen, Anaprox]\nTablets per day"
    t.integer "pnmed_antiinf_dose", comment: "Other anti-inflammatory analgesics[e.g. Aleve, Naprosyn, Relafen, Ketoprofen, Anaprox]\nUsual dose per tab"
    t.integer "pnmed_oralster", comment: "Are you currently taking any of the following pain relief medications?\nSteroid taken orally [e.g. Prednisone, Medrol]"
    t.integer "pnmed_oralster_days", comment: "Steroid taken orally [e.g. Prednisone, Medrol]\nDays per week"
    t.integer "pnmed_oralster_tabs", comment: "Steroid taken orally [e.g. Prednisone, Medrol]\nTablets per day"
    t.integer "pnmed_oralster_dose", comment: "Steroid taken orally [e.g. Prednisone, Medrol]\nUsual dose per tab"
    t.integer "pnmed_opioid", comment: "Are you currently taking any of the following pain relief medications?\nOpioid-based pain medication [e.g. Percocet, Vicodin]"
    t.integer "pnmed_opioid_days", comment: "Opioid-based pain medication [e.g. Percocet, Vicodin]\nDays per week"
    t.integer "pnmed_opioid_tab", comment: "Opioid-based pain medication [e.g. Percocet, Vicodin]\nTablets per days"
    t.integer "pnmed_opioid_dose", comment: "Opioid-based pain medication [e.g. Percocet, Vicodin]\nUsual dose per tab"
    t.integer "pnsurg_nckspin", comment: "Since January 1, 2015, have you had any of the following surgical procedures?\nNeck/spine surgery"
    t.integer "pnsurg_back", comment: "Since January 1, 2015, have you had any of the following surgical procedures?\nBack (lumbar) surgery"
    t.integer "pnsurg_hip", comment: "Since January 1, 2015, have you had any of the following surgical procedures?\nHip replacement"
    t.integer "pnsurg_knee", comment: "Since January 1, 2015, have you had any of the following surgical procedures?\nKnee replacement"
    t.integer "pain___complete"
    t.datetime "pain_date", comment: "Hidden on survey;\nDate and time that the Pain domain of Q2 survey was completed"
    t.integer "wealth", comment: "What is your approximate household net worth? _x000D_\n[the value of all the assets of people in your household(like housing, cars, stock, retirement funds, and businessownership) minus any debt or loans you and house (...)"
    t.integer "wealth_emerg___1", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___2", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___3", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___4", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___5", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___6", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___7", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___8", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "wealth_emerg___9", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.text "wealth_emerg_oth", comment: "Suppose that you have an emergency expense that costs $400...\nBased on your current financial situation, how would you pay for this expense? If you would use more than one method to cover this expense, plea (...)"
    t.integer "ladder_wealth", comment: "The following questions relate to how you feel about your standing in US society and in your community.\nA) Think of this ladder as representing where people stand in the United States.\nAt the top of the lad (...)"
    t.integer "ladder_comm", comment: "The following questions relate to how you feel about your standing in US society and in your community.\nB)  Now think of this ladder as representing where people stand in their communities. People define commu (...)"
    t.integer "household_number", comment: "How many people are in your household?"
    t.integer "hcutil_pcp", comment: "Have you seen you seen your primary care physician (PCP) in the past 3 years?"
    t.integer "hcutil_pcp_exp", comment: "Have you seen you seen your primary care  physician (PCP) in the past 3 years?\nIf not, why?"
    t.text "hcutil_pcp_oth", comment: "Have you seen you seen your primary care  physician (PCP) in the past 3 years?\nIf not, why?\nIf Other, please explain:"
    t.integer "hcutil_othprov", comment: "Have you seen a physician or healthcare provider other than your PCP in the past 3 years?\n(e.g. physical therapist, cardiologist, endocrinologist, etc.)"
    t.integer "selfrpt_cte", comment: "Do you believe you have Chronic Traumatic Encephalopathy (CTE)?"
    t.integer "otdx_arthritis", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nArthritis (e.g. osteoarthritis)"
    t.integer "otdx_slpapnea", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nSleep apnea"
    t.integer "otdx_prostcanc", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nProstate cancer"
    t.integer "otdx_basalcanc", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nBasal cell skin cancer"
    t.integer "otdx_squamcanc", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nSquamous cell skin cancer"
    t.integer "otdx_melanom", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nMelanoma"
    t.integer "otdx_lymphom", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nLymphoma"
    t.integer "otdx_othcanc", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nOther cancer"
    t.integer "otdx_renalfail", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nChronic renal failure"
    t.integer "otdx_alcdep", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nAlcohol dependence problem"
    t.integer "otdx_livcirrhosis", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nLiver cirrhosis"
    t.integer "otdx_livfail", comment: "Since January 1, 2015, has a healthcare provider told you that you have had any of the following diagnoses or health outcomes?\nLiver failure"
    t.integer "otmedrec_pncond", comment: "Since January 1, 2015, has a medical provider recommended or prescribed medicine for any of the following conditions?\nPain related condition"
    t.integer "otmedrec_livprob", comment: "Since January 1, 2015, has a medical provider recommended or prescribed medicine for any of the following conditions?\nLiver problem"
    t.integer "otmedrec_lowtest", comment: "Since January 1, 2015, has a medical provider recommended or prescribed medicine for any of the following conditions?\nLow testosterone"
    t.integer "otmedrec_ed", comment: "Since January 1, 2015, has a medical provider recommended or prescribed medicine for any of the following conditions?\nErectile dysfunction (E.D.)"
    t.integer "massage", comment: "Are you currently using any other health practices?\nMassage"
    t.integer "acupuncture", comment: "Are you currently using any other health practices?\nAcupuncture"
    t.integer "chiropractic", comment: "Are you currently using any other health practices?\nChiropractic treatment"
    t.integer "yoga", comment: "Are you currently using any other health practices?\nYoga"
    t.integer "taichi", comment: "Are you currently using any other health practices?\nTai chi"
    t.integer "meditation", comment: "Are you currently using any other health practices?\nMeditation"
    t.integer "othaltmed", comment: "Are you currently using any other health practices?\nOther alternative medication"
    t.text "othaltmed_exp", comment: "Are you currently using any other health practices?\nOther alternative medication\nPlease specify:"
    t.integer "famhxmoth___na", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nNot applicable"
    t.integer "famhxmoth___lung", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nLung Cancer"
    t.integer "famhxmoth___colrec", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nColon or rectal cancer"
    t.integer "famhxmoth___diab", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nDiabetes"
    t.integer "famhxmoth___mela", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nMelanoma"
    t.integer "famhxmoth___hypert", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nHypertension"
    t.integer "famhxmoth___dem", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nDementia before age 70"
    t.integer "famhxmoth___alc", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMother\nAlcohol problem"
    t.integer "famhxfsib___na", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nNot applicable"
    t.integer "famhxfsib___lung", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nLung Cancer"
    t.integer "famhxfsib___colrec", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nColon or rectal cancer"
    t.integer "famhxfsib___diab", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nDiabetes"
    t.integer "famhxfsib___mela", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nMelanoma"
    t.integer "famhxfsib___hypert", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nHypertension"
    t.integer "famhxfsib___dem", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nDementia before age 70"
    t.integer "famhxfsib___alc", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFemale Sibling\nAlcohol problem"
    t.integer "femsib_number", comment: "How many full female siblings do you have?"
    t.integer "famhxfath___na", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nNot applicable"
    t.integer "famhxfath___lung", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nLung Cancer"
    t.integer "famhxfath___colrec", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nColon or rectal cancer"
    t.integer "famhxfath___prost", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nProstate cancer"
    t.integer "famhxfath___diab", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nDiabetes"
    t.integer "famhxfath___mela", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nMelanoma"
    t.integer "famhxfath___hypert", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nHypertension"
    t.integer "famhxfath___dem", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nDementia before age 70"
    t.integer "famhxfath___alc", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nFather\nAlcohol problem"
    t.integer "famhxmsib___na", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nNot applicable"
    t.integer "famhxmsib___lung", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nLung Cancer"
    t.integer "famhxmsib___colrec", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nColon or rectal cancer"
    t.integer "famhxmsib___prost", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nProstate cancer"
    t.integer "famhxmsib___diab", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nDiabetes"
    t.integer "famhxmsib___mela", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nMelanoma"
    t.integer "famhxmsib___hypert", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nHypertension"
    t.integer "famhxmsib___dem", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nDementia before age 70"
    t.integer "famhxmsib___alc", comment: "Did your parents or siblings have any of the following diagnoses or health outcomes? Please select all that apply.\nMale Sibling\nAlcohol problem"
    t.integer "sib_number", comment: "How many full male siblings do you have?"
    t.decimal "sib1age", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nCurrent age:"
    t.decimal "sib1ht_feet", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nHeight (feet):"
    t.decimal "sib1ht_inch", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nHeight (inches):"
    t.integer "sib1sport___none", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nDid not play (...)"
    t.integer "sib1sport___hsfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nPlayed H.S.  (...)"
    t.integer "sib1sport___colfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nPlayed coll (...)"
    t.integer "sib1sport___oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nOther"
    t.text "sib1sport_oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 1:\nOther\nPlease sp (...)"
    t.decimal "sib2age", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nCurrent age:"
    t.decimal "sib2ht_feet", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nHeight (feet):"
    t.decimal "sib2ht_inch", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nHeight (inches):"
    t.integer "sib2sport___none", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nDid not play (...)"
    t.integer "sib2sport___hsfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nPlayed H.S.  (...)"
    t.integer "sib2sport___colfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nPlayed coll (...)"
    t.integer "sib2sport___oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nOther"
    t.text "sib2sport_oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nOther\nPlease sp (...)"
    t.decimal "sib3age", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nCurrent age:"
    t.decimal "sib3ht_feet", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nHeight (feet):"
    t.decimal "sib3ht_inch", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 2:\nHeight (inches):"
    t.integer "sib3sport___none", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 3:\nDid not play (...)"
    t.integer "sib3sport___hsfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 3:\nPlayed H.S.  (...)"
    t.integer "sib3sport___colfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 3:\nPlayed coll (...)"
    t.integer "sib3sport___oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 3:\nOther"
    t.text "sib3sport_oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 3:\nOther\nPlease sp (...)"
    t.decimal "sib4age", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nCurrent age:"
    t.decimal "sib4ht_feet", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nHeight (feet):"
    t.decimal "sib4ht_inch", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nHeight (inches):"
    t.integer "sib4sport___none", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nDid not play (...)"
    t.integer "sib4sport___hsfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nPlayed H.S.  (...)"
    t.integer "sib4sport___colfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nPlayed coll (...)"
    t.integer "sib4sport___oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nOther"
    t.text "sib4sportoth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 4:\nOther\nPlease spe (...)"
    t.decimal "sib5age", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nCurrent age:"
    t.decimal "sib5ht_feet", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nHeight (feet):"
    t.decimal "sib5ht_inch", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nHeight (inches): (...)"
    t.integer "sib5sport___none", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nDid not play (...)"
    t.integer "sib5sport___hsfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nPlayed H.S.  (...)"
    t.integer "sib5sport___colfb", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nPlayed coll (...)"
    t.integer "sib5sport___oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nOther"
    t.text "sib5sport_oth", comment: "Please list the birth order of all your full male siblings. Provide their age, height, and indicate if they played football in high school, college, or other sports in college.\nMale Sibling 5:\nOther\nPlease sp (...)"
    t.integer "pedcaff___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? Select all choices that apply.\n*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pedcaff___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solely (...)"
    t.integer "pedcaff___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance?\n Select all choices that apply.*All information disclosed in this survey is confidential and will be used solely (...)"
    t.integer "pedcaff___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance?\n Select all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pededrink___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used s (...)"
    t.integer "pededrink___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pededrink___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pededrink___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nelect all choices that apply.*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pedcreat___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used so (...)"
    t.integer "pedcreat___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedcreat___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedcreat___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pedsteroid___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used  (...)"
    t.integer "pedsteroid___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pedsteroid___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pedsteroid___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used so (...)"
    t.integer "pedgh___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedgh___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solely f (...)"
    t.integer "pedgh___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solely f (...)"
    t.integer "pedgh___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solely  (...)"
    t.integer "pedephed___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used so (...)"
    t.integer "pedephed___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedephed___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedephed___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pedbetahy___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used s (...)"
    t.integer "pedbetahy___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pedbetahy___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pedbetahy___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pednoncaf___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used s (...)"
    t.integer "pednoncaf___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pednoncaf___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pednoncaf___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pedrcell___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used so (...)"
    t.integer "pedrcell___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedrcell___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "pedrcell___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used sole (...)"
    t.integer "pedinos___noans", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance?\n Select all choices that apply.*All information disclosed in this survey is confidential and will be used sol (...)"
    t.integer "pedinos___no", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance?\n Select all choices that apply.*All information disclosed in this survey is confidential and will be used solely (...)"
    t.integer "pedinos___fb", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solely (...)"
    t.integer "pedinos___cur", comment: "Have you ever tried or used any of the following in an attempt to improve your sports performance? \nSelect all choices that apply.*All information disclosed in this survey is confidential and will be used solel (...)"
    t.integer "alcohol_days", comment: "In a typical week, how many days do you drink a beverage containing alcohol?"
    t.integer "alcohol_drinks", comment: "On a typical day that you drink, how many alcoholic beverages do you usually have?"
    t.integer "marijuana", comment: "Do you smoke or ingest marijuana?"
    t.decimal "marijuana_start", comment: "How old were you when you started smoking marijuana?"
    t.decimal "marijuana_stop", comment: "How old were you when you stopped smoking marijuana?"
    t.decimal "marijuana_totyrs", comment: "How many years, in total, have you smoked marijuana?(if you quit more than once, estimate the total years you considered yourself an active smoker)"
    t.integer "marijtime___pnfl", comment: "Please indicate the time-frames during which you smoked marijuana (select all that apply):\nBefore playing in the NFL"
    t.integer "marijtime___dnfl", comment: "Please indicate the time-frames during which you smoked marijuana (select all that apply):\nWhile playing in the NFL"
    t.integer "marijtime___anfl", comment: "Please indicate the time-frames during which you smoked marijuana (select all that apply):\nAfter playing in the NFL"
    t.integer "marijreas___fun", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nFun"
    t.integer "marijreas___relx", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nRelaxation"
    t.integer "marijreas___pain", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nPain"
    t.integer "marijreas___anx", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nAnxiety"
    t.integer "marijreas___dep", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nDepression"
    t.integer "marijreas___oth", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nOther"
    t.text "marijreas_exp", comment: "Please indicate the reasons why you use, or have previously used, marijuana (select all that apply):\nIf Other reason, please explain:"
    t.text "born_address", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nBorn:\nAddress:"
    t.text "born_city", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nBorn:\nCity:"
    t.integer "born_state", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nBorn:\nState:"
    t.decimal "born_zip", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nBorn:\nZip code (if known)"
    t.text "twelveyrs_address", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nAt 12 years of age:\nAddress:"
    t.text "twelveyrs_city", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nAt 12 years of age:\nCity:"
    t.integer "twelveyrs_state", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nAt 12 years of age:\nState:"
    t.decimal "twelveyrs_zip", comment: "Indicate where you have lived for the time-frames listed. Please fill in as much as you can remember.\nAt 12 years of age:\nZip code (if known)"
    t.integer "infertility", comment: "Please answer the following questions to the best of your knowledge:\nHave you and a female spouse or partner ever tried to become pregnant for 12 consecutive months without becoming pregnant (even if she ultimat (...)"
    t.decimal "infert_age", comment: "Have you and a female spouse or partner evertried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nHow old were you when this first happened?"
    t.integer "infert_hcp", comment: "Have you and a female spouse or partner evertried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nDid you seek help from a healthcare provider?"
    t.integer "infertreas___fem", comment: "Have you and a female spouse or partner ever tried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nDid he or she find a reason why you and you (...)"
    t.integer "infertreas___mal", comment: "Have you and a female spouse or partner ever tried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nDid he or she find a reason why you and you (...)"
    t.integer "infertreas___unex", comment: "Have you and a female spouse or partner ever tried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nDid he or she find a reason why you and yo (...)"
    t.integer "infertreas___oth", comment: "Have you and a female spouse or partner ever tried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nDid he or she find a reason why you and you (...)"
    t.text "infertreas_oth", comment: "Have you and a female spouse or partner ever tried to become pregnant for 12 consecutivemonths without becoming pregnant (even if she ultimately became pregnant)?\nDid he or she find a reason why you and yourf (...)"
    t.integer "actout_dreams", comment: "Has your spouse [or sleep partner] told you that you appear to act out your dreams while sleeping [punched or flailed arms in the air, shouted, screamed], which has occurred at least three times?"
    t.integer "smell_problem", comment: "Have you had any problems with your sense of smell, such as not being able to smell things or things not smelling the way they are supposed to for at least three months?"
    t.integer "taste_problem", comment: "Have you had any problems with your sense of taste, such as not being able to taste salt or sugar or with tastes in the mouth that shouldnt be there, like bitter, salty, sour, or sweet tastes for at least thr (...)"
    t.integer "bowel_move", comment: "How frequently do you have a bowel movement?"
    t.integer "laxative_use", comment: "How often do you use a laxative? (Such as softeners, bulking agents, fiber supplements, or suppositories)"
    t.integer "workplace_harass", comment: "Bullying or harassment is a problem in some workplaces. While you were in the NFL...\nWas there a period of time when you frequently experienced any of the following from teammates, coaches or trainers: soci (...)"
    t.integer "coach_discrim", comment: "Bullying or harassment is a problem in some workplaces. While you were in the NFL...\nHow many times were you treated unfairly by COACHES OR TRAINERS because of your race or ethnicity?"
    t.integer "coach_discrimstr", comment: "Bullying or harassment is a problem in some workplaces. While you were in the NFL...\nHow many times were you treated unfairly by COACHES OR TRAINERS because of yourrace or ethnicity?\nHow stressful was this  (...)"
    t.integer "player_discrim", comment: "Bullying or harassment is a problem in some workplaces. While you were in the NFL...\nHow many times were you treated unfairly by OTHER PLAYERS because of your race or ethnicity?"
    t.integer "player_discrimstr", comment: "Bullying or harassment is a problem in some workplaces. While you were in the NFL...\nHow many times were you treated unfairly by OTHER PLAYERS because of your race orethnicity?\nHow stressful was this for y (...)"
    t.integer "job_discrim", comment: "After your playing years...\nHow many times were you treated unfairly in being hired for a job or promoted because of your race or ethnicity?"
    t.integer "job_discrimstr", comment: "After your playing years…\nHow many times were you treated unfairly in being hired for a job or promoted because of your race or ethnicity?\nHow stressful was this for you?"
    t.integer "ace1", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid a parent or other adult in the household often or very often..._x000D_\n_x000D_\nS (...)"
    t.integer "ace2", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid a parent or other adult in the household often or very often..._x000D_\n_x000D_\nP (...)"
    t.integer "ace3", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid an adult or person at least 5 years older than you ever..._x000D_\n_x000D_\nTouch  (...)"
    t.integer "ace4", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid you often or very often feel that..._x000D_\n_x000D_\nNo one in your family loved  (...)"
    t.integer "ace5", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid you often or very often feel that..._x000D_\n_x000D_\nYou didnt have enough to ea (...)"
    t.integer "ace6", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nWere your parents ever separated or divorced?"
    t.integer "ace7", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nWas your mother or stepmother:_x000D_\nOften or very often pushed, grabbed, slapped, (...)"
    t.integer "ace8", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid you live with anyone who was a problem drinker or alcoholic, or who used street  (...)"
    t.integer "ace9", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nWas a household member depressed or mentally ill, or did a household member attempt  (...)"
    t.integer "ace10", comment: "Things that happen in childhood sometimes affect our health as adults. While you were growing up, during your first 18 years of life:\nDid a household member go to prison?"
    t.integer "foodins_worry", comment: "As a child growing up...\nI worried whether our food would run out before we got money to buy more"
    t.integer "foodins_ranout", comment: "As a child growing up...\nThe food my family bought just didnt last and we didnt have money to get more"
    t.integer "q2help", comment: "Did someone help you fill out the questionnaire?"
    t.integer "othealth___complete", comment: "Have you completed all questions that you intend to answer on this page? \nOnce you have advanced to the next section, you will not be able to return.\nOther Health Domain"
    t.datetime "othealth_date", comment: "Hidden on survey;\nDate and time that Other Health domain of Q2 survey was completed"
    t.integer "q2_complete", comment: "Hidden on survey;\nCompletion status of the full Q2 survey"
  end

  create_table "q2_datadic", id: :integer, default: -> { "nextval('datadic_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "variable_name", null: false
    t.text "domain"
    t.text "field_type_rc"
    t.text "field_type_sa"
    t.text "field_label"
    t.text "field_attributes"
    t.text "field_note"
    t.text "text_valid_type"
    t.text "text_valid_min"
    t.text "text_valid_max"
    t.text "required_field"
    t.text "field_attr_array", array: true
    t.text "source"
    t.text "owner"
    t.text "classification"
    t.text "display"
  end

  create_table "q2_rc_codebook", id: :serial, force: :cascade do |t|
    t.string "variable_name", null: false
    t.text "q2_domain"
    t.text "field_label"
    t.text "field_attributes"
    t.text "notes"
    t.text "field_attr_array", array: true
  end

  create_table "rc_cis", id: :serial, force: :cascade do |t|
    t.string "fname"
    t.string "lname"
    t.string "status"
    t.datetime "created_at", default: "2017-09-25 15:43:37"
    t.datetime "updated_at", default: "2017-09-25 15:43:37"
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

  create_table "rc_femfl_cif", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.integer "master_id"
    t.decimal "record_id"
    t.text "redcap_survey_identifier"
    t.datetime "femfl_contact_info_timestamp"
    t.text "first_name"
    t.text "last_name"
    t.text "email"
    t.text "cell_number"
    t.text "other_phone_number"
    t.decimal "hear_about___1"
    t.decimal "hear_about___10"
    t.decimal "hear_about___11"
    t.decimal "hear_about___12"
    t.decimal "hear_about___2"
    t.decimal "hear_about___3"
    t.decimal "hear_about___4"
    t.decimal "hear_about___5"
    t.decimal "hear_about___6"
    t.decimal "hear_about___7"
    t.decimal "hear_about___8"
    t.decimal "hear_about___9"
    t.text "hear_about_wives_group"
    t.text "hear_about_event"
    t.text "hear_about_other"
    t.decimal "relationship_to_player___1"
    t.decimal "relationship_to_player___2"
    t.decimal "relationship_to_player___3"
    t.decimal "relationship_to_player___4"
    t.decimal "relationship_to_player___5"
    t.decimal "relationship_to_player___6"
    t.decimal "relationship_to_player___7"
    t.decimal "relationship_to_player___8"
    t.decimal "relationship_to_player___9"
    t.decimal "relationship_to_player___10"
    t.decimal "relationship_to_player___11"
    t.text "relationship_other"
    t.text "comments"
    t.decimal "femfl_contact_info_complete"
  end

  create_table "rc_links", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.integer "master_id"
    t.string "link"
  end

  create_table "rc_links", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.integer "master_id"
    t.string "link"
  end

  create_table "rc_stage", id: false, force: :cascade do |t|
    t.integer "record_id"
    t.integer "redcap_survey_identifier"
    t.datetime "football_players_health_study_questionnaire_1_timestamp"
    t.date "dob"
    t.integer "age"
    t.integer "race___1"
    t.integer "race___2"
    t.integer "race___3"
    t.integer "race___4"
    t.integer "race___5"
    t.integer "race___6"
    t.integer "race___7"
    t.integer "hispanic"
    t.integer "domesticstatus"
    t.integer "livingsituation"
    t.integer "height"
    t.integer "current_weight"
    t.integer "highschool_wt"
    t.integer "college_wt"
    t.integer "pro_wt"
    t.integer "maxretire_wt"
    t.integer "startplay_age"
    t.float "numb_season"
    t.integer "first_cal_yearplay"
    t.integer "last_cal_yearplay"
    t.integer "position___1"
    t.integer "position___2"
    t.integer "position___3"
    t.integer "position___4"
    t.integer "position___5"
    t.integer "position___6"
    t.integer "position___7"
    t.integer "position___8"
    t.integer "position___9"
    t.integer "position___10"
    t.integer "global1"
    t.integer "global2"
    t.integer "global3"
    t.integer "global4"
    t.integer "global5"
    t.integer "global6"
    t.integer "global7"
    t.integer "global8"
    t.integer "global10"
    t.integer "phq1"
    t.integer "phq2"
    t.integer "gad1"
    t.integer "gad_2"
    t.integer "number_days_exercise"
    t.integer "walking"
    t.integer "jogging"
    t.integer "running"
    t.integer "other_aerobic"
    t.integer "low_intensity_exercise"
    t.integer "weight_training"
    t.integer "promis_pf6b1"
    t.integer "promis_pf6b2"
    t.integer "promis_pf6b3"
    t.integer "promis_pf6b4"
    t.integer "promis_pf6b5"
    t.integer "promis_pf6b6"
    t.integer "painin3"
    t.integer "painin8"
    t.integer "painin9"
    t.integer "painin10"
    t.integer "painin14"
    t.integer "painin26"
    t.integer "nqcog64"
    t.integer "nqcog65"
    t.integer "nqcog66"
    t.integer "nqcog68"
    t.integer "nqcog72"
    t.integer "nqcog75"
    t.integer "nqcog77"
    t.integer "nqcog80"
    t.integer "nqcog67_editted"
    t.integer "nqcog84"
    t.integer "nqcog86"
    t.integer "pcp"
    t.integer "other_health_professional"
    t.integer "supplement___1"
    t.integer "supplement___2"
    t.integer "supplement___3"
    t.integer "supplement___4"
    t.integer "medication___1"
    t.integer "medication___2"
    t.integer "medication___3"
    t.integer "medication___4"
    t.integer "pain_medications___1"
    t.integer "pain_medications___2"
    t.integer "pain_medications___3"
    t.integer "pain_medications___4"
    t.integer "dx_concussion"
    t.string "numb_concussions", limit: 255
    t.integer "headaches_ht"
    t.integer "nausea"
    t.integer "dizziness"
    t.integer "loss_of_consciousness"
    t.integer "memory_problems"
    t.integer "disorientation"
    t.integer "confusion"
    t.integer "seizure"
    t.integer "visual_problems"
    t.integer "weakness_on_one_side_of_th"
    t.integer "feeling_unsteady_on_your_f"
    t.integer "neck_surgery"
    t.integer "back_surgery"
    t.integer "anterior_cruciate_ligament"
    t.integer "knee_surgery"
    t.integer "ankle_surgery"
    t.integer "shoulder_surgery"
    t.integer "hand_surgery"
    t.integer "knee_joint_replacement"
    t.string "approxyrssurg_knee", limit: 255
    t.integer "hip_joint_replacemen"
    t.string "approxyrssurg_hip", limit: 255
    t.integer "cardiac_surgery"
    t.string "approxyrssurg_cardiac", limit: 255
    t.integer "cataract_surgery"
    t.string "approxyrssurg_cataract", limit: 255
    t.integer "neck_spine_surgery"
    t.string "approxyrssurg_neckspine", limit: 255
    t.integer "back_surgery1"
    t.string "approxyrssurg_back", limit: 255
    t.integer "othersurgery"
    t.string "type_other_surgery", limit: 255
    t.string "years_other_surgery", limit: 255
    t.integer "high_blood_pressure"
    t.integer "current_htn_med"
    t.integer "heart_failure"
    t.integer "current_heartfailure_med"
    t.integer "heart_rhythm"
    t.integer "current_heartrhythm_med"
    t.integer "high_cholesterol"
    t.integer "current_highcholesterol"
    t.integer "diabetes_high_blood_sugar"
    t.integer "current_diabetes_med"
    t.integer "headaches"
    t.integer "current_headache_med"
    t.integer "pain_medication"
    t.integer "current_medication_pain"
    t.integer "liver_probelm"
    t.integer "current_med_liver_problem"
    t.integer "anxiety"
    t.integer "current_anxiety_med"
    t.integer "depression"
    t.integer "current_depression_med"
    t.integer "memory_loss"
    t.integer "current_med_memory_loss"
    t.integer "add"
    t.integer "current_med_add"
    t.integer "low_testosterone"
    t.integer "current_lowt_med"
    t.integer "erectile_dys"
    t.integer "current_erectile_dys"
    t.integer "heart_attack"
    t.string "yr_dx_heart_attack", limit: 255
    t.integer "stroke"
    t.string "yr_dx_stroke", limit: 255
    t.integer "sleep_apnea"
    t.string "yr_dx_sleepapnea", limit: 255
    t.integer "dementia"
    t.string "yr_dx_dementia", limit: 255
    t.integer "cte"
    t.string "yr_dx_cte", limit: 255
    t.integer "parkinsons"
    t.string "yr_dx_parkinsons", limit: 255
    t.integer "arthritis"
    t.string "yr_dx_arthritis", limit: 255
    t.integer "als"
    t.string "yr_dx_als", limit: 255
    t.integer "renal_kidney_disease"
    t.string "yr_dx_kidney_dx", limit: 255
    t.integer "cancer"
    t.string "cancer_type", limit: 255
    t.string "yr_dx_cancer", limit: 255
    t.integer "days_drink_week"
    t.integer "drinksday"
    t.integer "smoking_hx"
    t.integer "do_you_currently_or_have_y"
    t.integer "snore_loudly"
    t.integer "sleephrs"
    t.integer "health_expectation"
    t.integer "are_you_currently_employed"
    t.integer "student_looking"
    t.integer "job_in_football"
    t.string "other_job_in_football", limit: 255
    t.string "job_industry", limit: 255
    t.string "job_outside_football", limit: 255
    t.string "retired_industry", limit: 255
    t.string "retired_job_title", limit: 255
    t.integer "questionnaire_help"
    t.integer "football_players_health_study_questionnaire_1_complete"
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
    t.datetime "created_at", default: "2017-09-25 15:43:37"
    t.integer "user_id"
    t.integer "master_id"
    t.datetime "updated_at", default: "2017-09-25 15:43:37"
    t.boolean "added_tracker"
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

  create_table "sage_assignments", id: :serial, force: :cascade do |t|
    t.string "sage_id", limit: 10
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

  create_table "sage_two_history", id: :serial, force: :cascade do |t|
    t.integer "sage_two_id"
    t.integer "master_id"
    t.bigint "external_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sage_two_history_on_master_id"
    t.index ["sage_two_id"], name: "index_sage_two_history_on_sage_two_id"
    t.index ["user_id"], name: "index_sage_two_history_on_user_id"
  end

  create_table "sage_twos", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "external_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sage_twos_on_master_id"
    t.index ["user_id"], name: "index_sage_twos_on_user_id"
  end

  create_table "sc_stage", id: false, force: :cascade do |t|
    t.string "ncs_header", limit: 100
    t.integer "litho"
    t.date "opp_date"
    t.date "dob"
    t.integer "age"
    t.integer "race___1"
    t.integer "race___2"
    t.integer "race___3"
    t.integer "race___4"
    t.integer "race___5"
    t.integer "race___6"
    t.integer "hispanic"
    t.integer "domesticstatus"
    t.integer "livingsituation"
    t.integer "feet"
    t.integer "inches"
    t.integer "current_weight"
    t.integer "highschool_wt"
    t.integer "college_wt"
    t.integer "pro_wt"
    t.integer "maxretire_wt"
    t.integer "startplay_age"
    t.float "numb_season"
    t.integer "first_cal_yearplay"
    t.integer "last_cal_yearplay"
    t.integer "position___1"
    t.integer "position___2"
    t.integer "position___3"
    t.integer "position___4"
    t.integer "position___5"
    t.integer "position___6"
    t.integer "position___7"
    t.integer "position___8"
    t.integer "position___9"
    t.integer "position___10"
    t.integer "global1"
    t.integer "global2"
    t.integer "global3"
    t.integer "global4"
    t.integer "global5"
    t.integer "global6"
    t.integer "global7"
    t.integer "global8"
    t.integer "global10"
    t.integer "phq1"
    t.integer "phq2"
    t.integer "gad1"
    t.integer "gad_2"
    t.integer "number_days_exercise"
    t.integer "walking"
    t.integer "jogging"
    t.integer "running"
    t.integer "other_aerobic"
    t.integer "low_intensity_exercise"
    t.integer "weight_training"
    t.integer "promis_pf6b1"
    t.integer "promis_pf6b2"
    t.integer "promis_pf6b3"
    t.integer "promis_pf6b4"
    t.integer "promis_pf6b5"
    t.integer "promis_pf6b6"
    t.integer "painin3"
    t.integer "painin8"
    t.integer "painin9"
    t.integer "painin10"
    t.integer "painin14"
    t.integer "painin26"
    t.integer "nqcog64"
    t.integer "nqcog65"
    t.integer "nqcog66"
    t.integer "nqcog68"
    t.integer "nqcog72"
    t.integer "nqcog75"
    t.integer "nqcog77"
    t.integer "nqcog80"
    t.integer "nqcog67_editted"
    t.integer "nqcog84"
    t.integer "nqcog86"
    t.integer "pcp"
    t.integer "other_health_professional"
    t.integer "supplement___1"
    t.integer "supplement___2"
    t.integer "supplement___3"
    t.integer "supplement___4"
    t.integer "medication___1"
    t.integer "medication___2"
    t.integer "medication___3"
    t.integer "medication___4"
    t.integer "pain_medications___1"
    t.integer "pain_medications___2"
    t.integer "pain_medications___3"
    t.integer "pain_medications___4"
    t.integer "dx_concussion"
    t.string "numb_concussions", limit: 255
    t.integer "headaches_ht"
    t.integer "nausea"
    t.integer "dizziness"
    t.integer "loss_of_consciousness"
    t.integer "memory_problems"
    t.integer "disorientation"
    t.integer "confusion"
    t.integer "seizure"
    t.integer "visual_problems"
    t.integer "weakness_on_one_side_of_th"
    t.integer "feeling_unsteady_on_your_f"
    t.integer "neck_surgery"
    t.integer "back_surgery"
    t.integer "anterior_cruciate_ligament"
    t.integer "knee_surgery"
    t.integer "ankle_surgery"
    t.integer "shoulder_surgery"
    t.integer "hand_surgery"
    t.integer "knee_joint_replacement"
    t.string "approxyrssurg_knee", limit: 255
    t.integer "hip_joint_replacemen"
    t.string "approxyrssurg_hip", limit: 255
    t.integer "cardiac_surgery"
    t.string "approxyrssurg_cardiac", limit: 255
    t.integer "cataract_surgery"
    t.string "approxyrssurg_cataract", limit: 255
    t.integer "neck_spine_surgery"
    t.string "approxyrssurg_neckspine", limit: 255
    t.integer "back_surgery1"
    t.string "approxyrssurg_back", limit: 255
    t.integer "othersurgery"
    t.string "type_other_surgery", limit: 255
    t.integer "operator65"
    t.string "years_other_surgery", limit: 255
    t.integer "high_blood_pressure"
    t.integer "current_htn_med"
    t.integer "heart_failure"
    t.integer "current_heartfailure_med"
    t.integer "heart_rhythm"
    t.integer "current_heartrhythm_med"
    t.integer "high_cholesterol"
    t.integer "current_highcholesterol"
    t.integer "diabetes_high_blood_sugar"
    t.integer "current_diabetes_med"
    t.integer "headaches"
    t.integer "current_headache_med"
    t.integer "pain_medication"
    t.integer "current_medication_pain"
    t.integer "liver_problem"
    t.integer "current_med_liver_problem"
    t.integer "anxiety"
    t.integer "current_anxiety_med"
    t.integer "depression"
    t.integer "current_depression_med"
    t.integer "memory_loss"
    t.integer "current_med_memory_loss"
    t.integer "add"
    t.integer "current_med_add"
    t.integer "low_testosterone"
    t.integer "current_lowt_med"
    t.integer "erectile_dys"
    t.integer "current_erectile_dys"
    t.integer "heart_attack"
    t.string "yr_dx_heart_attack", limit: 255
    t.integer "stroke"
    t.string "yr_dx_stroke", limit: 255
    t.integer "sleep_apnea"
    t.string "yr_dx_sleepapnea", limit: 255
    t.integer "dementia"
    t.string "yr_dx_dementia", limit: 255
    t.integer "cte"
    t.string "yr_dx_cte", limit: 255
    t.integer "parkinsons"
    t.string "yr_dx_parkinsons", limit: 255
    t.integer "arthritis"
    t.string "yr_dx_arthritis", limit: 255
    t.integer "als"
    t.string "yr_dx_als", limit: 255
    t.integer "renal_kidney_disease"
    t.string "yr_dx_kidney_dx", limit: 255
    t.integer "cancer"
    t.string "cancer_type", limit: 255
    t.integer "operator67"
    t.string "yr_dx_cancer", limit: 255
    t.integer "days_drink_week"
    t.integer "drinksday"
    t.integer "smoking_hx"
    t.integer "do_you_currently_or_have_y"
    t.integer "snore_loudly"
    t.integer "sleephrs"
    t.integer "health_expectation"
    t.integer "are_you_currently_employed"
    t.integer "student_looking"
    t.integer "job_in_football"
    t.string "other_job_in_football", limit: 255
    t.string "job_industry", limit: 255
    t.string "job_outside_football", limit: 255
    t.string "job_outside_ses", limit: 255
    t.string "retired_industry", limit: 255
    t.string "retired_job_title", limit: 255
    t.string "retired_ses", limit: 255
    t.integer "operator75"
    t.integer "questionnaire_help"
    t.integer "msid"
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

  create_table "scantron_q2_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "q2_scantron_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scantron_q2_table_id"
    t.index ["admin_id"], name: "index_scantron_q2_history_on_admin_id"
    t.index ["master_id"], name: "index_scantron_q2_history_on_master_id"
    t.index ["scantron_q2_table_id"], name: "index_scantron_q2_history_on_scantron_q2_table_id"
    t.index ["user_id"], name: "index_scantron_q2_history_on_user_id"
  end

  create_table "scantron_q2s", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "q2_scantron_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_scantron_q2s_on_admin_id"
    t.index ["master_id"], name: "index_scantron_q2s_on_master_id"
    t.index ["user_id"], name: "index_scantron_q2s_on_user_id"
  end

  create_table "scantron_series_two_history", id: :serial, force: :cascade do |t|
    t.integer "scantron_series_two_id"
    t.integer "master_id"
    t.bigint "external_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_scantron_series_two_history_on_master_id"
    t.index ["scantron_series_two_id"], name: "index_scantron_series_two_history_on_scantron_series_two_id"
    t.index ["user_id"], name: "index_scantron_series_two_history_on_user_id"
  end

  create_table "scantron_series_twos", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "external_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_scantron_series_twos_on_master_id"
    t.index ["user_id"], name: "index_scantron_series_twos_on_user_id"
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

  create_table "sleep_access_bwh_staff_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_access_bwh_staff_id"
    t.index ["master_id"], name: "index_sleep_access_bwh_staff_history_on_master_id"
    t.index ["sleep_access_bwh_staff_id"], name: "index_sleep_access_bwh_staff_history_on_sleep_access_bwh_staff_"
    t.index ["user_id"], name: "index_sleep_access_bwh_staff_history_on_user_id"
  end

  create_table "sleep_access_bwh_staffs", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_access_bwh_staffs_on_master_id"
    t.index ["user_id"], name: "index_sleep_access_bwh_staffs_on_user_id"
  end

  create_table "sleep_access_interventionist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "assign_access_to_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_access_interventionist_id"
    t.index ["master_id"], name: "index_sleep_access_interventionist_history_on_master_id"
    t.index ["sleep_access_interventionist_id"], name: "index_sleep_access_interventionist_history_on_sleep_access_inte"
    t.index ["user_id"], name: "index_sleep_access_interventionist_history_on_user_id"
  end

  create_table "sleep_access_interventionists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "assign_access_to_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_access_interventionists_on_master_id"
    t.index ["user_id"], name: "index_sleep_access_interventionists_on_user_id"
  end

  create_table "sleep_access_pi_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_access_pi_id"
    t.index ["master_id"], name: "index_sleep_access_pi_history_on_master_id"
    t.index ["sleep_access_pi_id"], name: "index_sleep_access_pi_history_on_sleep_access_pi_id"
    t.index ["user_id"], name: "index_sleep_access_pi_history_on_user_id"
  end

  create_table "sleep_access_pis", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_access_pis_on_master_id"
    t.index ["user_id"], name: "index_sleep_access_pis_on_user_id"
  end

  create_table "sleep_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_adverse_event_id"
    t.index ["master_id"], name: "index_sleep_adverse_event_history_on_master_id"
    t.index ["sleep_adverse_event_id"], name: "index_sleep_adverse_event_history_on_sleep_adverse_event_id"
    t.index ["user_id"], name: "index_sleep_adverse_event_history_on_user_id"
  end

  create_table "sleep_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_adverse_events_on_master_id"
    t.index ["user_id"], name: "index_sleep_adverse_events_on_user_id"
  end

  create_table "sleep_appointment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "interventionist"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_appointment_id"
    t.index ["master_id"], name: "index_sleep_appointment_history_on_master_id"
    t.index ["sleep_appointment_id"], name: "index_sleep_appointment_history_on_sleep_appointment_id"
    t.index ["user_id"], name: "index_sleep_appointment_history_on_user_id"
  end

  create_table "sleep_appointments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "interventionist"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_appointments_on_master_id"
    t.index ["user_id"], name: "index_sleep_appointments_on_user_id"
  end

  create_table "sleep_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "sleep_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_assignment_table_id"
    t.index ["admin_id"], name: "index_sleep_assignment_history_on_admin_id"
    t.index ["admin_id"], name: "index_sleep_assignment_history_on_admin_id"
    t.index ["master_id"], name: "index_sleep_assignment_history_on_master_id"
    t.index ["master_id"], name: "index_sleep_assignment_history_on_master_id"
    t.index ["sleep_assignment_table_id"], name: "index_sleep_assignment_history_on_sleep_assignment_table_id"
    t.index ["sleep_assignment_table_id"], name: "index_sleep_assignment_history_on_sleep_assignment_table_id"
    t.index ["user_id"], name: "index_sleep_assignment_history_on_user_id"
    t.index ["user_id"], name: "index_sleep_assignment_history_on_user_id"
  end

  create_table "sleep_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "sleep_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_assignment_table_id"
    t.index ["admin_id"], name: "index_sleep_assignment_history_on_admin_id"
    t.index ["admin_id"], name: "index_sleep_assignment_history_on_admin_id"
    t.index ["master_id"], name: "index_sleep_assignment_history_on_master_id"
    t.index ["master_id"], name: "index_sleep_assignment_history_on_master_id"
    t.index ["sleep_assignment_table_id"], name: "index_sleep_assignment_history_on_sleep_assignment_table_id"
    t.index ["sleep_assignment_table_id"], name: "index_sleep_assignment_history_on_sleep_assignment_table_id"
    t.index ["user_id"], name: "index_sleep_assignment_history_on_user_id"
    t.index ["user_id"], name: "index_sleep_assignment_history_on_user_id"
  end

  create_table "sleep_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "sleep_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_sleep_assignments_on_admin_id"
    t.index ["admin_id"], name: "index_sleep_assignments_on_admin_id"
    t.index ["master_id"], name: "index_sleep_assignments_on_master_id"
    t.index ["master_id"], name: "index_sleep_assignments_on_master_id"
    t.index ["user_id"], name: "index_sleep_assignments_on_user_id"
    t.index ["user_id"], name: "index_sleep_assignments_on_user_id"
  end

  create_table "sleep_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "sleep_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_sleep_assignments_on_admin_id"
    t.index ["admin_id"], name: "index_sleep_assignments_on_admin_id"
    t.index ["master_id"], name: "index_sleep_assignments_on_master_id"
    t.index ["master_id"], name: "index_sleep_assignments_on_master_id"
    t.index ["user_id"], name: "index_sleep_assignments_on_user_id"
    t.index ["user_id"], name: "index_sleep_assignments_on_user_id"
  end

  create_table "sleep_consent_mailing_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_consent_mailing_id"
    t.index ["master_id"], name: "index_sleep_consent_mailing_history_on_master_id"
    t.index ["sleep_consent_mailing_id"], name: "index_sleep_consent_mailing_history_on_sleep_consent_mailing_id"
    t.index ["user_id"], name: "index_sleep_consent_mailing_history_on_user_id"
  end

  create_table "sleep_consent_mailings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_consent_mailings_on_master_id"
    t.index ["user_id"], name: "index_sleep_consent_mailings_on_user_id"
  end

  create_table "sleep_ese_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sitting_and_reading"
    t.integer "watching_tv"
    t.integer "public_place"
    t.integer "car_passenger"
    t.integer "afternoon_rest"
    t.integer "sitting_and_talking"
    t.integer "after_lunch"
    t.integer "stopped_in_traffic"
    t.integer "total_score"
    t.integer "number_hours_sleep"
    t.string "ineligible_resource_yes_no"
    t.string "trust_assessment_info_yes_no"
    t.string "help_finding_pcp_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ese_question_id"
    t.index ["master_id"], name: "index_sleep_ese_question_history_on_master_id"
    t.index ["sleep_ese_question_id"], name: "index_sleep_ese_question_history_on_sleep_ese_question_id"
    t.index ["user_id"], name: "index_sleep_ese_question_history_on_user_id"
  end

  create_table "sleep_ese_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "sitting_and_reading"
    t.integer "watching_tv"
    t.integer "public_place"
    t.integer "car_passenger"
    t.integer "afternoon_rest"
    t.integer "sitting_and_talking"
    t.integer "after_lunch"
    t.integer "stopped_in_traffic"
    t.integer "total_score"
    t.integer "number_hours_sleep"
    t.string "ineligible_resource_yes_no"
    t.string "trust_assessment_info_yes_no"
    t.string "help_finding_pcp_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ese_questions_on_master_id"
    t.index ["user_id"], name: "index_sleep_ese_questions_on_user_id"
  end

  create_table "sleep_incidental_finding_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_incidental_finding_id"
    t.string "xray_notes"
    t.date "xray_date"
    t.boolean "xray_check"
    t.string "cardiac_notes"
    t.date "cardiac_date"
    t.boolean "cardiac_check"
    t.string "sleep_notes"
    t.date "sleep_date"
    t.boolean "sleep_check"
    t.string "eeg_notes"
    t.date "eeg_date"
    t.boolean "eeg_check"
    t.string "physical_function_notes"
    t.date "physical_function_date"
    t.boolean "physical_function_check"
    t.string "liver_mri_notes"
    t.date "liver_mri_date"
    t.boolean "liver_mri_check"
    t.string "sensory_testing_notes"
    t.date "sensory_testing_date"
    t.boolean "sensory_testing_check"
    t.string "neuro_psych_notes"
    t.date "neuro_psych_date"
    t.boolean "neuro_psych_check"
    t.string "brain_mri_notes"
    t.date "brain_mri_date"
    t.boolean "brain_mri_check"
    t.string "dexa_notes"
    t.date "dexa_date"
    t.boolean "dexa_check"
    t.string "lab_results_notes"
    t.date "lab_results_date"
    t.boolean "lab_results_check"
    t.string "anthropometrics_notes"
    t.date "anthropometrics_date"
    t.boolean "anthropometrics_check"
    t.index ["master_id"], name: "index_sleep_incidental_finding_history_on_master_id"
    t.index ["sleep_incidental_finding_id"], name: "index_sleep_incidental_finding_history_on_sleep_incidental_find"
    t.index ["user_id"], name: "index_sleep_incidental_finding_history_on_user_id"
  end

  create_table "sleep_incidental_findings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "xray_notes"
    t.date "xray_date"
    t.boolean "xray_check"
    t.string "cardiac_notes"
    t.date "cardiac_date"
    t.boolean "cardiac_check"
    t.string "sleep_notes"
    t.date "sleep_date"
    t.boolean "sleep_check"
    t.string "eeg_notes"
    t.date "eeg_date"
    t.boolean "eeg_check"
    t.string "physical_function_notes"
    t.date "physical_function_date"
    t.boolean "physical_function_check"
    t.string "liver_mri_notes"
    t.date "liver_mri_date"
    t.boolean "liver_mri_check"
    t.string "sensory_testing_notes"
    t.date "sensory_testing_date"
    t.boolean "sensory_testing_check"
    t.string "neuro_psych_notes"
    t.date "neuro_psych_date"
    t.boolean "neuro_psych_check"
    t.string "brain_mri_notes"
    t.date "brain_mri_date"
    t.boolean "brain_mri_check"
    t.string "dexa_notes"
    t.date "dexa_date"
    t.boolean "dexa_check"
    t.string "lab_results_notes"
    t.date "lab_results_date"
    t.boolean "lab_results_check"
    t.string "anthropometrics_notes"
    t.date "anthropometrics_date"
    t.boolean "anthropometrics_check"
    t.index ["master_id"], name: "index_sleep_incidental_findings_on_master_id"
    t.index ["user_id"], name: "index_sleep_incidental_findings_on_user_id"
  end

  create_table "sleep_inex_checklist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fixed_checklist_type"
    t.string "reliable_internet_yes_no"
    t.string "cbt_yes_no"
    t.string "cbt_how_long_ago"
    t.string "sleep_times_yes_no"
    t.string "work_night_shifts_yes_no"
    t.integer "number_times_per_week_work_night_shifts"
    t.string "narcolepsy_diagnosis_yes_no_dont_know"
    t.string "antiseizure_meds_yes_no"
    t.string "seizure_in_ten_years_yes_no"
    t.string "major_psychiatric_disorder_yes_no"
    t.integer "isi_total_score"
    t.string "sa_diagnosed_yes_no"
    t.string "sa_use_treatment_yes_no"
    t.string "sa_severity"
    t.integer "ese_total_score"
    t.integer "number_hours_sleep"
    t.integer "audit_c_total_score"
    t.string "alcohol_frequency"
    t.integer "number_days_negative_feeling_d2"
    t.integer "number_days_drug_usage_d2"
    t.integer "phq8_initial_score"
    t.integer "phq8_total_score"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "select_subject_eligibility"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_inex_checklist_id"
    t.string "conditions_yes_no"
    t.index ["master_id"], name: "index_sleep_inex_checklist_history_on_master_id"
    t.index ["sleep_inex_checklist_id"], name: "index_sleep_inex_checklist_history_on_sleep_inex_checklist_id"
    t.index ["user_id"], name: "index_sleep_inex_checklist_history_on_user_id"
  end

  create_table "sleep_inex_checklists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fixed_checklist_type"
    t.string "reliable_internet_yes_no"
    t.string "cbt_yes_no"
    t.string "cbt_how_long_ago"
    t.string "sleep_times_yes_no"
    t.string "work_night_shifts_yes_no"
    t.integer "number_times_per_week_work_night_shifts"
    t.string "narcolepsy_diagnosis_yes_no_dont_know"
    t.string "antiseizure_meds_yes_no"
    t.string "seizure_in_ten_years_yes_no"
    t.string "major_psychiatric_disorder_yes_no"
    t.integer "isi_total_score"
    t.string "sa_diagnosed_yes_no"
    t.string "sa_use_treatment_yes_no"
    t.string "sa_severity"
    t.integer "ese_total_score"
    t.integer "number_hours_sleep"
    t.integer "audit_c_total_score"
    t.string "alcohol_frequency"
    t.integer "number_days_negative_feeling_d2"
    t.integer "number_days_drug_usage_d2"
    t.integer "phq8_initial_score"
    t.integer "phq8_total_score"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "select_subject_eligibility"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "conditions_yes_no"
    t.index ["master_id"], name: "index_sleep_inex_checklists_on_master_id"
    t.index ["user_id"], name: "index_sleep_inex_checklists_on_user_id"
  end

  create_table "sleep_isi_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "falling_asleep"
    t.integer "staying_asleep"
    t.integer "waking_too_early"
    t.integer "satisfaction_with_pattern"
    t.integer "noticeable_to_others"
    t.integer "worried_distressed"
    t.integer "interferes_with_daily_function"
    t.integer "total_score"
    t.string "ineligible_assist_yes_no"
    t.string "trust_assessment_info_yes_no"
    t.string "help_finding_pcp_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_isi_question_id"
    t.index ["master_id"], name: "index_sleep_isi_question_history_on_master_id"
    t.index ["sleep_isi_question_id"], name: "index_sleep_isi_question_history_on_sleep_isi_question_id"
    t.index ["user_id"], name: "index_sleep_isi_question_history_on_user_id"
  end

  create_table "sleep_isi_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "falling_asleep"
    t.integer "staying_asleep"
    t.integer "waking_too_early"
    t.integer "satisfaction_with_pattern"
    t.integer "noticeable_to_others"
    t.integer "worried_distressed"
    t.integer "interferes_with_daily_function"
    t.integer "total_score"
    t.string "ineligible_assist_yes_no"
    t.string "trust_assessment_info_yes_no"
    t.string "help_finding_pcp_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_isi_questions_on_master_id"
    t.index ["user_id"], name: "index_sleep_isi_questions_on_user_id"
  end

  create_table "sleep_mednav_provider_comm_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_mednav_provider_comm_id"
    t.index ["master_id"], name: "index_sleep_mednav_provider_comm_history_on_master_id"
    t.index ["sleep_mednav_provider_comm_id"], name: "index_sleep_mednav_provider_comm_history_on_sleep_mednav_provid"
    t.index ["user_id"], name: "index_sleep_mednav_provider_comm_history_on_user_id"
  end

  create_table "sleep_mednav_provider_comms", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_mednav_provider_comms_on_master_id"
    t.index ["user_id"], name: "index_sleep_mednav_provider_comms_on_user_id"
  end

  create_table "sleep_mednav_provider_report_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "report_delivery_date"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_mednav_provider_report_id"
    t.index ["master_id"], name: "index_sleep_mednav_provider_report_history_on_master_id"
    t.index ["sleep_mednav_provider_report_id"], name: "index_sleep_mednav_provider_report_history_on_sleep_mednav_prov"
    t.index ["user_id"], name: "index_sleep_mednav_provider_report_history_on_user_id"
  end

  create_table "sleep_mednav_provider_reports", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "report_delivery_date"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_mednav_provider_reports_on_master_id"
    t.index ["user_id"], name: "index_sleep_mednav_provider_reports_on_user_id"
  end

  create_table "sleep_payment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_type"
    t.date "sent_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_payment_id"
    t.index ["master_id"], name: "index_sleep_payment_history_on_master_id"
    t.index ["sleep_payment_id"], name: "index_sleep_payment_history_on_sleep_payment_id"
    t.index ["user_id"], name: "index_sleep_payment_history_on_user_id"
  end

  create_table "sleep_payments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_type"
    t.date "sent_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_payments_on_master_id"
    t.index ["user_id"], name: "index_sleep_payments_on_user_id"
  end

  create_table "sleep_pi_follow_up_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "pre_call_notes"
    t.string "call_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_pi_follow_up_id"
    t.index ["master_id"], name: "index_sleep_pi_follow_up_history_on_master_id"
    t.index ["sleep_pi_follow_up_id"], name: "index_sleep_pi_follow_up_history_on_sleep_pi_follow_up_id"
    t.index ["user_id"], name: "index_sleep_pi_follow_up_history_on_user_id"
  end

  create_table "sleep_pi_follow_ups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "pre_call_notes"
    t.string "call_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_pi_follow_ups_on_master_id"
    t.index ["user_id"], name: "index_sleep_pi_follow_ups_on_user_id"
  end

  create_table "sleep_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_protocol_deviation_id"
    t.index ["master_id"], name: "index_sleep_protocol_deviation_history_on_master_id"
    t.index ["sleep_protocol_deviation_id"], name: "index_sleep_protocol_deviation_history_on_sleep_protocol_deviat"
    t.index ["user_id"], name: "index_sleep_protocol_deviation_history_on_user_id"
  end

  create_table "sleep_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_protocol_deviations_on_master_id"
    t.index ["user_id"], name: "index_sleep_protocol_deviations_on_user_id"
  end

  create_table "sleep_protocol_exception_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_protocol_exception_id"
    t.index ["master_id"], name: "index_sleep_protocol_exception_history_on_master_id"
    t.index ["sleep_protocol_exception_id"], name: "index_sleep_protocol_exception_history_on_sleep_protocol_except"
    t.index ["user_id"], name: "index_sleep_protocol_exception_history_on_user_id"
  end

  create_table "sleep_protocol_exceptions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_protocol_exceptions_on_master_id"
    t.index ["user_id"], name: "index_sleep_protocol_exceptions_on_user_id"
  end

  create_table "sleep_ps2_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "review_consent_now_yes_no"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps2_eligible_id"
    t.index ["master_id"], name: "index_sleep_ps2_eligible_history_on_master_id"
    t.index ["sleep_ps2_eligible_id"], name: "index_sleep_ps2_eligible_history_on_sleep_ps2_eligible_id"
    t.index ["user_id"], name: "index_sleep_ps2_eligible_history_on_user_id"
  end

  create_table "sleep_ps2_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "review_consent_now_yes_no"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps2_eligibles_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps2_eligibles_on_user_id"
  end

  create_table "sleep_ps2_initial_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.date "follow_up_date"
    t.string "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps2_initial_screening_id"
    t.string "select_still_interested"
    t.index ["master_id"], name: "index_sleep_ps2_initial_screening_history_on_master_id"
    t.index ["sleep_ps2_initial_screening_id"], name: "index_sleep_ps2_initial_screening_history_on_sleep_ps2_initial_"
    t.index ["user_id"], name: "index_sleep_ps2_initial_screening_history_on_user_id"
  end

  create_table "sleep_ps2_initial_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.date "follow_up_date"
    t.string "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_still_interested"
    t.index ["master_id"], name: "index_sleep_ps2_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps2_initial_screenings_on_user_id"
  end

  create_table "sleep_ps2_non_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "questions_for_pi_yes_no"
    t.string "questions_for_pi_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps2_non_eligible_id"
    t.index ["master_id"], name: "index_sleep_ps2_non_eligible_history_on_master_id"
    t.index ["sleep_ps2_non_eligible_id"], name: "index_sleep_ps2_non_eligible_history_on_sleep_ps2_non_eligible_"
    t.index ["user_id"], name: "index_sleep_ps2_non_eligible_history_on_user_id"
  end

  create_table "sleep_ps2_non_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "questions_for_pi_yes_no"
    t.string "questions_for_pi_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps2_non_eligibles_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps2_non_eligibles_on_user_id"
  end

  create_table "sleep_ps2_phq8_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "little_interest"
    t.integer "feeling_down"
    t.integer "initial_score"
    t.integer "trouble_sleeping"
    t.integer "feeling_tired"
    t.integer "poor_appetite"
    t.integer "feeling_bad"
    t.integer "trouble_concentrating"
    t.integer "acting_slowly_or_restlessly"
    t.integer "total_score"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps2_phq8_question_id"
    t.index ["master_id"], name: "index_sleep_ps2_phq8_question_history_on_master_id"
    t.index ["sleep_ps2_phq8_question_id"], name: "index_sleep_ps2_phq8_question_history_on_sleep_ps2_phq8_questio"
    t.index ["user_id"], name: "index_sleep_ps2_phq8_question_history_on_user_id"
  end

  create_table "sleep_ps2_phq8_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "little_interest"
    t.integer "feeling_down"
    t.integer "initial_score"
    t.integer "trouble_sleeping"
    t.integer "feeling_tired"
    t.integer "poor_appetite"
    t.integer "feeling_bad"
    t.integer "trouble_concentrating"
    t.integer "acting_slowly_or_restlessly"
    t.integer "total_score"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps2_phq8_questions_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps2_phq8_questions_on_user_id"
  end

  create_table "sleep_ps_audit_c_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "alcohol_frequency"
    t.string "daily_alcohol"
    t.string "six_or_more_frequency"
    t.string "total_score"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_audit_c_question_id"
    t.index ["master_id"], name: "index_sleep_ps_audit_c_question_history_on_master_id"
    t.index ["sleep_ps_audit_c_question_id"], name: "index_sleep_ps_audit_c_question_history_on_sleep_ps_audit_c_que"
    t.index ["user_id"], name: "index_sleep_ps_audit_c_question_history_on_user_id"
  end

  create_table "sleep_ps_audit_c_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "alcohol_frequency"
    t.string "daily_alcohol"
    t.string "six_or_more_frequency"
    t.string "total_score"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_audit_c_questions_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_audit_c_questions_on_user_id"
  end

  create_table "sleep_ps_basic_response_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "reliable_internet_yes_no"
    t.string "cbt_yes_no"
    t.string "cbt_how_long_ago"
    t.string "cbt_notes"
    t.string "sleep_times_yes_no"
    t.string "sleep_times_notes"
    t.string "work_night_shifts_yes_no"
    t.integer "number_times_per_week_work_night_shifts"
    t.string "narcolepsy_diagnosis_yes_no_dont_know"
    t.string "narcolepsy_diagnosis_notes"
    t.string "antiseizure_meds_yes_no"
    t.string "seizure_in_ten_years_yes_no"
    t.string "major_psychiatric_disorder_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_basic_response_id"
    t.string "conditions_yes_no"
    t.string "conditions_notes"
    t.index ["master_id"], name: "index_sleep_ps_basic_response_history_on_master_id"
    t.index ["sleep_ps_basic_response_id"], name: "index_sleep_ps_basic_response_history_on_sleep_ps_basic_respons"
    t.index ["user_id"], name: "index_sleep_ps_basic_response_history_on_user_id"
  end

  create_table "sleep_ps_basic_responses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "reliable_internet_yes_no"
    t.string "cbt_yes_no"
    t.string "cbt_how_long_ago"
    t.string "cbt_notes"
    t.string "sleep_times_yes_no"
    t.string "sleep_times_notes"
    t.string "work_night_shifts_yes_no"
    t.integer "number_times_per_week_work_night_shifts"
    t.string "narcolepsy_diagnosis_yes_no_dont_know"
    t.string "narcolepsy_diagnosis_notes"
    t.string "antiseizure_meds_yes_no"
    t.string "seizure_in_ten_years_yes_no"
    t.string "major_psychiatric_disorder_yes_no"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "conditions_yes_no"
    t.string "conditions_notes"
    t.index ["master_id"], name: "index_sleep_ps_basic_responses_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_basic_responses_on_user_id"
  end

  create_table "sleep_ps_dast2_mod_question_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "number_days_negative_feeling"
    t.integer "number_days_drug_usage"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.string "audit_c_eligible_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_dast2_mod_question_id"
    t.index ["master_id"], name: "index_sleep_ps_dast2_mod_question_history_on_master_id"
    t.index ["sleep_ps_dast2_mod_question_id"], name: "index_sleep_ps_dast2_mod_question_history_on_sleep_ps_dast2_mod"
    t.index ["user_id"], name: "index_sleep_ps_dast2_mod_question_history_on_user_id"
  end

  create_table "sleep_ps_dast2_mod_questions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "number_days_negative_feeling"
    t.integer "number_days_drug_usage"
    t.string "possibly_eligible_yes_no"
    t.string "possibly_eligible_reason_notes"
    t.string "notes"
    t.string "audit_c_eligible_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_dast2_mod_questions_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_dast2_mod_questions_on_user_id"
  end

  create_table "sleep_ps_eligibility_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "any_questions_yes_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_eligibility_followup_id"
    t.index ["master_id"], name: "index_sleep_ps_eligibility_followup_history_on_master_id"
    t.index ["sleep_ps_eligibility_followup_id"], name: "index_sleep_ps_eligibility_followup_history_on_sleep_ps_eligibi"
    t.index ["user_id"], name: "index_sleep_ps_eligibility_followup_history_on_user_id"
  end

  create_table "sleep_ps_eligibility_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "any_questions_yes_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_eligibility_followups_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_eligibility_followups_on_user_id"
  end

  create_table "sleep_ps_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_eligible_id"
    t.index ["master_id"], name: "index_sleep_ps_eligible_history_on_master_id"
    t.index ["sleep_ps_eligible_id"], name: "index_sleep_ps_eligible_history_on_sleep_ps_eligible_id"
    t.index ["user_id"], name: "index_sleep_ps_eligible_history_on_user_id"
  end

  create_table "sleep_ps_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "interested_yes_no"
    t.string "not_interested_notes"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_eligibles_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_eligibles_on_user_id"
  end

  create_table "sleep_ps_initial_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_initial_screening_id"
    t.string "select_may_i_begin"
    t.string "looked_at_website_yes_no"
    t.index ["master_id"], name: "index_sleep_ps_initial_screening_history_on_master_id"
    t.index ["sleep_ps_initial_screening_id"], name: "index_sleep_ps_initial_screening_history_on_sleep_ps_initial_sc"
    t.index ["user_id"], name: "index_sleep_ps_initial_screening_history_on_user_id"
  end

  create_table "sleep_ps_initial_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "any_questions_blank_yes_no"
    t.string "question_notes"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_may_i_begin"
    t.string "looked_at_website_yes_no"
    t.index ["master_id"], name: "index_sleep_ps_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_initial_screenings_on_user_id"
  end

  create_table "sleep_ps_non_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_non_eligible_id"
    t.index ["master_id"], name: "index_sleep_ps_non_eligible_history_on_master_id"
    t.index ["sleep_ps_non_eligible_id"], name: "index_sleep_ps_non_eligible_history_on_sleep_ps_non_eligible_id"
    t.index ["user_id"], name: "index_sleep_ps_non_eligible_history_on_user_id"
  end

  create_table "sleep_ps_non_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "contact_pi_yes_no"
    t.string "additional_questions_yes_no"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_non_eligibles_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_non_eligibles_on_user_id"
  end

  create_table "sleep_ps_possibly_eligible_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_possibly_eligible_id"
    t.time "follow_up_time"
    t.date "follow_up_date"
    t.index ["master_id"], name: "index_sleep_ps_possibly_eligible_history_on_master_id"
    t.index ["sleep_ps_possibly_eligible_id"], name: "index_sleep_ps_possibly_eligible_history_on_sleep_ps_possibly_e"
    t.index ["user_id"], name: "index_sleep_ps_possibly_eligible_history_on_user_id"
  end

  create_table "sleep_ps_possibly_eligibles", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "any_questions_yes_no"
    t.string "consent_to_pass_info_to_bwh_yes_no"
    t.string "consent_to_pass_info_to_bwh_2_yes_no"
    t.string "contact_info_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "follow_up_time"
    t.date "follow_up_date"
    t.index ["master_id"], name: "index_sleep_ps_possibly_eligibles_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_possibly_eligibles_on_user_id"
  end

  create_table "sleep_ps_screener_response_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "comm_clearly_in_english_yes_no"
    t.string "give_informed_consent_yes_no_dont_know"
    t.string "give_informed_consent_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_screener_response_id"
    t.index ["master_id"], name: "index_sleep_ps_screener_response_history_on_master_id"
    t.index ["sleep_ps_screener_response_id"], name: "index_sleep_ps_screener_response_history_on_sleep_ps_screener_r"
    t.index ["user_id"], name: "index_sleep_ps_screener_response_history_on_user_id"
  end

  create_table "sleep_ps_screener_responses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "outcome"
    t.string "comm_clearly_in_english_yes_no"
    t.string "give_informed_consent_yes_no_dont_know"
    t.string "give_informed_consent_notes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_screener_responses_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_screener_responses_on_user_id"
  end

  create_table "sleep_ps_sleep_apnea_response_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "diagnosed_yes_no"
    t.string "use_treatment_yes_no"
    t.string "severity"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_sleep_apnea_response_id"
    t.string "possibly_eligible_yes_no"
    t.index ["master_id"], name: "index_sleep_ps_sleep_apnea_response_history_on_master_id"
    t.index ["sleep_ps_sleep_apnea_response_id"], name: "index_sleep_ps_sleep_apnea_response_history_on_sleep_ps_sleep_a"
    t.index ["user_id"], name: "index_sleep_ps_sleep_apnea_response_history_on_user_id"
  end

  create_table "sleep_ps_sleep_apnea_responses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "diagnosed_yes_no"
    t.string "use_treatment_yes_no"
    t.string "severity"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "possibly_eligible_yes_no"
    t.index ["master_id"], name: "index_sleep_ps_sleep_apnea_responses_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_sleep_apnea_responses_on_user_id"
  end

  create_table "sleep_ps_subject_contact_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_ps_subject_contact_id"
    t.index ["master_id"], name: "index_sleep_ps_subject_contact_history_on_master_id"
    t.index ["sleep_ps_subject_contact_id"], name: "index_sleep_ps_subject_contact_history_on_sleep_ps_subject_cont"
    t.index ["user_id"], name: "index_sleep_ps_subject_contact_history_on_user_id"
  end

  create_table "sleep_ps_subject_contacts", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_ps_subject_contacts_on_master_id"
    t.index ["user_id"], name: "index_sleep_ps_subject_contacts_on_user_id"
  end

  create_table "sleep_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.string "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "consent_performed_yes_no"
    t.string "did_subject_consent_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_screening_id"
    t.string "notes"
    t.string "requires_study_partner_blank_yes_no"
    t.index ["master_id"], name: "index_sleep_screening_history_on_master_id"
    t.index ["sleep_screening_id"], name: "index_sleep_screening_history_on_sleep_screening_id"
    t.index ["user_id"], name: "index_sleep_screening_history_on_user_id"
  end

  create_table "sleep_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.string "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.string "consent_performed_yes_no"
    t.string "did_subject_consent_yes_no"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notes"
    t.string "requires_study_partner_blank_yes_no"
    t.index ["master_id"], name: "index_sleep_screenings_on_master_id"
    t.index ["user_id"], name: "index_sleep_screenings_on_user_id"
  end

  create_table "sleep_withdrawal_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_withdrawal_id"
    t.index ["master_id"], name: "index_sleep_withdrawal_history_on_master_id"
    t.index ["sleep_withdrawal_id"], name: "index_sleep_withdrawal_history_on_sleep_withdrawal_id"
    t.index ["user_id"], name: "index_sleep_withdrawal_history_on_user_id"
  end

  create_table "sleep_withdrawals", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_sleep_withdrawals_on_master_id"
    t.index ["user_id"], name: "index_sleep_withdrawals_on_user_id"
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

  create_table "subjects", id: false, force: :cascade do |t|
    t.integer "master_id"
    t.integer "subject_id"
  end

  create_table "sync_statuses", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "from_db"
    t.integer "from_master_id"
    t.string "to_db"
    t.integer "to_master_id"
    t.string "select_status", default: "new"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "external_id"
    t.string "external_type"
    t.string "event"
  end

  create_table "tbs_adl_informant_screener_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_regarding_eating"
    t.string "select_regarding_walking"
    t.string "select_regarding_bowel_and_bladder"
    t.string "select_regarding_bathing"
    t.string "select_regarding_grooming"
    t.string "select_regarding_dressing"
    t.string "select_regarding_dressing_performance"
    t.string "select_regarding_getting_dressed"
    t.string "used_telephone_yes_no_dont_know"
    t.string "select_telephone_performance"
    t.string "watched_tv_yes_no_dont_know"
    t.string "selected_programs_yes_no_dont_know"
    t.string "talk_about_content_during_yes_no_dont_know"
    t.string "talk_about_content_after_yes_no_dont_know"
    t.string "pay_attention_to_conversation_yes_no_dont_know"
    t.string "select_degree_of_participation"
    t.string "clear_dishes_yes_no_dont_know"
    t.string "select_clear_dishes_performance"
    t.string "find_personal_belongings_yes_no_dont_know"
    t.string "select_find_personal_belongings_performance"
    t.string "obtain_beverage_yes_no_dont_know"
    t.string "select_obtain_beverage_performance"
    t.string "make_meal_yes_no_dont_know"
    t.string "select_make_meal_performance"
    t.string "dispose_of_garbage_yes_no_dont_know"
    t.string "select_dispose_of_garbage_performance"
    t.string "get_around_outside_yes_no_dont_know"
    t.string "select_get_around_outside_performance"
    t.string "go_shopping_yes_no_dont_know"
    t.string "select_go_shopping_performance"
    t.string "pay_for_items_yes_no_dont_know"
    t.string "keep_appointments_yes_no_dont_know"
    t.string "select_keep_appointments_performance"
    t.string "institutionalized_no_yes"
    t.string "left_on_own_yes_no_dont_know"
    t.string "away_from_home_yes_no_dont_know"
    t.string "at_home_more_than_hour_yes_no_dont_know"
    t.string "at_home_less_than_hour_yes_no_dont_know"
    t.string "talk_about_current_events_yes_no_dont_know"
    t.string "did_not_take_part_in_yes_no_dont_know"
    t.string "took_part_in_outside_home_yes_no_dont_know"
    t.string "took_part_in_at_home_yes_no_dont_know"
    t.string "read_yes_no_dont_know"
    t.string "talk_about_reading_shortly_after_yes_no_dont_know"
    t.string "talk_about_reading_later_yes_no_dont_know"
    t.string "write_yes_no_dont_know"
    t.string "select_write_performance"
    t.string "pastime_yes_no_dont_know"
    t.string "multi_select_pastimes", array: true
    t.string "pastime_other"
    t.string "pastimes_only_at_daycare_no_yes"
    t.string "select_pastimes_only_at_daycare_performance"
    t.string "use_household_appliance_yes_no_dont_know"
    t.string "multi_select_household_appliances", array: true
    t.string "household_appliance_other"
    t.string "select_household_appliance_performance"
    t.integer "npi_infor"
    t.string "npi_inforsp"
    t.integer "npi_delus"
    t.integer "npi_delussev"
    t.integer "npi_hallu"
    t.integer "npi_hallusev"
    t.integer "npi_agita"
    t.integer "npi_agitasev"
    t.integer "npi_depre"
    t.integer "npi_depresev"
    t.integer "npi_anxie"
    t.integer "npi_anxiesev"
    t.integer "npi_elati"
    t.integer "npi_elatisev"
    t.integer "npi_apath"
    t.integer "npi_apathsev"
    t.integer "npi_disin"
    t.integer "npi_disinsev"
    t.integer "npi_irrit"
    t.integer "npi_irritsev"
    t.integer "npi_motor"
    t.integer "npi_motorsev"
    t.integer "npi_night"
    t.integer "npi_nightsev"
    t.integer "npi_appet"
    t.integer "npi_appetsev"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_adl_informant_screener_id"
    t.index ["master_id"], name: "index_tbs_adl_informant_screener_history_on_master_id"
    t.index ["tbs_adl_informant_screener_id"], name: "index_tbs_adl_informant_screener_history_on_tbs_adl_informant_s"
    t.index ["user_id"], name: "index_tbs_adl_informant_screener_history_on_user_id"
  end

  create_table "tbs_adl_informant_screeners", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_regarding_eating"
    t.string "select_regarding_walking"
    t.string "select_regarding_bowel_and_bladder"
    t.string "select_regarding_bathing"
    t.string "select_regarding_grooming"
    t.string "select_regarding_dressing"
    t.string "select_regarding_dressing_performance"
    t.string "select_regarding_getting_dressed"
    t.string "used_telephone_yes_no_dont_know"
    t.string "select_telephone_performance"
    t.string "watched_tv_yes_no_dont_know"
    t.string "selected_programs_yes_no_dont_know"
    t.string "talk_about_content_during_yes_no_dont_know"
    t.string "talk_about_content_after_yes_no_dont_know"
    t.string "pay_attention_to_conversation_yes_no_dont_know"
    t.string "select_degree_of_participation"
    t.string "clear_dishes_yes_no_dont_know"
    t.string "select_clear_dishes_performance"
    t.string "find_personal_belongings_yes_no_dont_know"
    t.string "select_find_personal_belongings_performance"
    t.string "obtain_beverage_yes_no_dont_know"
    t.string "select_obtain_beverage_performance"
    t.string "make_meal_yes_no_dont_know"
    t.string "select_make_meal_performance"
    t.string "dispose_of_garbage_yes_no_dont_know"
    t.string "select_dispose_of_garbage_performance"
    t.string "get_around_outside_yes_no_dont_know"
    t.string "select_get_around_outside_performance"
    t.string "go_shopping_yes_no_dont_know"
    t.string "select_go_shopping_performance"
    t.string "pay_for_items_yes_no_dont_know"
    t.string "keep_appointments_yes_no_dont_know"
    t.string "select_keep_appointments_performance"
    t.string "institutionalized_no_yes"
    t.string "left_on_own_yes_no_dont_know"
    t.string "away_from_home_yes_no_dont_know"
    t.string "at_home_more_than_hour_yes_no_dont_know"
    t.string "at_home_less_than_hour_yes_no_dont_know"
    t.string "talk_about_current_events_yes_no_dont_know"
    t.string "did_not_take_part_in_yes_no_dont_know"
    t.string "took_part_in_outside_home_yes_no_dont_know"
    t.string "took_part_in_at_home_yes_no_dont_know"
    t.string "read_yes_no_dont_know"
    t.string "talk_about_reading_shortly_after_yes_no_dont_know"
    t.string "talk_about_reading_later_yes_no_dont_know"
    t.string "write_yes_no_dont_know"
    t.string "select_write_performance"
    t.string "pastime_yes_no_dont_know"
    t.string "multi_select_pastimes", array: true
    t.string "pastime_other"
    t.string "pastimes_only_at_daycare_no_yes"
    t.string "select_pastimes_only_at_daycare_performance"
    t.string "use_household_appliance_yes_no_dont_know"
    t.string "multi_select_household_appliances", array: true
    t.string "household_appliance_other"
    t.string "select_household_appliance_performance"
    t.integer "npi_infor"
    t.string "npi_inforsp"
    t.integer "npi_delus"
    t.integer "npi_delussev"
    t.integer "npi_hallu"
    t.integer "npi_hallusev"
    t.integer "npi_agita"
    t.integer "npi_agitasev"
    t.integer "npi_depre"
    t.integer "npi_depresev"
    t.integer "npi_anxie"
    t.integer "npi_anxiesev"
    t.integer "npi_elati"
    t.integer "npi_elatisev"
    t.integer "npi_apath"
    t.integer "npi_apathsev"
    t.integer "npi_disin"
    t.integer "npi_disinsev"
    t.integer "npi_irrit"
    t.integer "npi_irritsev"
    t.integer "npi_motor"
    t.integer "npi_motorsev"
    t.integer "npi_night"
    t.integer "npi_nightsev"
    t.integer "npi_appet"
    t.integer "npi_appetsev"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_adl_informant_screeners_on_master_id"
    t.index ["user_id"], name: "index_tbs_adl_informant_screeners_on_user_id"
  end

  create_table "tbs_adl_screener_data", id: :serial, force: :cascade do |t|
    t.decimal "record_id"
    t.decimal "redcap_survey_identifier"
    t.datetime "adcs_npiq_timestamp"
    t.decimal "adlnpi_consent___agree"
    t.decimal "informant"
    t.decimal "adl_eat"
    t.decimal "adl_walk"
    t.decimal "adl_toilet"
    t.decimal "adl_bath"
    t.decimal "adl_groom"
    t.decimal "adl_dressa"
    t.decimal "adl_dressa_perf"
    t.decimal "adl_dressb"
    t.decimal "adl_phone"
    t.decimal "adl_phone_perf"
    t.decimal "adl_tv"
    t.decimal "adl_tva"
    t.decimal "adl_tvb"
    t.decimal "adl_tvc"
    t.decimal "adl_attnconvo"
    t.decimal "adl_attnconvo_part"
    t.decimal "adl_dishes"
    t.decimal "adl_dishes_perf"
    t.decimal "adl_belong"
    t.decimal "adl_belong_perf"
    t.decimal "adl_beverage"
    t.decimal "adl_beverage_perf"
    t.decimal "adl_snack"
    t.decimal "adl_snack_prep"
    t.decimal "adl_garbage"
    t.decimal "adl_garbage_perf"
    t.decimal "adl_travel"
    t.decimal "adl_travel_perf"
    t.decimal "adl_shop"
    t.decimal "adl_shop_select"
    t.decimal "adl_shop_pay"
    t.decimal "adl_appt"
    t.decimal "adl_appt_aware"
    t.decimal "institutionalized___1"
    t.decimal "adl_alone"
    t.decimal "adl_alone_15m"
    t.decimal "adl_alone_gt1hr"
    t.decimal "adl_alone_lt1hr"
    t.decimal "adl_currev"
    t.decimal "adl_currev_tv"
    t.decimal "adl_currev_outhome"
    t.decimal "adl_currev_inhome"
    t.decimal "adl_read"
    t.decimal "adl_read_lt1hr"
    t.decimal "adl_read_gt1hr"
    t.decimal "adl_write"
    t.decimal "adl_write_complex"
    t.decimal "adl_hob"
    t.decimal "adl_hobls___gam"
    t.decimal "adl_hobls___bing"
    t.decimal "adl_hobls___instr"
    t.decimal "adl_hobls___read"
    t.decimal "adl_hobls___tenn"
    t.decimal "adl_hobls___cword"
    t.decimal "adl_hobls___knit"
    t.decimal "adl_hobls___gard"
    t.decimal "adl_hobls___wshop"
    t.decimal "adl_hobls___art"
    t.decimal "adl_hobls___sew"
    t.decimal "adl_hobls___golf"
    t.decimal "adl_hobls___fish"
    t.decimal "adl_hobls___oth"
    t.text "adl_hobls_oth"
    t.decimal "adl_hobdc___1"
    t.decimal "adl_hob_perf"
    t.decimal "adl_appl"
    t.decimal "adl_applls___wash"
    t.decimal "adl_applls___dish"
    t.decimal "adl_applls___range"
    t.decimal "adl_applls___dry"
    t.decimal "adl_applls___toast"
    t.decimal "adl_applls___micro"
    t.decimal "adl_applls___vac"
    t.decimal "adl_applls___toven"
    t.decimal "adl_applls___fproc"
    t.decimal "adl_applls___oth"
    t.text "adl_applls_oth"
    t.decimal "adl_appl_perf"
    t.text "adl_comm"
    t.decimal "npi_infor"
    t.text "npi_inforsp"
    t.decimal "npi_delus"
    t.decimal "npi_delussev"
    t.decimal "npi_hallu"
    t.decimal "npi_hallusev"
    t.decimal "npi_agita"
    t.decimal "npi_agitasev"
    t.decimal "npi_depre"
    t.decimal "npi_depresev"
    t.decimal "npi_anxie"
    t.decimal "npi_anxiesev"
    t.decimal "npi_elati"
    t.decimal "npi_elatisev"
    t.decimal "npi_apath"
    t.decimal "npi_apathsev"
    t.decimal "npi_disin"
    t.decimal "npi_disinsev"
    t.decimal "npi_irrit"
    t.decimal "npi_irritsev"
    t.decimal "npi_motor"
    t.decimal "npi_motorsev"
    t.decimal "npi_night"
    t.decimal "npi_nightsev"
    t.decimal "npi_appet"
    t.decimal "npi_appetsev"
    t.decimal "adcs_npiq_complete"
    t.decimal "score"
    t.decimal "dk_count"
  end

  create_table "tbs_adverse_event_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_adverse_event_id"
    t.index ["master_id"], name: "index_tbs_adverse_event_history_on_master_id"
    t.index ["tbs_adverse_event_id"], name: "index_tbs_adverse_event_history_on_tbs_adverse_event_id"
    t.index ["user_id"], name: "index_tbs_adverse_event_history_on_user_id"
  end

  create_table "tbs_adverse_events", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_problem_type"
    t.date "event_occurred_when"
    t.date "event_discovered_when"
    t.string "select_severity"
    t.string "select_location"
    t.string "select_expectedness"
    t.string "select_relatedness"
    t.string "event_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_adverse_events_on_master_id"
    t.index ["user_id"], name: "index_tbs_adverse_events_on_user_id"
  end

  create_table "tbs_appointment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_appointment_id"
    t.index ["master_id"], name: "index_tbs_appointment_history_on_master_id"
    t.index ["tbs_appointment_id"], name: "index_tbs_appointment_history_on_tbs_appointment_id"
    t.index ["user_id"], name: "index_tbs_appointment_history_on_user_id"
  end

  create_table "tbs_appointments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "visit_start_date"
    t.date "visit_end_date"
    t.string "select_status"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_appointments_on_master_id"
    t.index ["user_id"], name: "index_tbs_appointments_on_user_id"
    t.index ["visit_start_date"], name: "tbs_appointments_visit_start_date_key", unique: true
  end

  create_table "tbs_assignment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "tbs_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_assignment_table_id"
    t.index ["admin_id"], name: "index_tbs_assignment_history_on_admin_id"
    t.index ["master_id"], name: "index_tbs_assignment_history_on_master_id"
    t.index ["tbs_assignment_table_id"], name: "index_tbs_assignment_history_on_tbs_assignment_table_id"
    t.index ["user_id"], name: "index_tbs_assignment_history_on_user_id"
  end

  create_table "tbs_assignments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "tbs_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_tbs_assignments_on_admin_id"
    t.index ["master_id"], name: "index_tbs_assignments_on_master_id"
    t.index ["user_id"], name: "index_tbs_assignments_on_user_id"
  end

  create_table "tbs_consent_mailing_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_consent_mailing_id"
    t.index ["master_id"], name: "index_tbs_consent_mailing_history_on_master_id"
    t.index ["tbs_consent_mailing_id"], name: "index_tbs_consent_mailing_history_on_tbs_consent_mailing_id"
    t.index ["user_id"], name: "index_tbs_consent_mailing_history_on_user_id"
  end

  create_table "tbs_consent_mailings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_record_from_player_contact_email"
    t.string "select_record_from_addresses"
    t.date "sent_when"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_consent_mailings_on_master_id"
    t.index ["user_id"], name: "index_tbs_consent_mailings_on_user_id"
  end

  create_table "tbs_exit_interview_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "notes"
    t.string "labs_returned_yes_no"
    t.string "labs_notes"
    t.string "dexa_returned_yes_no"
    t.string "dexa_notes"
    t.string "brain_mri_returned_yes_no"
    t.string "brain_mri_notes"
    t.string "neuro_psych_returned_yes_no"
    t.string "neuro_psych_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_exit_interview_id"
    t.index ["master_id"], name: "index_tbs_exit_interview_history_on_master_id"
    t.index ["tbs_exit_interview_id"], name: "index_tbs_exit_interview_history_on_tbs_exit_interview_id"
    t.index ["user_id"], name: "index_tbs_exit_interview_history_on_user_id"
  end

  create_table "tbs_exit_interviews", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "notes"
    t.string "labs_returned_yes_no"
    t.string "labs_notes"
    t.string "dexa_returned_yes_no"
    t.string "dexa_notes"
    t.string "brain_mri_returned_yes_no"
    t.string "brain_mri_notes"
    t.string "neuro_psych_returned_yes_no"
    t.string "neuro_psych_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_exit_interviews_on_master_id"
    t.index ["user_id"], name: "index_tbs_exit_interviews_on_user_id"
  end

  create_table "tbs_four_wk_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "select_sensory_testing_returned"
    t.string "sensory_testing_notes"
    t.string "select_liver_mri_returned"
    t.string "liver_mri_notes"
    t.string "select_physical_function_returned"
    t.string "physical_function_notes"
    t.string "select_eeg_returned"
    t.string "eeg_notes"
    t.string "select_sleep_returned"
    t.string "sleep_notes"
    t.string "select_cardiology_returned"
    t.string "cardiology_notes"
    t.string "select_xray_returned"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_four_wk_followup_id"
    t.index ["master_id"], name: "index_tbs_four_wk_followup_history_on_master_id"
    t.index ["tbs_four_wk_followup_id"], name: "index_tbs_four_wk_followup_history_on_tbs_four_wk_followup_id"
    t.index ["user_id"], name: "index_tbs_four_wk_followup_history_on_user_id"
  end

  create_table "tbs_four_wk_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_all_results_returned"
    t.string "select_sensory_testing_returned"
    t.string "sensory_testing_notes"
    t.string "select_liver_mri_returned"
    t.string "liver_mri_notes"
    t.string "select_physical_function_returned"
    t.string "physical_function_notes"
    t.string "select_eeg_returned"
    t.string "eeg_notes"
    t.string "select_sleep_returned"
    t.string "sleep_notes"
    t.string "select_cardiology_returned"
    t.string "cardiology_notes"
    t.string "select_xray_returned"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_four_wk_followups_on_master_id"
    t.index ["user_id"], name: "index_tbs_four_wk_followups_on_user_id"
  end

  create_table "tbs_hotel_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "hotel"
    t.date "check_in_date"
    t.time "check_in_time"
    t.string "room_number"
    t.date "check_out_date"
    t.time "check_out_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_hotel_id"
    t.index ["master_id"], name: "index_tbs_hotel_history_on_master_id"
    t.index ["tbs_hotel_id"], name: "index_tbs_hotel_history_on_tbs_hotel_id"
    t.index ["user_id"], name: "index_tbs_hotel_history_on_user_id"
  end

  create_table "tbs_hotels", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "hotel"
    t.date "check_in_date"
    t.time "check_in_time"
    t.string "room_number"
    t.date "check_out_date"
    t.time "check_out_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_hotels_on_master_id"
    t.index ["user_id"], name: "index_tbs_hotels_on_user_id"
  end

  create_table "tbs_incidental_finding_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.date "anthropometrics_date"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.date "lab_results_date"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.date "dexa_date"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.date "brain_mri_date"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.date "neuro_psych_date"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.date "sensory_testing_date"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.date "liver_mri_date"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.date "physical_function_date"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.date "eeg_date"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.date "sleep_date"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.date "cardiac_date"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.date "xray_date"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_incidental_finding_id"
    t.index ["master_id"], name: "index_tbs_incidental_finding_history_on_master_id"
    t.index ["tbs_incidental_finding_id"], name: "index_tbs_incidental_finding_history_on_tbs_incidental_finding_"
    t.index ["user_id"], name: "index_tbs_incidental_finding_history_on_user_id"
  end

  create_table "tbs_incidental_findings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.date "anthropometrics_date"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.date "lab_results_date"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.date "dexa_date"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.date "brain_mri_date"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.date "neuro_psych_date"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.date "sensory_testing_date"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.date "liver_mri_date"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.date "physical_function_date"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.date "eeg_date"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.date "sleep_date"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.date "cardiac_date"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.date "xray_date"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_incidental_findings_on_master_id"
    t.index ["user_id"], name: "index_tbs_incidental_findings_on_user_id"
  end

  create_table "tbs_inex_checklist_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fixed_checklist_type"
    t.string "ix_consent_blank_yes_no"
    t.string "ix_consent_details"
    t.string "ix_not_pro_blank_yes_no"
    t.string "ix_not_pro_details"
    t.string "ix_age_range_blank_yes_no"
    t.string "ix_age_range_details"
    t.string "ix_weight_ok_blank_yes_no"
    t.string "ix_weight_ok_details"
    t.string "ix_no_seizure_blank_yes_no"
    t.string "ix_no_seizure_details"
    t.string "ix_no_device_impl_blank_yes_no"
    t.string "ix_no_device_impl_details"
    t.string "ix_no_ferromagnetic_impl_blank_yes_no"
    t.string "ix_no_ferromagnetic_impl_details"
    t.string "ix_diagnosed_sleep_apnea_blank_yes_no"
    t.string "ix_diagnosed_sleep_apnea_details"
    t.string "ix_diagnosed_heart_stroke_or_meds_blank_yes_no"
    t.string "ix_diagnosed_heart_stroke_or_meds_details"
    t.string "ix_chronic_pain_and_meds_blank_yes_no"
    t.string "ix_chronic_pain_and_meds_details"
    t.string "ix_tmoca_score_blank_yes_no"
    t.string "ix_tmoca_score_details"
    t.string "ix_no_hemophilia_blank_yes_no"
    t.string "ix_no_hemophilia_details"
    t.string "ix_raynauds_ok_blank_yes_no"
    t.string "ix_raynauds_ok_details"
    t.string "ix_mi_ok_blank_yes_no"
    t.string "ix_mi_ok_details"
    t.string "ix_bicycle_ok_blank_yes_no"
    t.string "ix_bicycle_ok_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_inex_checklist_id"
    t.string "select_subject_eligibility"
    t.index ["master_id"], name: "index_tbs_inex_checklist_history_on_master_id"
    t.index ["tbs_inex_checklist_id"], name: "index_tbs_inex_checklist_history_on_tbs_inex_checklist_id"
    t.index ["user_id"], name: "index_tbs_inex_checklist_history_on_user_id"
  end

  create_table "tbs_inex_checklists", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "fixed_checklist_type"
    t.string "ix_consent_blank_yes_no"
    t.string "ix_consent_details"
    t.string "ix_not_pro_blank_yes_no"
    t.string "ix_not_pro_details"
    t.string "ix_age_range_blank_yes_no"
    t.string "ix_age_range_details"
    t.string "ix_weight_ok_blank_yes_no"
    t.string "ix_weight_ok_details"
    t.string "ix_no_seizure_blank_yes_no"
    t.string "ix_no_seizure_details"
    t.string "ix_no_device_impl_blank_yes_no"
    t.string "ix_no_device_impl_details"
    t.string "ix_no_ferromagnetic_impl_blank_yes_no"
    t.string "ix_no_ferromagnetic_impl_details"
    t.string "ix_diagnosed_sleep_apnea_blank_yes_no"
    t.string "ix_diagnosed_sleep_apnea_details"
    t.string "ix_diagnosed_heart_stroke_or_meds_blank_yes_no"
    t.string "ix_diagnosed_heart_stroke_or_meds_details"
    t.string "ix_chronic_pain_and_meds_blank_yes_no"
    t.string "ix_chronic_pain_and_meds_details"
    t.string "ix_tmoca_score_blank_yes_no"
    t.string "ix_tmoca_score_details"
    t.string "ix_no_hemophilia_blank_yes_no"
    t.string "ix_no_hemophilia_details"
    t.string "ix_raynauds_ok_blank_yes_no"
    t.string "ix_raynauds_ok_details"
    t.string "ix_mi_ok_blank_yes_no"
    t.string "ix_mi_ok_details"
    t.string "ix_bicycle_ok_blank_yes_no"
    t.string "ix_bicycle_ok_details"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "select_subject_eligibility"
    t.index ["master_id"], name: "index_tbs_inex_checklists_on_master_id"
    t.index ["user_id"], name: "index_tbs_inex_checklists_on_user_id"
  end

  create_table "tbs_mednav_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_mednav_followup_id"
    t.index ["master_id"], name: "index_tbs_mednav_followup_history_on_master_id"
    t.index ["tbs_mednav_followup_id"], name: "index_tbs_mednav_followup_history_on_tbs_mednav_followup_id"
    t.index ["user_id"], name: "index_tbs_mednav_followup_history_on_user_id"
  end

  create_table "tbs_mednav_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_mednav_followups_on_master_id"
    t.index ["user_id"], name: "index_tbs_mednav_followups_on_user_id"
  end

  create_table "tbs_mednav_provider_comm_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_mednav_provider_comm_id"
    t.index ["master_id"], name: "index_tbs_mednav_provider_comm_history_on_master_id"
    t.index ["tbs_mednav_provider_comm_id"], name: "index_tbs_mednav_provider_comm_history_on_tbs_mednav_provider_c"
    t.index ["user_id"], name: "index_tbs_mednav_provider_comm_history_on_user_id"
  end

  create_table "tbs_mednav_provider_comms", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_mednav_provider_comms_on_master_id"
    t.index ["user_id"], name: "index_tbs_mednav_provider_comms_on_user_id"
  end

  create_table "tbs_mednav_provider_report_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "report_delivery_date"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_mednav_provider_report_id"
    t.index ["master_id"], name: "index_tbs_mednav_provider_report_history_on_master_id"
    t.index ["tbs_mednav_provider_report_id"], name: "index_tbs_mednav_provider_report_history_on_tbs_mednav_provider"
    t.index ["user_id"], name: "index_tbs_mednav_provider_report_history_on_user_id"
  end

  create_table "tbs_mednav_provider_reports", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "report_delivery_date"
    t.boolean "anthropometrics_check"
    t.string "anthropometrics_notes"
    t.boolean "lab_results_check"
    t.string "lab_results_notes"
    t.boolean "dexa_check"
    t.string "dexa_notes"
    t.boolean "brain_mri_check"
    t.string "brain_mri_notes"
    t.boolean "neuro_psych_check"
    t.string "neuro_psych_notes"
    t.boolean "sensory_testing_check"
    t.string "sensory_testing_notes"
    t.boolean "liver_mri_check"
    t.string "liver_mri_notes"
    t.boolean "physical_function_check"
    t.string "physical_function_notes"
    t.boolean "eeg_check"
    t.string "eeg_notes"
    t.boolean "sleep_check"
    t.string "sleep_notes"
    t.boolean "cardiac_check"
    t.string "cardiac_notes"
    t.boolean "xray_check"
    t.string "xray_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_mednav_provider_reports_on_master_id"
    t.index ["user_id"], name: "index_tbs_mednav_provider_reports_on_user_id"
  end

  create_table "tbs_payment_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_type"
    t.date "sent_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_payment_id"
    t.index ["master_id"], name: "index_tbs_payment_history_on_master_id"
    t.index ["tbs_payment_id"], name: "index_tbs_payment_history_on_tbs_payment_id"
    t.index ["user_id"], name: "index_tbs_payment_history_on_user_id"
  end

  create_table "tbs_payments", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_type"
    t.date "sent_date"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_payments_on_master_id"
    t.index ["user_id"], name: "index_tbs_payments_on_user_id"
  end

  create_table "tbs_protocol_deviation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_protocol_deviation_id"
    t.index ["master_id"], name: "index_tbs_protocol_deviation_history_on_master_id"
    t.index ["tbs_protocol_deviation_id"], name: "index_tbs_protocol_deviation_history_on_tbs_protocol_deviation_"
    t.index ["user_id"], name: "index_tbs_protocol_deviation_history_on_user_id"
  end

  create_table "tbs_protocol_deviations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "deviation_occurred_when"
    t.date "deviation_discovered_when"
    t.string "select_severity"
    t.string "deviation_description"
    t.string "corrective_action_description"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_protocol_deviations_on_master_id"
    t.index ["user_id"], name: "index_tbs_protocol_deviations_on_user_id"
  end

  create_table "tbs_protocol_exception_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_protocol_exception_id"
    t.index ["master_id"], name: "index_tbs_protocol_exception_history_on_master_id"
    t.index ["tbs_protocol_exception_id"], name: "index_tbs_protocol_exception_history_on_tbs_protocol_exception_"
    t.index ["user_id"], name: "index_tbs_protocol_exception_history_on_user_id"
  end

  create_table "tbs_protocol_exceptions", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "exception_date"
    t.string "exception_description"
    t.string "risks_and_benefits_notes"
    t.string "informed_consent_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_protocol_exceptions_on_master_id"
    t.index ["user_id"], name: "index_tbs_protocol_exceptions_on_user_id"
  end

  create_table "tbs_ps_informant_detail_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "relationship_to_participant"
    t.string "contact_information_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_ps_informant_detail_id"
    t.index ["master_id"], name: "index_tbs_ps_informant_detail_history_on_master_id"
    t.index ["tbs_ps_informant_detail_id"], name: "index_tbs_ps_informant_detail_history_on_tbs_ps_informant_detai"
    t.index ["user_id"], name: "index_tbs_ps_informant_detail_history_on_user_id"
  end

  create_table "tbs_ps_informant_details", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "relationship_to_participant"
    t.string "contact_information_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_ps_informant_details_on_master_id"
    t.index ["user_id"], name: "index_tbs_ps_informant_details_on_user_id"
  end

  create_table "tbs_ps_initial_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "looked_at_website_yes_no"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_ps_initial_screening_id"
    t.index ["master_id"], name: "index_tbs_ps_initial_screening_history_on_master_id"
    t.index ["tbs_ps_initial_screening_id"], name: "index_tbs_ps_initial_screening_history_on_tbs_ps_initial_screen"
    t.index ["user_id"], name: "index_tbs_ps_initial_screening_history_on_user_id"
  end

  create_table "tbs_ps_initial_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_is_good_time_to_speak"
    t.string "looked_at_website_yes_no"
    t.string "select_may_i_begin"
    t.string "any_questions_blank_yes_no"
    t.string "select_still_interested"
    t.date "follow_up_date"
    t.time "follow_up_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_ps_initial_screenings_on_master_id"
    t.index ["user_id"], name: "index_tbs_ps_initial_screenings_on_user_id"
  end

  create_table "tbs_screening_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "requires_study_partner_blank_yes_no"
    t.string "notes"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.string "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_screening_id"
    t.index ["master_id"], name: "index_tbs_screening_history_on_master_id"
    t.index ["tbs_screening_id"], name: "index_tbs_screening_history_on_tbs_screening_id"
    t.index ["user_id"], name: "index_tbs_screening_history_on_user_id"
  end

  create_table "tbs_screenings", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "eligible_for_study_blank_yes_no"
    t.string "requires_study_partner_blank_yes_no"
    t.string "notes"
    t.string "good_time_to_speak_blank_yes_no"
    t.date "callback_date"
    t.string "callback_time"
    t.string "still_interested_blank_yes_no"
    t.string "not_interested_notes"
    t.string "contact_in_future_yes_no"
    t.string "ineligible_notes"
    t.string "eligible_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_screenings_on_master_id"
    t.index ["user_id"], name: "index_tbs_screenings_on_user_id"
  end

  create_table "tbs_station_contact_history", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "select_availability"
    t.string "phone"
    t.string "alt_phone"
    t.string "email"
    t.string "alt_email"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_station_contact_id"
    t.index ["tbs_station_contact_id"], name: "index_tbs_station_contact_history_on_tbs_station_contact_id"
    t.index ["user_id"], name: "index_tbs_station_contact_history_on_user_id"
  end

  create_table "tbs_station_contacts", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "select_availability"
    t.string "phone"
    t.string "alt_phone"
    t.string "email"
    t.string "alt_email"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tbs_station_contacts_on_user_id"
  end

  create_table "tbs_survey_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_survey_type"
    t.date "sent_date"
    t.date "completed_date"
    t.date "send_next_survey_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_survey_id"
    t.index ["master_id"], name: "index_tbs_survey_history_on_master_id"
    t.index ["tbs_survey_id"], name: "index_tbs_survey_history_on_tbs_survey_id"
    t.index ["user_id"], name: "index_tbs_survey_history_on_user_id"
  end

  create_table "tbs_surveys", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_survey_type"
    t.date "sent_date"
    t.date "completed_date"
    t.date "send_next_survey_when"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_surveys_on_master_id"
    t.index ["user_id"], name: "index_tbs_surveys_on_user_id"
  end

  create_table "tbs_transportation_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "travel_date"
    t.string "travel_confirmed_no_yes"
    t.string "select_direction"
    t.string "origin_city_and_state"
    t.string "destination_city_and_state"
    t.string "select_mode_of_transport"
    t.string "airline"
    t.string "flight_number"
    t.string "departure_time"
    t.string "arrival_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_transportation_id"
    t.index ["master_id"], name: "index_tbs_transportation_history_on_master_id"
    t.index ["tbs_transportation_id"], name: "index_tbs_transportation_history_on_tbs_transportation_id"
    t.index ["user_id"], name: "index_tbs_transportation_history_on_user_id"
  end

  create_table "tbs_transportations", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.date "travel_date"
    t.string "travel_confirmed_no_yes"
    t.string "select_direction"
    t.string "origin_city_and_state"
    t.string "destination_city_and_state"
    t.string "select_mode_of_transport"
    t.string "airline"
    t.string "flight_number"
    t.string "departure_time"
    t.string "arrival_time"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_transportations_on_master_id"
    t.index ["user_id"], name: "index_tbs_transportations_on_user_id"
  end

  create_table "tbs_two_wk_followup_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "participant_had_qs_yes_no"
    t.string "participant_qs_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_two_wk_followup_id"
    t.index ["master_id"], name: "index_tbs_two_wk_followup_history_on_master_id"
    t.index ["tbs_two_wk_followup_id"], name: "index_tbs_two_wk_followup_history_on_tbs_two_wk_followup_id"
    t.index ["user_id"], name: "index_tbs_two_wk_followup_history_on_user_id"
  end

  create_table "tbs_two_wk_followups", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "participant_had_qs_yes_no"
    t.string "participant_qs_notes"
    t.string "assisted_finding_provider_yes_no"
    t.string "assistance_notes"
    t.string "other_notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_two_wk_followups_on_master_id"
    t.index ["user_id"], name: "index_tbs_two_wk_followups_on_user_id"
  end

  create_table "tbs_withdrawal_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tbs_withdrawal_id"
    t.index ["master_id"], name: "index_tbs_withdrawal_history_on_master_id"
    t.index ["tbs_withdrawal_id"], name: "index_tbs_withdrawal_history_on_tbs_withdrawal_id"
    t.index ["user_id"], name: "index_tbs_withdrawal_history_on_user_id"
  end

  create_table "tbs_withdrawals", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "select_subject_withdrew_reason"
    t.string "select_investigator_terminated"
    t.string "lost_to_follow_up_no_yes"
    t.string "no_longer_participating_no_yes"
    t.string "notes"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_tbs_withdrawals_on_master_id"
    t.index ["user_id"], name: "index_tbs_withdrawals_on_user_id"
  end

  create_table "test1_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "test1_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test1_table_id"
    t.index ["admin_id"], name: "index_test1_history_on_admin_id"
    t.index ["master_id"], name: "index_test1_history_on_master_id"
    t.index ["test1_table_id"], name: "index_test1_history_on_test1_table_id"
    t.index ["user_id"], name: "index_test1_history_on_user_id"
  end

  create_table "test1s", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "test1_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_test1s_on_admin_id"
    t.index ["master_id"], name: "index_test1s_on_master_id"
    t.index ["user_id"], name: "index_test1s_on_user_id"
  end

  create_table "test2_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "test_2ext_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test2_table_id"
    t.index ["admin_id"], name: "index_test2_history_on_admin_id"
    t.index ["master_id"], name: "index_test2_history_on_master_id"
    t.index ["test2_table_id"], name: "index_test2_history_on_test2_table_id"
    t.index ["user_id"], name: "index_test2_history_on_user_id"
  end

  create_table "test2s", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "test_2ext_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_test2s_on_admin_id"
    t.index ["master_id"], name: "index_test2s_on_master_id"
    t.index ["user_id"], name: "index_test2s_on_user_id"
  end

  create_table "test9_number_history", force: :cascade do |t|
    t.bigint "master_id"
    t.string "test9_id"
    t.bigint "user_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "test9_number_table_id_id"
    t.index ["admin_id"], name: "index_femfl.test9_number_history_on_admin_id"
    t.index ["master_id"], name: "index_femfl.test9_number_history_on_master_id"
    t.index ["test9_number_table_id_id"], name: "test9_number_id_idx"
    t.index ["user_id"], name: "index_femfl.test9_number_history_on_user_id"
  end

  create_table "test9_numbers", force: :cascade do |t|
    t.bigint "master_id"
    t.string "test9_id"
    t.bigint "user_id"
    t.bigint "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_femfl.test9_numbers_on_admin_id"
    t.index ["master_id"], name: "index_femfl.test9_numbers_on_master_id"
    t.index ["user_id"], name: "index_femfl.test9_numbers_on_user_id"
  end

  create_table "test_2_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "test_2ext_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_2_table_id"
    t.index ["admin_id"], name: "index_test_2_history_on_admin_id"
    t.index ["master_id"], name: "index_test_2_history_on_master_id"
    t.index ["test_2_table_id"], name: "index_test_2_history_on_test_2_table_id"
    t.index ["user_id"], name: "index_test_2_history_on_user_id"
  end

  create_table "test_2s", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "test_2ext_id"
    t.integer "user_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_test_2s_on_admin_id"
    t.index ["master_id"], name: "index_test_2s_on_master_id"
    t.index ["user_id"], name: "index_test_2s_on_user_id"
  end

  create_table "test_ext2_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "test_e2_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_ext2_table_id"
    t.index ["master_id"], name: "index_test_ext2_history_on_master_id"
    t.index ["test_ext2_table_id"], name: "index_test_ext2_history_on_test_ext2_table_id"
    t.index ["user_id"], name: "index_test_ext2_history_on_user_id"
  end

  create_table "test_ext2s", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "test_e2_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_test_ext2s_on_master_id"
    t.index ["user_id"], name: "index_test_ext2s_on_user_id"
  end

  create_table "test_ext_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "test_e_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "test_ext_table_id"
    t.index ["master_id"], name: "index_test_ext_history_on_master_id"
    t.index ["test_ext_table_id"], name: "index_test_ext_history_on_test_ext_table_id"
    t.index ["user_id"], name: "index_test_ext_history_on_user_id"
  end

  create_table "test_exts", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "test_e_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_test_exts_on_master_id"
    t.index ["user_id"], name: "index_test_exts_on_user_id"
  end

  create_table "test_item_history", id: :serial, force: :cascade do |t|
    t.integer "test_item_id"
    t.integer "master_id"
    t.bigint "external_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_test_item_history_on_master_id"
    t.index ["test_item_id"], name: "index_test_item_history_on_test_item_id"
    t.index ["user_id"], name: "index_test_item_history_on_user_id"
  end

  create_table "test_items", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.bigint "external_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_test_items_on_master_id"
    t.index ["user_id"], name: "index_test_items_on_user_id"
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
    t.integer "user_id", default: 0
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
    t.index ["app_type_id"], name: "index_user_history_on_app_type_id"
    t.index ["user_id"], name: "index_user_history_on_user_id"
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
    t.index ["admin_id"], name: "index_user_role_history_on_admin_id"
    t.index ["user_role_id"], name: "index_user_role_history_on_user_role_id"
    t.index ["user_role_id"], name: "index_user_role_history_on_user_role_id"
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
    t.index ["admin_id"], name: "index_user_role_history_on_admin_id"
    t.index ["user_role_id"], name: "index_user_role_history_on_user_role_id"
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
    t.index ["admin_id"], name: "index_users_on_admin_id"
    t.index ["app_type_id"], name: "index_users_on_app_type_id"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
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
    t.index ["admin_id"], name: "index_users_contact_infos_on_admin_id"
    t.index ["user_id"], name: "index_users_contact_infos_on_user_id"
    t.index ["user_id"], name: "index_users_contact_infos_on_user_id"
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
    t.index ["admin_id"], name: "index_users_contact_infos_on_admin_id"
    t.index ["user_id"], name: "index_users_contact_infos_on_user_id"
    t.index ["user_id"], name: "index_users_contact_infos_on_user_id"
  end

  create_table "zeus_bulk_message_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "name"
    t.string "notes"
    t.string "channel"
    t.string "message"
    t.date "send_date"
    t.time "send_time"
    t.string "status"
    t.string "cancel"
    t.string "ready"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zeus_bulk_message_id"
    t.index ["master_id"], name: "index_zeus_bulk_message_history_on_master_id"
    t.index ["user_id"], name: "index_zeus_bulk_message_history_on_user_id"
    t.index ["zeus_bulk_message_id"], name: "index_zeus_bulk_message_history_on_zeus_bulk_message_id"
  end

  create_table "zeus_bulk_message_recipient_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "record_type"
    t.bigint "record_id"
    t.string "data"
    t.string "rec_type"
    t.string "rank"
    t.boolean "disabled", default: false, null: false
    t.bigint "zeus_bulk_message_id"
    t.string "response"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zeus_bulk_message_recipient_id"
    t.index ["master_id"], name: "index_zeus_bulk_message_recipient_history_on_master_id"
    t.index ["user_id"], name: "index_zeus_bulk_message_recipient_history_on_user_id"
    t.index ["zeus_bulk_message_recipient_id"], name: "index_zeus_bulk_message_recipient_history_on_zeus_bulk_message_"
  end

  create_table "zeus_bulk_message_recipients", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "record_type"
    t.bigint "record_id"
    t.string "data"
    t.string "rec_type"
    t.string "rank"
    t.boolean "disabled", default: false, null: false
    t.bigint "zeus_bulk_message_id"
    t.string "response"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_zeus_bulk_message_recipients_on_master_id"
    t.index ["user_id"], name: "index_zeus_bulk_message_recipients_on_user_id"
    t.index ["zeus_bulk_message_id", "record_id"], name: "unique_recipient", unique: true, where: "(disabled = false)"
  end

  create_table "zeus_bulk_message_status_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "res_timestamp"
    t.string "message_id"
    t.string "status"
    t.string "status_reason"
    t.integer "zeus_bulk_message_recipient_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zeus_bulk_message_status_id"
    t.index ["master_id"], name: "index_zeus_bulk_message_status_history_on_master_id"
    t.index ["user_id"], name: "index_zeus_bulk_message_status_history_on_user_id"
    t.index ["zeus_bulk_message_status_id"], name: "index_zeus_bulk_message_status_history_on_zeus_bulk_message_sta"
  end

  create_table "zeus_bulk_message_statuses", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.integer "res_timestamp"
    t.string "message_id"
    t.string "status"
    t.string "status_reason"
    t.integer "zeus_bulk_message_recipient_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_zeus_bulk_message_statuses_on_master_id"
    t.index ["res_timestamp"], name: "index_zeus_bulk_message_statuses_on_ts"
    t.index ["user_id"], name: "index_zeus_bulk_message_statuses_on_user_id"
  end

  create_table "zeus_bulk_messages", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "name"
    t.string "notes"
    t.string "channel"
    t.string "message"
    t.date "send_date"
    t.time "send_time"
    t.string "status"
    t.string "cancel"
    t.string "ready"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_zeus_bulk_messages_on_master_id"
    t.index ["user_id"], name: "index_zeus_bulk_messages_on_user_id"
  end

  create_table "zeus_short_link_clicks", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "shortcode"
    t.string "domain"
    t.string "browser"
    t.string "logfile"
    t.datetime "action_timestamp", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["master_id"], name: "index_zeus_short_link_clicks_on_master_id"
    t.index ["user_id"], name: "index_zeus_short_link_clicks_on_user_id"
  end

  create_table "zeus_short_link_history", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "url"
    t.string "shortcode"
    t.integer "clicks", default: 0
    t.date "next_check_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zeus_short_link_id"
    t.string "domain"
    t.string "for_item_type"
    t.string "for_item_id"
    t.index ["master_id"], name: "index_zeus_short_link_history_on_master_id"
    t.index ["user_id"], name: "index_zeus_short_link_history_on_user_id"
    t.index ["zeus_short_link_id"], name: "index_zeus_short_link_history_on_zeus_short_link_id"
  end

  create_table "zeus_short_links", id: :serial, force: :cascade do |t|
    t.integer "master_id"
    t.string "url"
    t.string "shortcode"
    t.integer "clicks", default: 0
    t.date "next_check_date"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain"
    t.string "for_item_type"
    t.string "for_item_id"
    t.index ["master_id"], name: "index_zeus_short_links_on_master_id"
    t.index ["user_id"], name: "index_zeus_short_links_on_user_id"
  end

  add_foreign_key "accuracy_score_history", "accuracy_scores", name: "fk_accuracy_score_history_accuracy_scores"
  add_foreign_key "accuracy_scores", "admins"
  add_foreign_key "activity_log_bhs_assignment_history", "activity_log_bhs_assignments", name: "fk_activity_log_bhs_assignment_history_activity_log_bhs_assignm"
  add_foreign_key "activity_log_bhs_assignment_history", "bhs_assignments", name: "fk_activity_log_bhs_assignment_history_bhs_assignment_id"
  add_foreign_key "activity_log_bhs_assignment_history", "masters", name: "fk_activity_log_bhs_assignment_history_masters"
  add_foreign_key "activity_log_bhs_assignment_history", "users", name: "fk_activity_log_bhs_assignment_history_users"
  add_foreign_key "activity_log_bhs_assignments", "masters"
  add_foreign_key "activity_log_bhs_assignments", "users"
  add_foreign_key "activity_log_data_request_assignment_history", "activity_log_data_request_assignments", name: "fk_activity_log_data_request_assignment_history_activity_log_da"
  add_foreign_key "activity_log_data_request_assignment_history", "data_request_assignments", name: "fk_activity_log_data_request_assignment_history_data_request_as"
  add_foreign_key "activity_log_data_request_assignment_history", "masters", name: "fk_activity_log_data_request_assignment_history_masters"
  add_foreign_key "activity_log_data_request_assignment_history", "users", column: "created_by_user_id", name: "fk_activity_log_data_request_assignment_history_cb_users"
  add_foreign_key "activity_log_data_request_assignment_history", "users", name: "fk_activity_log_data_request_assignment_history_users"
  add_foreign_key "activity_log_data_request_assignments", "masters"
  add_foreign_key "activity_log_data_request_assignments", "users"
  add_foreign_key "activity_log_data_request_assignments", "users", column: "created_by_user_id", name: "fk_rails_982635401e0"
  add_foreign_key "activity_log_ext_assignment_history", "activity_log_ext_assignments", name: "fk_activity_log_ext_assignment_history_activity_log_ext_assignm"
  add_foreign_key "activity_log_ext_assignment_history", "ext_assignments", name: "fk_activity_log_ext_assignment_history_ext_assignment_id"
  add_foreign_key "activity_log_ext_assignment_history", "masters", name: "fk_activity_log_ext_assignment_history_masters"
  add_foreign_key "activity_log_ext_assignment_history", "users", name: "fk_activity_log_ext_assignment_history_users"
  add_foreign_key "activity_log_ext_assignments", "ext_assignments"
  add_foreign_key "activity_log_ext_assignments", "masters"
  add_foreign_key "activity_log_ext_assignments", "users"
  add_foreign_key "activity_log_femfl_assignment_femfl_comm_history", "activity_log_femfl_assignment_femfl_comms"
  add_foreign_key "activity_log_femfl_assignment_femfl_comm_history", "femfl_assignments"
  add_foreign_key "activity_log_femfl_assignment_femfl_comm_history", "masters"
  add_foreign_key "activity_log_femfl_assignment_femfl_comm_history", "users"
  add_foreign_key "activity_log_femfl_assignment_femfl_comms", "femfl_assignments"
  add_foreign_key "activity_log_femfl_assignment_femfl_comms", "masters"
  add_foreign_key "activity_log_femfl_assignment_femfl_comms", "users"
  add_foreign_key "activity_log_grit_assignment_adverse_event_history", "activity_log_grit_assignment_adverse_events", name: "fk_activity_log_grit_assignment_adverse_event_history_activity_"
  add_foreign_key "activity_log_grit_assignment_adverse_event_history", "grit.grit_assignments", column: "grit_assignment_id", name: "fk_activity_log_grit_assignment_adverse_event_history_grit_assi"
  add_foreign_key "activity_log_grit_assignment_adverse_event_history", "masters", name: "fk_activity_log_grit_assignment_adverse_event_history_masters"
  add_foreign_key "activity_log_grit_assignment_adverse_event_history", "users", name: "fk_activity_log_grit_assignment_adverse_event_history_users"
  add_foreign_key "activity_log_grit_assignment_adverse_events", "grit.grit_assignments", column: "grit_assignment_id"
  add_foreign_key "activity_log_grit_assignment_adverse_events", "masters"
  add_foreign_key "activity_log_grit_assignment_adverse_events", "users"
  add_foreign_key "activity_log_grit_assignment_discussion_history", "activity_log_grit_assignment_discussions", name: "fk_activity_log_grit_assignment_discussion_history_activity_log"
  add_foreign_key "activity_log_grit_assignment_discussion_history", "grit.grit_assignments", column: "grit_assignment_id", name: "fk_activity_log_grit_assignment_discussion_history_grit_assignm"
  add_foreign_key "activity_log_grit_assignment_discussion_history", "masters", name: "fk_activity_log_grit_assignment_discussion_history_masters"
  add_foreign_key "activity_log_grit_assignment_discussion_history", "users", name: "fk_activity_log_grit_assignment_discussion_history_users"
  add_foreign_key "activity_log_grit_assignment_discussions", "grit.grit_assignments", column: "grit_assignment_id"
  add_foreign_key "activity_log_grit_assignment_discussions", "masters"
  add_foreign_key "activity_log_grit_assignment_discussions", "users"
  add_foreign_key "activity_log_grit_assignment_followup_history", "activity_log_grit_assignment_followups", name: "fk_activity_log_grit_assignment_followup_history_activity_log_g"
  add_foreign_key "activity_log_grit_assignment_followup_history", "grit.grit_assignments", column: "grit_assignment_id", name: "fk_activity_log_grit_assignment_followup_history_grit_assignmen"
  add_foreign_key "activity_log_grit_assignment_followup_history", "masters", name: "fk_activity_log_grit_assignment_followup_history_masters"
  add_foreign_key "activity_log_grit_assignment_followup_history", "users", name: "fk_activity_log_grit_assignment_followup_history_users"
  add_foreign_key "activity_log_grit_assignment_followups", "grit.grit_assignments", column: "grit_assignment_id"
  add_foreign_key "activity_log_grit_assignment_followups", "masters"
  add_foreign_key "activity_log_grit_assignment_followups", "users"
  add_foreign_key "activity_log_grit_assignment_history", "activity_log_grit_assignments", name: "fk_activity_log_grit_assignment_history_activity_log_grit_assig"
  add_foreign_key "activity_log_grit_assignment_history", "grit.grit_assignments", column: "grit_assignment_id", name: "fk_activity_log_grit_assignment_history_grit_assignment_id"
  add_foreign_key "activity_log_grit_assignment_history", "masters", name: "fk_activity_log_grit_assignment_history_masters"
  add_foreign_key "activity_log_grit_assignment_history", "users", name: "fk_activity_log_grit_assignment_history_users"
  add_foreign_key "activity_log_grit_assignment_phone_screen_history", "activity_log_grit_assignment_phone_screens", name: "fk_activity_log_grit_assignment_phone_screen_history_activity_l"
  add_foreign_key "activity_log_grit_assignment_phone_screen_history", "grit.grit_assignments", column: "grit_assignment_id", name: "fk_activity_log_grit_assignment_phone_screen_history_grit_assig"
  add_foreign_key "activity_log_grit_assignment_phone_screen_history", "masters", name: "fk_activity_log_grit_assignment_phone_screen_history_masters"
  add_foreign_key "activity_log_grit_assignment_phone_screen_history", "users", name: "fk_activity_log_grit_assignment_phone_screen_history_users"
  add_foreign_key "activity_log_grit_assignment_phone_screens", "grit.grit_assignments", column: "grit_assignment_id"
  add_foreign_key "activity_log_grit_assignment_phone_screens", "masters"
  add_foreign_key "activity_log_grit_assignment_phone_screens", "users"
  add_foreign_key "activity_log_grit_assignment_protocol_deviation_history", "activity_log_grit_assignment_protocol_deviations", name: "fk_activity_log_grit_assignment_protocol_deviation_history_acti"
  add_foreign_key "activity_log_grit_assignment_protocol_deviation_history", "grit.grit_assignments", column: "grit_assignment_id", name: "fk_activity_log_grit_assignment_protocol_deviation_history_grit"
  add_foreign_key "activity_log_grit_assignment_protocol_deviation_history", "masters", name: "fk_activity_log_grit_assignment_protocol_deviation_history_mast"
  add_foreign_key "activity_log_grit_assignment_protocol_deviation_history", "users", name: "fk_activity_log_grit_assignment_protocol_deviation_history_user"
  add_foreign_key "activity_log_grit_assignment_protocol_deviations", "grit.grit_assignments", column: "grit_assignment_id"
  add_foreign_key "activity_log_grit_assignment_protocol_deviations", "masters"
  add_foreign_key "activity_log_grit_assignment_protocol_deviations", "users"
  add_foreign_key "activity_log_grit_assignments", "grit.grit_assignments", column: "grit_assignment_id"
  add_foreign_key "activity_log_grit_assignments", "masters"
  add_foreign_key "activity_log_grit_assignments", "users"
  add_foreign_key "activity_log_history", "activity_logs"
  add_foreign_key "activity_log_ipa_assignment_adverse_event_history", "activity_log_ipa_assignment_adverse_events", name: "fk_activity_log_ipa_assignment_adverse_event_history_activity_l"
  add_foreign_key "activity_log_ipa_assignment_adverse_event_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_adverse_event_history_ipa_assign"
  add_foreign_key "activity_log_ipa_assignment_adverse_event_history", "masters", name: "fk_activity_log_ipa_assignment_adverse_event_history_masters"
  add_foreign_key "activity_log_ipa_assignment_adverse_event_history", "users", name: "fk_activity_log_ipa_assignment_adverse_event_history_users"
  add_foreign_key "activity_log_ipa_assignment_adverse_events", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_adverse_events", "masters"
  add_foreign_key "activity_log_ipa_assignment_adverse_events", "users"
  add_foreign_key "activity_log_ipa_assignment_discussion_history", "activity_log_ipa_assignment_discussions", name: "fk_activity_log_ipa_assignment_discussion_history_activity_log_"
  add_foreign_key "activity_log_ipa_assignment_discussion_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_discussion_history_ipa_assignmen"
  add_foreign_key "activity_log_ipa_assignment_discussion_history", "masters", name: "fk_activity_log_ipa_assignment_discussion_history_masters"
  add_foreign_key "activity_log_ipa_assignment_discussion_history", "users", column: "created_by_user_id"
  add_foreign_key "activity_log_ipa_assignment_discussion_history", "users", name: "fk_activity_log_ipa_assignment_discussion_history_users"
  add_foreign_key "activity_log_ipa_assignment_discussions", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_discussions", "masters"
  add_foreign_key "activity_log_ipa_assignment_discussions", "users"
  add_foreign_key "activity_log_ipa_assignment_discussions", "users", column: "created_by_user_id"
  add_foreign_key "activity_log_ipa_assignment_history", "activity_log_ipa_assignments", name: "fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm"
  add_foreign_key "activity_log_ipa_assignment_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_history_ipa_assignment_id"
  add_foreign_key "activity_log_ipa_assignment_history", "masters", name: "fk_activity_log_ipa_assignment_history_masters"
  add_foreign_key "activity_log_ipa_assignment_history", "users", name: "fk_activity_log_ipa_assignment_history_users"
  add_foreign_key "activity_log_ipa_assignment_inex_checklist_history", "activity_log_ipa_assignment_inex_checklists", name: "fk_activity_log_ipa_assignment_inex_checklist_history_activity_"
  add_foreign_key "activity_log_ipa_assignment_inex_checklist_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_inex_checklist_history_ipa_assig"
  add_foreign_key "activity_log_ipa_assignment_inex_checklist_history", "masters", name: "fk_activity_log_ipa_assignment_inex_checklist_history_masters"
  add_foreign_key "activity_log_ipa_assignment_inex_checklist_history", "users", name: "fk_activity_log_ipa_assignment_inex_checklist_history_users"
  add_foreign_key "activity_log_ipa_assignment_inex_checklists", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_inex_checklists", "masters"
  add_foreign_key "activity_log_ipa_assignment_inex_checklists", "users"
  add_foreign_key "activity_log_ipa_assignment_med_nav_history", "activity_log_ipa_assignment_med_navs", name: "fk_activity_log_ipa_assignment_med_nav_history_activity_log_ipa"
  add_foreign_key "activity_log_ipa_assignment_med_nav_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_med_nav_history_ipa_assignment_m"
  add_foreign_key "activity_log_ipa_assignment_med_nav_history", "masters", name: "fk_activity_log_ipa_assignment_med_nav_history_masters"
  add_foreign_key "activity_log_ipa_assignment_med_nav_history", "users", name: "fk_activity_log_ipa_assignment_med_nav_history_users"
  add_foreign_key "activity_log_ipa_assignment_med_navs", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_med_navs", "masters"
  add_foreign_key "activity_log_ipa_assignment_med_navs", "users"
  add_foreign_key "activity_log_ipa_assignment_minor_deviation_history", "activity_log_ipa_assignment_minor_deviations", name: "fk_activity_log_ipa_assignment_minor_deviation_history_activity"
  add_foreign_key "activity_log_ipa_assignment_minor_deviation_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_minor_deviation_history_ipa_assi"
  add_foreign_key "activity_log_ipa_assignment_minor_deviation_history", "masters", name: "fk_activity_log_ipa_assignment_minor_deviation_history_masters"
  add_foreign_key "activity_log_ipa_assignment_minor_deviation_history", "users", name: "fk_activity_log_ipa_assignment_minor_deviation_history_users"
  add_foreign_key "activity_log_ipa_assignment_minor_deviations", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_minor_deviations", "masters"
  add_foreign_key "activity_log_ipa_assignment_minor_deviations", "users"
  add_foreign_key "activity_log_ipa_assignment_navigation_history", "activity_log_ipa_assignment_navigations", name: "fk_activity_log_ipa_assignment_navigation_history_activity_log_"
  add_foreign_key "activity_log_ipa_assignment_navigation_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_navigation_history_ipa_assignmen"
  add_foreign_key "activity_log_ipa_assignment_navigation_history", "masters", name: "fk_activity_log_ipa_assignment_navigation_history_masters"
  add_foreign_key "activity_log_ipa_assignment_navigation_history", "users", name: "fk_activity_log_ipa_assignment_navigation_history_users"
  add_foreign_key "activity_log_ipa_assignment_navigations", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_navigations", "masters"
  add_foreign_key "activity_log_ipa_assignment_navigations", "users"
  add_foreign_key "activity_log_ipa_assignment_phone_screen_history", "activity_log_ipa_assignment_phone_screens", name: "fk_activity_log_ipa_assignment_phone_screen_history_activity_lo"
  add_foreign_key "activity_log_ipa_assignment_phone_screen_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_phone_screen_history_ipa_assignm"
  add_foreign_key "activity_log_ipa_assignment_phone_screen_history", "masters", name: "fk_activity_log_ipa_assignment_phone_screen_history_masters"
  add_foreign_key "activity_log_ipa_assignment_phone_screen_history", "users", name: "fk_activity_log_ipa_assignment_phone_screen_history_users"
  add_foreign_key "activity_log_ipa_assignment_phone_screens", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_phone_screens", "masters"
  add_foreign_key "activity_log_ipa_assignment_phone_screens", "users"
  add_foreign_key "activity_log_ipa_assignment_post_visit_history", "activity_log_ipa_assignment_post_visits", name: "fk_activity_log_ipa_assignment_post_visit_history_activity_log_"
  add_foreign_key "activity_log_ipa_assignment_post_visit_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_post_visit_history_ipa_assignmen"
  add_foreign_key "activity_log_ipa_assignment_post_visit_history", "masters", name: "fk_activity_log_ipa_assignment_post_visit_history_masters"
  add_foreign_key "activity_log_ipa_assignment_post_visit_history", "users", name: "fk_activity_log_ipa_assignment_post_visit_history_users"
  add_foreign_key "activity_log_ipa_assignment_post_visits", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_post_visits", "masters"
  add_foreign_key "activity_log_ipa_assignment_post_visits", "users"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviation_history", "activity_log_ipa_assignment_protocol_deviations", name: "fk_activity_log_ipa_assignment_protocol_deviation_history_activ"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviation_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_protocol_deviation_history_ipa_a"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviation_history", "masters", name: "fk_activity_log_ipa_assignment_protocol_deviation_history_maste"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviation_history", "users", name: "fk_activity_log_ipa_assignment_protocol_deviation_history_users"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviations", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviations", "masters"
  add_foreign_key "activity_log_ipa_assignment_protocol_deviations", "users"
  add_foreign_key "activity_log_ipa_assignment_session_filestore_history", "activity_log_ipa_assignment_session_filestores", name: "fk_activity_log_ipa_assignment_session_filestore_history_activi"
  add_foreign_key "activity_log_ipa_assignment_session_filestore_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_session_filestore_history_ipa_as"
  add_foreign_key "activity_log_ipa_assignment_session_filestore_history", "masters", name: "fk_activity_log_ipa_assignment_session_filestore_history_master"
  add_foreign_key "activity_log_ipa_assignment_session_filestore_history", "users", name: "fk_activity_log_ipa_assignment_session_filestore_history_users"
  add_foreign_key "activity_log_ipa_assignment_session_filestores", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_session_filestores", "masters"
  add_foreign_key "activity_log_ipa_assignment_session_filestores", "users"
  add_foreign_key "activity_log_ipa_assignment_summaries", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignment_summaries", "masters"
  add_foreign_key "activity_log_ipa_assignment_summaries", "users"
  add_foreign_key "activity_log_ipa_assignment_summary_history", "activity_log_ipa_assignment_summaries", name: "fk_activity_log_ipa_assignment_summary_history_activity_log_ipa"
  add_foreign_key "activity_log_ipa_assignment_summary_history", "ipa_assignments", name: "fk_activity_log_ipa_assignment_summary_history_ipa_assignment_s"
  add_foreign_key "activity_log_ipa_assignment_summary_history", "masters", name: "fk_activity_log_ipa_assignment_summary_history_masters"
  add_foreign_key "activity_log_ipa_assignment_summary_history", "users", name: "fk_activity_log_ipa_assignment_summary_history_users"
  add_foreign_key "activity_log_ipa_assignments", "ipa_assignments"
  add_foreign_key "activity_log_ipa_assignments", "masters"
  add_foreign_key "activity_log_ipa_assignments", "users"
  add_foreign_key "activity_log_ipa_survey_history", "activity_log_ipa_surveys", name: "fk_activity_log_ipa_survey_history_activity_log_ipa_surveys"
  add_foreign_key "activity_log_ipa_survey_history", "ipa_surveys", name: "fk_activity_log_ipa_survey_history_ipa_survey_id"
  add_foreign_key "activity_log_ipa_survey_history", "masters", name: "fk_activity_log_ipa_survey_history_masters"
  add_foreign_key "activity_log_ipa_survey_history", "users", name: "fk_activity_log_ipa_survey_history_users"
  add_foreign_key "activity_log_ipa_surveys", "ipa_surveys"
  add_foreign_key "activity_log_ipa_surveys", "masters"
  add_foreign_key "activity_log_ipa_surveys", "users"
  add_foreign_key "activity_log_new_test_history", "activity_log_new_tests", name: "fk_activity_log_new_test_history_activity_log_new_tests"
  add_foreign_key "activity_log_new_test_history", "masters", name: "fk_activity_log_new_test_history_masters"
  add_foreign_key "activity_log_new_test_history", "new_tests", name: "fk_activity_log_new_test_history_new_test_id"
  add_foreign_key "activity_log_new_test_history", "users", name: "fk_activity_log_new_test_history_users"
  add_foreign_key "activity_log_new_tests", "masters"
  add_foreign_key "activity_log_new_tests", "new_tests"
  add_foreign_key "activity_log_new_tests", "users"
  add_foreign_key "activity_log_persnet_assignment_history", "activity_log_persnet_assignments", name: "fk_activity_log_persnet_assignment_history_activity_log_persnet"
  add_foreign_key "activity_log_persnet_assignment_history", "masters", name: "fk_activity_log_persnet_assignment_history_masters"
  add_foreign_key "activity_log_persnet_assignment_history", "persnet_assignments", name: "fk_activity_log_persnet_assignment_history_persnet_assignment_i"
  add_foreign_key "activity_log_persnet_assignment_history", "users", name: "fk_activity_log_persnet_assignment_history_users"
  add_foreign_key "activity_log_persnet_assignments", "masters"
  add_foreign_key "activity_log_persnet_assignments", "persnet_assignments"
  add_foreign_key "activity_log_persnet_assignments", "users"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussion_history", "activity_log_pitt_bhi_assignment_discussions"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussion_history", "masters"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussion_history", "pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussion_history", "users"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussions", "masters"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussions", "pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignment_discussions", "users"
  add_foreign_key "activity_log_pitt_bhi_assignment_history", "activity_log_pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignment_history", "masters"
  add_foreign_key "activity_log_pitt_bhi_assignment_history", "pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignment_history", "users"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screen_history", "activity_log_pitt_bhi_assignment_phone_screens"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screen_history", "masters"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screen_history", "pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screen_history", "users"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screens", "masters"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screens", "pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignment_phone_screens", "users"
  add_foreign_key "activity_log_pitt_bhi_assignments", "masters"
  add_foreign_key "activity_log_pitt_bhi_assignments", "pitt_bhi_assignments"
  add_foreign_key "activity_log_pitt_bhi_assignments", "users"
  add_foreign_key "activity_log_player_contact_phone_history", "activity_log_player_contact_phones", name: "fk_activity_log_player_contact_phone_history_activity_log_playe"
  add_foreign_key "activity_log_player_contact_phone_history", "masters", name: "fk_activity_log_player_contact_phone_history_masters"
  add_foreign_key "activity_log_player_contact_phone_history", "player_contacts", name: "fk_activity_log_player_contact_phone_history_player_contact_pho"
  add_foreign_key "activity_log_player_contact_phone_history", "users", name: "fk_activity_log_player_contact_phone_history_users"
  add_foreign_key "activity_log_player_info_history", "activity_log_player_infos", name: "fk_activity_log_player_info_history_activity_log_player_infos"
  add_foreign_key "activity_log_player_info_history", "masters", name: "fk_activity_log_player_info_history_masters"
  add_foreign_key "activity_log_player_info_history", "player_infos", name: "fk_activity_log_player_info_history_player_info_id"
  add_foreign_key "activity_log_player_info_history", "users", name: "fk_activity_log_player_info_history_users"
  add_foreign_key "activity_log_player_infos", "masters"
  add_foreign_key "activity_log_player_infos", "player_infos"
  add_foreign_key "activity_log_player_infos", "users"
  add_foreign_key "activity_log_sleep_assignment_adverse_event_history", "activity_log_sleep_assignment_adverse_events", name: "fk_activity_log_sleep_assignment_adverse_event_history_activity"
  add_foreign_key "activity_log_sleep_assignment_adverse_event_history", "masters", name: "fk_activity_log_sleep_assignment_adverse_event_history_masters"
  add_foreign_key "activity_log_sleep_assignment_adverse_event_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_adverse_event_history_sleep_as"
  add_foreign_key "activity_log_sleep_assignment_adverse_event_history", "users", name: "fk_activity_log_sleep_assignment_adverse_event_history_users"
  add_foreign_key "activity_log_sleep_assignment_adverse_events", "masters"
  add_foreign_key "activity_log_sleep_assignment_adverse_events", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_adverse_events", "users"
  add_foreign_key "activity_log_sleep_assignment_discussion_history", "activity_log_sleep_assignment_discussions", name: "fk_activity_log_sleep_assignment_discussion_history_activity_lo"
  add_foreign_key "activity_log_sleep_assignment_discussion_history", "masters", name: "fk_activity_log_sleep_assignment_discussion_history_masters"
  add_foreign_key "activity_log_sleep_assignment_discussion_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_discussion_history_sleep_assig"
  add_foreign_key "activity_log_sleep_assignment_discussion_history", "users", name: "fk_activity_log_sleep_assignment_discussion_history_users"
  add_foreign_key "activity_log_sleep_assignment_discussions", "masters"
  add_foreign_key "activity_log_sleep_assignment_discussions", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_discussions", "users"
  add_foreign_key "activity_log_sleep_assignment_history", "activity_log_sleep_assignments", name: "fk_activity_log_sleep_assignment_history_activity_log_sleep_ass"
  add_foreign_key "activity_log_sleep_assignment_history", "masters", name: "fk_activity_log_sleep_assignment_history_masters"
  add_foreign_key "activity_log_sleep_assignment_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_history_sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_history", "users", name: "fk_activity_log_sleep_assignment_history_users"
  add_foreign_key "activity_log_sleep_assignment_inex_checklist_history", "activity_log_sleep_assignment_inex_checklists", name: "fk_activity_log_sleep_assignment_inex_checklist_history_activit"
  add_foreign_key "activity_log_sleep_assignment_inex_checklist_history", "masters", name: "fk_activity_log_sleep_assignment_inex_checklist_history_masters"
  add_foreign_key "activity_log_sleep_assignment_inex_checklist_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_inex_checklist_history_sleep_a"
  add_foreign_key "activity_log_sleep_assignment_inex_checklist_history", "users", name: "fk_activity_log_sleep_assignment_inex_checklist_history_users"
  add_foreign_key "activity_log_sleep_assignment_inex_checklists", "masters"
  add_foreign_key "activity_log_sleep_assignment_inex_checklists", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_inex_checklists", "users"
  add_foreign_key "activity_log_sleep_assignment_med_nav_history", "activity_log_sleep_assignment_med_navs", name: "fk_activity_log_sleep_assignment_med_nav_history_activity_log_s"
  add_foreign_key "activity_log_sleep_assignment_med_nav_history", "masters", name: "fk_activity_log_sleep_assignment_med_nav_history_masters"
  add_foreign_key "activity_log_sleep_assignment_med_nav_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_med_nav_history_sleep_assignme"
  add_foreign_key "activity_log_sleep_assignment_med_nav_history", "users", name: "fk_activity_log_sleep_assignment_med_nav_history_users"
  add_foreign_key "activity_log_sleep_assignment_med_navs", "masters"
  add_foreign_key "activity_log_sleep_assignment_med_navs", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_med_navs", "users"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2_history", "activity_log_sleep_assignment_phone_screen2s", name: "fk_activity_log_sleep_assignment_phone_screen2_history_activity"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2_history", "masters", name: "fk_activity_log_sleep_assignment_phone_screen2_history_masters"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_phone_screen2_history_sleep_as"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2_history", "users", name: "fk_activity_log_sleep_assignment_phone_screen2_history_users"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2s", "masters"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2s", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_phone_screen2s", "users"
  add_foreign_key "activity_log_sleep_assignment_phone_screen_history", "activity_log_sleep_assignment_phone_screens", name: "fk_activity_log_sleep_assignment_phone_screen_history_activity_"
  add_foreign_key "activity_log_sleep_assignment_phone_screen_history", "masters", name: "fk_activity_log_sleep_assignment_phone_screen_history_masters"
  add_foreign_key "activity_log_sleep_assignment_phone_screen_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_phone_screen_history_sleep_ass"
  add_foreign_key "activity_log_sleep_assignment_phone_screen_history", "users", name: "fk_activity_log_sleep_assignment_phone_screen_history_users"
  add_foreign_key "activity_log_sleep_assignment_phone_screens", "masters"
  add_foreign_key "activity_log_sleep_assignment_phone_screens", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_phone_screens", "users"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviation_history", "activity_log_sleep_assignment_protocol_deviations", name: "fk_activity_log_sleep_assignment_protocol_deviation_history_act"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviation_history", "masters", name: "fk_activity_log_sleep_assignment_protocol_deviation_history_mas"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviation_history", "sleep.sleep_assignments", column: "sleep_assignment_id", name: "fk_activity_log_sleep_assignment_protocol_deviation_history_sle"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviation_history", "users", name: "fk_activity_log_sleep_assignment_protocol_deviation_history_use"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviations", "masters"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviations", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignment_protocol_deviations", "users"
  add_foreign_key "activity_log_sleep_assignments", "masters"
  add_foreign_key "activity_log_sleep_assignments", "sleep.sleep_assignments", column: "sleep_assignment_id"
  add_foreign_key "activity_log_sleep_assignments", "users"
  add_foreign_key "activity_log_tbs_assignment_adverse_event_history", "activity_log_tbs_assignment_adverse_events", name: "fk_activity_log_tbs_assignment_adverse_event_history_activity_l"
  add_foreign_key "activity_log_tbs_assignment_adverse_event_history", "masters", name: "fk_activity_log_tbs_assignment_adverse_event_history_masters"
  add_foreign_key "activity_log_tbs_assignment_adverse_event_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_adverse_event_history_tbs_assign"
  add_foreign_key "activity_log_tbs_assignment_adverse_event_history", "users", name: "fk_activity_log_tbs_assignment_adverse_event_history_users"
  add_foreign_key "activity_log_tbs_assignment_adverse_events", "masters"
  add_foreign_key "activity_log_tbs_assignment_adverse_events", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignment_adverse_events", "users"
  add_foreign_key "activity_log_tbs_assignment_history", "activity_log_tbs_assignments", name: "fk_activity_log_tbs_assignment_history_activity_log_tbs_assignm"
  add_foreign_key "activity_log_tbs_assignment_history", "masters", name: "fk_activity_log_tbs_assignment_history_masters"
  add_foreign_key "activity_log_tbs_assignment_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_history_tbs_assignment_id"
  add_foreign_key "activity_log_tbs_assignment_history", "users", name: "fk_activity_log_tbs_assignment_history_users"
  add_foreign_key "activity_log_tbs_assignment_inex_checklist_history", "activity_log_tbs_assignment_inex_checklists", name: "fk_activity_log_tbs_assignment_inex_checklist_history_activity_"
  add_foreign_key "activity_log_tbs_assignment_inex_checklist_history", "masters", name: "fk_activity_log_tbs_assignment_inex_checklist_history_masters"
  add_foreign_key "activity_log_tbs_assignment_inex_checklist_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_inex_checklist_history_tbs_assig"
  add_foreign_key "activity_log_tbs_assignment_inex_checklist_history", "users", name: "fk_activity_log_tbs_assignment_inex_checklist_history_users"
  add_foreign_key "activity_log_tbs_assignment_inex_checklists", "masters"
  add_foreign_key "activity_log_tbs_assignment_inex_checklists", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignment_inex_checklists", "users"
  add_foreign_key "activity_log_tbs_assignment_med_nav_history", "activity_log_tbs_assignment_med_navs", name: "fk_activity_log_tbs_assignment_med_nav_history_activity_log_tbs"
  add_foreign_key "activity_log_tbs_assignment_med_nav_history", "masters", name: "fk_activity_log_tbs_assignment_med_nav_history_masters"
  add_foreign_key "activity_log_tbs_assignment_med_nav_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_med_nav_history_tbs_assignment_m"
  add_foreign_key "activity_log_tbs_assignment_med_nav_history", "users", name: "fk_activity_log_tbs_assignment_med_nav_history_users"
  add_foreign_key "activity_log_tbs_assignment_med_navs", "masters"
  add_foreign_key "activity_log_tbs_assignment_med_navs", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignment_med_navs", "users"
  add_foreign_key "activity_log_tbs_assignment_navigation_history", "activity_log_tbs_assignment_navigations", name: "fk_activity_log_tbs_assignment_navigation_history_activity_log_"
  add_foreign_key "activity_log_tbs_assignment_navigation_history", "masters", name: "fk_activity_log_tbs_assignment_navigation_history_masters"
  add_foreign_key "activity_log_tbs_assignment_navigation_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_navigation_history_tbs_assignmen"
  add_foreign_key "activity_log_tbs_assignment_navigation_history", "users", name: "fk_activity_log_tbs_assignment_navigation_history_users"
  add_foreign_key "activity_log_tbs_assignment_navigations", "masters"
  add_foreign_key "activity_log_tbs_assignment_navigations", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignment_navigations", "users"
  add_foreign_key "activity_log_tbs_assignment_phone_screen_history", "activity_log_tbs_assignment_phone_screens", name: "fk_activity_log_tbs_assignment_phone_screen_history_activity_lo"
  add_foreign_key "activity_log_tbs_assignment_phone_screen_history", "masters", name: "fk_activity_log_tbs_assignment_phone_screen_history_masters"
  add_foreign_key "activity_log_tbs_assignment_phone_screen_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_phone_screen_history_tbs_assignm"
  add_foreign_key "activity_log_tbs_assignment_phone_screen_history", "users", name: "fk_activity_log_tbs_assignment_phone_screen_history_users"
  add_foreign_key "activity_log_tbs_assignment_phone_screens", "masters"
  add_foreign_key "activity_log_tbs_assignment_phone_screens", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignment_phone_screens", "users"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviation_history", "activity_log_tbs_assignment_protocol_deviations", name: "fk_activity_log_tbs_assignment_protocol_deviation_history_activ"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviation_history", "masters", name: "fk_activity_log_tbs_assignment_protocol_deviation_history_maste"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviation_history", "tbs_assignments", name: "fk_activity_log_tbs_assignment_protocol_deviation_history_tbs_a"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviation_history", "users", name: "fk_activity_log_tbs_assignment_protocol_deviation_history_users"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviations", "masters"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviations", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignment_protocol_deviations", "users"
  add_foreign_key "activity_log_tbs_assignments", "masters"
  add_foreign_key "activity_log_tbs_assignments", "tbs_assignments"
  add_foreign_key "activity_log_tbs_assignments", "users"
  add_foreign_key "activity_log_zeus_bulk_message_history", "activity_log_zeus_bulk_messages", name: "fk_activity_log_zeus_bulk_message_history_activity_log_zeus_bul"
  add_foreign_key "activity_log_zeus_bulk_message_history", "masters", name: "fk_activity_log_zeus_bulk_message_history_masters"
  add_foreign_key "activity_log_zeus_bulk_message_history", "users", name: "fk_activity_log_zeus_bulk_message_history_users"
  add_foreign_key "activity_log_zeus_bulk_message_history", "zeus_bulk_messages", name: "fk_activity_log_zeus_bulk_message_history_zeus_bulk_message_id"
  add_foreign_key "activity_log_zeus_bulk_messages", "masters"
  add_foreign_key "activity_log_zeus_bulk_messages", "users"
  add_foreign_key "activity_log_zeus_bulk_messages", "zeus_bulk_messages"
  add_foreign_key "address_history", "addresses", name: "fk_address_history_addresses"
  add_foreign_key "address_history", "masters", name: "fk_address_history_masters"
  add_foreign_key "address_history", "users", name: "fk_address_history_users"
  add_foreign_key "addresses", "masters"
  add_foreign_key "addresses", "users"
  add_foreign_key "admin_action_logs", "admins"
  add_foreign_key "admin_history", "admins", name: "fk_admin_history_admins"
  add_foreign_key "app_configuration_history", "admins", name: "fk_app_configuration_history_admins"
  add_foreign_key "app_configuration_history", "app_configurations", name: "fk_app_configuration_history_app_configurations"
  add_foreign_key "app_configurations", "admins"
  add_foreign_key "app_configurations", "app_types"
  add_foreign_key "app_configurations", "users"
  add_foreign_key "app_type_history", "admins", name: "fk_app_type_history_admins"
  add_foreign_key "app_type_history", "app_types", name: "fk_app_type_history_app_types"
  add_foreign_key "app_types", "admins"
  add_foreign_key "bhs_assignment_history", "admins", name: "fk_bhs_assignment_history_admins"
  add_foreign_key "bhs_assignment_history", "bhs_assignments", column: "bhs_assignment_table_id", name: "fk_bhs_assignment_history_bhs_assignments"
  add_foreign_key "bhs_assignment_history", "masters", name: "fk_bhs_assignment_history_masters"
  add_foreign_key "bhs_assignment_history", "users", name: "fk_bhs_assignment_history_users"
  add_foreign_key "bhs_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "bhs_assignments", "masters"
  add_foreign_key "bhs_assignments", "users"
  add_foreign_key "bwh_sleep_id_number_history", "admins", name: "fk_bwh_sleep_id_number_history_admins"
  add_foreign_key "bwh_sleep_id_number_history", "bwh_sleep_id_numbers", column: "bwh_sleep_id_number_table_id", name: "fk_bwh_sleep_id_number_history_bwh_sleep_id_numbers"
  add_foreign_key "bwh_sleep_id_number_history", "masters", name: "fk_bwh_sleep_id_number_history_masters"
  add_foreign_key "bwh_sleep_id_number_history", "users", name: "fk_bwh_sleep_id_number_history_users"
  add_foreign_key "bwh_sleep_id_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "bwh_sleep_id_numbers", "masters"
  add_foreign_key "bwh_sleep_id_numbers", "users"
  add_foreign_key "college_history", "colleges", name: "fk_college_history_colleges"
  add_foreign_key "colleges", "admins"
  add_foreign_key "colleges", "users"
  add_foreign_key "config_libraries", "admins"
  add_foreign_key "config_library_history", "admins"
  add_foreign_key "config_library_history", "config_libraries"
  add_foreign_key "data_request_assignment_history", "admins", name: "fk_data_request_assignment_history_admins"
  add_foreign_key "data_request_assignment_history", "data_request_assignments", column: "data_request_assignment_table_id", name: "fk_data_request_assignment_history_data_request_assignments"
  add_foreign_key "data_request_assignment_history", "masters", name: "fk_data_request_assignment_history_masters"
  add_foreign_key "data_request_assignment_history", "users", name: "fk_data_request_assignment_history_users"
  add_foreign_key "data_request_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "data_request_assignments", "masters"
  add_foreign_key "data_request_assignments", "users"
  add_foreign_key "data_request_attrib_history", "data_request_attribs", name: "fk_data_request_attrib_history_data_request_attribs"
  add_foreign_key "data_request_attrib_history", "masters", name: "fk_data_request_attrib_history_masters"
  add_foreign_key "data_request_attrib_history", "users", name: "fk_data_request_attrib_history_users"
  add_foreign_key "data_request_attribs", "masters"
  add_foreign_key "data_request_attribs", "users"
  add_foreign_key "data_request_history", "data_requests", name: "fk_data_request_history_data_requests"
  add_foreign_key "data_request_history", "masters", name: "fk_data_request_history_masters"
  add_foreign_key "data_request_history", "users", column: "created_by_user_id", name: "fk_data_request_history_cb_users"
  add_foreign_key "data_request_history", "users", name: "fk_data_request_history_users"
  add_foreign_key "data_request_initial_review_history", "data_request_initial_reviews", name: "fk_data_request_initial_review_history_data_request_initial_rev"
  add_foreign_key "data_request_initial_review_history", "masters", name: "fk_data_request_initial_review_history_masters"
  add_foreign_key "data_request_initial_review_history", "users", column: "created_by_user_id", name: "fk_data_request_initial_review_history_cb_users"
  add_foreign_key "data_request_initial_review_history", "users", name: "fk_data_request_initial_review_history_users"
  add_foreign_key "data_request_initial_reviews", "masters"
  add_foreign_key "data_request_initial_reviews", "users"
  add_foreign_key "data_request_initial_reviews", "users", column: "created_by_user_id", name: "fk_rails_982635401e0"
  add_foreign_key "data_request_message_history", "data_request_messages", name: "fk_data_request_message_history_data_request_messages"
  add_foreign_key "data_request_message_history", "masters", name: "fk_data_request_message_history_masters"
  add_foreign_key "data_request_message_history", "users", column: "created_by_user_id", name: "fk_data_request_message_history_cb_users"
  add_foreign_key "data_request_message_history", "users", name: "fk_data_request_message_history_users"
  add_foreign_key "data_request_message_to_requester_history", "data_request_message_to_requesters", name: "fk_data_request_message_to_requester_history_data_request_messa"
  add_foreign_key "data_request_message_to_requester_history", "masters", name: "fk_data_request_message_to_requester_history_masters"
  add_foreign_key "data_request_message_to_requester_history", "users", column: "created_by_user_id", name: "fk_data_request_message_to_requester_history_cb_users"
  add_foreign_key "data_request_message_to_requester_history", "users", name: "fk_data_request_message_to_requester_history_users"
  add_foreign_key "data_request_message_to_requesters", "masters"
  add_foreign_key "data_request_message_to_requesters", "users"
  add_foreign_key "data_request_message_to_requesters", "users", column: "created_by_user_id", name: "fk_rails_982635401e0"
  add_foreign_key "data_request_message_to_reviewer_history", "data_request_message_to_reviewers", name: "fk_data_request_message_to_reviewer_history_data_request_messag"
  add_foreign_key "data_request_message_to_reviewer_history", "masters", name: "fk_data_request_message_to_reviewer_history_masters"
  add_foreign_key "data_request_message_to_reviewer_history", "users", column: "created_by_user_id", name: "fk_data_request_message_to_reviewer_history_cb_users"
  add_foreign_key "data_request_message_to_reviewer_history", "users", name: "fk_data_request_message_to_reviewer_history_users"
  add_foreign_key "data_request_message_to_reviewers", "masters"
  add_foreign_key "data_request_message_to_reviewers", "users"
  add_foreign_key "data_request_message_to_reviewers", "users", column: "created_by_user_id", name: "fk_rails_982635401e0"
  add_foreign_key "data_request_messages", "masters"
  add_foreign_key "data_request_messages", "users"
  add_foreign_key "data_request_messages", "users", column: "created_by_user_id", name: "fk_rails_982635401e0"
  add_foreign_key "data_requests", "masters"
  add_foreign_key "data_requests", "users"
  add_foreign_key "data_requests", "users", column: "created_by_user_id", name: "fk_rails_982635401e0"
  add_foreign_key "data_requests_selected_attrib_history", "data_requests_selected_attribs", name: "fk_data_requests_selected_attrib_history_data_requests_selected"
  add_foreign_key "data_requests_selected_attrib_history", "masters", name: "fk_data_requests_selected_attrib_history_masters"
  add_foreign_key "data_requests_selected_attrib_history", "users", name: "fk_data_requests_selected_attrib_history_users"
  add_foreign_key "data_requests_selected_attribs", "masters"
  add_foreign_key "data_requests_selected_attribs", "users"
  add_foreign_key "dynamic_model_history", "dynamic_models", name: "fk_dynamic_model_history_dynamic_models"
  add_foreign_key "dynamic_models", "admins"
  add_foreign_key "emergency_contact_history", "emergency_contacts", name: "fk_emergency_contact_history_emergency_contacts"
  add_foreign_key "emergency_contact_history", "masters", name: "fk_emergency_contact_history_masters"
  add_foreign_key "emergency_contact_history", "masters", name: "fk_emergency_contact_history_masters"
  add_foreign_key "emergency_contact_history", "tbs.emergency_contacts", column: "emergency_contact_id", name: "fk_emergency_contact_history_emergency_contacts"
  add_foreign_key "emergency_contact_history", "users", name: "fk_emergency_contact_history_users"
  add_foreign_key "emergency_contact_history", "users", name: "fk_emergency_contact_history_users"
  add_foreign_key "emergency_contact_history", "emergency_contacts", name: "fk_emergency_contact_history_emergency_contacts"
  add_foreign_key "emergency_contact_history", "masters", name: "fk_emergency_contact_history_masters"
  add_foreign_key "emergency_contact_history", "masters", name: "fk_emergency_contact_history_masters"
  add_foreign_key "emergency_contact_history", "tbs.emergency_contacts", column: "emergency_contact_id", name: "fk_emergency_contact_history_emergency_contacts"
  add_foreign_key "emergency_contact_history", "users", name: "fk_emergency_contact_history_users"
  add_foreign_key "emergency_contact_history", "users", name: "fk_emergency_contact_history_users"
  add_foreign_key "emergency_contacts", "masters"
  add_foreign_key "emergency_contacts", "masters"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "emergency_contacts", "masters"
  add_foreign_key "emergency_contacts", "masters"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "env_environment_history", "env_environments"
  add_foreign_key "env_environment_history", "masters"
  add_foreign_key "env_environment_history", "users"
  add_foreign_key "env_environments", "masters"
  add_foreign_key "env_environments", "users"
  add_foreign_key "env_hosting_account_history", "env_hosting_accounts"
  add_foreign_key "env_hosting_account_history", "users"
  add_foreign_key "env_hosting_account_history", "users", column: "created_by_user_id"
  add_foreign_key "env_hosting_accounts", "users"
  add_foreign_key "env_hosting_accounts", "users", column: "created_by_user_id"
  add_foreign_key "env_server_history", "env_servers"
  add_foreign_key "env_server_history", "masters"
  add_foreign_key "env_server_history", "users"
  add_foreign_key "env_servers", "masters"
  add_foreign_key "env_servers", "users"
  add_foreign_key "exception_logs", "admins"
  add_foreign_key "exception_logs", "users"
  add_foreign_key "ext_assignment_history", "ext_assignments", column: "ext_assignment_table_id", name: "fk_ext_assignment_history_ext_assignments"
  add_foreign_key "ext_assignment_history", "masters", name: "fk_ext_assignment_history_masters"
  add_foreign_key "ext_assignment_history", "users", name: "fk_ext_assignment_history_users"
  add_foreign_key "ext_assignments", "masters"
  add_foreign_key "ext_assignments", "users"
  add_foreign_key "ext_gen_assignment_history", "admins", name: "fk_ext_gen_assignment_history_admins"
  add_foreign_key "ext_gen_assignment_history", "ext_gen_assignments", column: "ext_gen_assignment_table_id", name: "fk_ext_gen_assignment_history_ext_gen_assignments"
  add_foreign_key "ext_gen_assignment_history", "masters", name: "fk_ext_gen_assignment_history_masters"
  add_foreign_key "ext_gen_assignment_history", "users", name: "fk_ext_gen_assignment_history_users"
  add_foreign_key "ext_gen_assignments", "masters"
  add_foreign_key "ext_gen_assignments", "users"
  add_foreign_key "external_identifier_history", "admins"
  add_foreign_key "external_identifier_history", "external_identifiers"
  add_foreign_key "external_identifiers", "admins"
  add_foreign_key "external_link_history", "external_links", name: "fk_external_link_history_external_links"
  add_foreign_key "external_links", "admins"
  add_foreign_key "femfl_address_history", "femfl_addresses"
  add_foreign_key "femfl_address_history", "masters"
  add_foreign_key "femfl_address_history", "users"
  add_foreign_key "femfl_addresses", "masters"
  add_foreign_key "femfl_addresses", "users"
  add_foreign_key "femfl_assignment_history", "admins"
  add_foreign_key "femfl_assignment_history", "femfl_assignments", column: "femfl_assignment_table_id_id"
  add_foreign_key "femfl_assignment_history", "masters"
  add_foreign_key "femfl_assignment_history", "users"
  add_foreign_key "femfl_assignments", "admins"
  add_foreign_key "femfl_assignments", "masters"
  add_foreign_key "femfl_assignments", "users"
  add_foreign_key "femfl_contact_history", "femfl_contacts"
  add_foreign_key "femfl_contact_history", "masters"
  add_foreign_key "femfl_contact_history", "users"
  add_foreign_key "femfl_contacts", "masters"
  add_foreign_key "femfl_contacts", "users"
  add_foreign_key "femfl_subject_history", "femfl_subjects"
  add_foreign_key "femfl_subject_history", "masters"
  add_foreign_key "femfl_subject_history", "users"
  add_foreign_key "femfl_subjects", "masters"
  add_foreign_key "femfl_subjects", "users"
  add_foreign_key "general_selection_history", "general_selections", name: "fk_general_selection_history_general_selections"
  add_foreign_key "general_selections", "admins"
  add_foreign_key "grit_access_msm_staff_history", "grit_access_msm_staffs", name: "fk_grit_access_msm_staff_history_grit_access_msm_staffs"
  add_foreign_key "grit_access_msm_staff_history", "masters", name: "fk_grit_access_msm_staff_history_masters"
  add_foreign_key "grit_access_msm_staff_history", "users", name: "fk_grit_access_msm_staff_history_users"
  add_foreign_key "grit_access_msm_staffs", "masters"
  add_foreign_key "grit_access_msm_staffs", "users"
  add_foreign_key "grit_access_pi_history", "grit_access_pis", name: "fk_grit_access_pi_history_grit_access_pis"
  add_foreign_key "grit_access_pi_history", "masters", name: "fk_grit_access_pi_history_masters"
  add_foreign_key "grit_access_pi_history", "users", name: "fk_grit_access_pi_history_users"
  add_foreign_key "grit_access_pis", "masters"
  add_foreign_key "grit_access_pis", "users"
  add_foreign_key "grit_adverse_event_history", "grit_adverse_events", name: "fk_grit_adverse_event_history_grit_adverse_events"
  add_foreign_key "grit_adverse_event_history", "masters", name: "fk_grit_adverse_event_history_masters"
  add_foreign_key "grit_adverse_event_history", "users", name: "fk_grit_adverse_event_history_users"
  add_foreign_key "grit_adverse_events", "masters"
  add_foreign_key "grit_adverse_events", "users"
  add_foreign_key "grit_appointment_history", "grit_appointments", name: "fk_grit_appointment_history_grit_appointments"
  add_foreign_key "grit_appointment_history", "masters", name: "fk_grit_appointment_history_masters"
  add_foreign_key "grit_appointment_history", "users", name: "fk_grit_appointment_history_users"
  add_foreign_key "grit_appointments", "masters"
  add_foreign_key "grit_appointments", "users"
  add_foreign_key "grit_assignment_history", "admins", name: "fk_grit_assignment_history_admins"
  add_foreign_key "grit_assignment_history", "admins", name: "fk_grit_assignment_history_admins"
  add_foreign_key "grit_assignment_history", "grit.grit_assignments", column: "grit_assignment_table_id", name: "fk_grit_assignment_history_grit_assignments"
  add_foreign_key "grit_assignment_history", "grit_assignments", column: "grit_assignment_table_id", name: "fk_grit_assignment_history_grit_assignments"
  add_foreign_key "grit_assignment_history", "masters", name: "fk_grit_assignment_history_masters"
  add_foreign_key "grit_assignment_history", "masters", name: "fk_grit_assignment_history_masters"
  add_foreign_key "grit_assignment_history", "users", name: "fk_grit_assignment_history_users"
  add_foreign_key "grit_assignment_history", "users", name: "fk_grit_assignment_history_users"
  add_foreign_key "grit_assignment_history", "admins", name: "fk_grit_assignment_history_admins"
  add_foreign_key "grit_assignment_history", "admins", name: "fk_grit_assignment_history_admins"
  add_foreign_key "grit_assignment_history", "grit.grit_assignments", column: "grit_assignment_table_id", name: "fk_grit_assignment_history_grit_assignments"
  add_foreign_key "grit_assignment_history", "grit_assignments", column: "grit_assignment_table_id", name: "fk_grit_assignment_history_grit_assignments"
  add_foreign_key "grit_assignment_history", "masters", name: "fk_grit_assignment_history_masters"
  add_foreign_key "grit_assignment_history", "masters", name: "fk_grit_assignment_history_masters"
  add_foreign_key "grit_assignment_history", "users", name: "fk_grit_assignment_history_users"
  add_foreign_key "grit_assignment_history", "users", name: "fk_grit_assignment_history_users"
  add_foreign_key "grit_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "grit_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "grit_assignments", "masters"
  add_foreign_key "grit_assignments", "masters"
  add_foreign_key "grit_assignments", "users"
  add_foreign_key "grit_assignments", "users"
  add_foreign_key "grit_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "grit_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "grit_assignments", "masters"
  add_foreign_key "grit_assignments", "masters"
  add_foreign_key "grit_assignments", "users"
  add_foreign_key "grit_assignments", "users"
  add_foreign_key "grit_consent_mailing_history", "grit_consent_mailings", name: "fk_grit_consent_mailing_history_grit_consent_mailings"
  add_foreign_key "grit_consent_mailing_history", "masters", name: "fk_grit_consent_mailing_history_masters"
  add_foreign_key "grit_consent_mailing_history", "users", name: "fk_grit_consent_mailing_history_users"
  add_foreign_key "grit_consent_mailings", "masters"
  add_foreign_key "grit_consent_mailings", "users"
  add_foreign_key "grit_msm_post_testing_history", "grit_msm_post_testings", name: "fk_grit_msm_post_testing_history_grit_msm_post_testings"
  add_foreign_key "grit_msm_post_testing_history", "masters", name: "fk_grit_msm_post_testing_history_masters"
  add_foreign_key "grit_msm_post_testing_history", "users", name: "fk_grit_msm_post_testing_history_users"
  add_foreign_key "grit_msm_post_testings", "masters"
  add_foreign_key "grit_msm_post_testings", "users"
  add_foreign_key "grit_msm_screening_detail_history", "grit_msm_screening_details", name: "fk_grit_msm_screening_detail_history_grit_msm_screening_details"
  add_foreign_key "grit_msm_screening_detail_history", "masters", name: "fk_grit_msm_screening_detail_history_masters"
  add_foreign_key "grit_msm_screening_detail_history", "users", name: "fk_grit_msm_screening_detail_history_users"
  add_foreign_key "grit_msm_screening_details", "masters"
  add_foreign_key "grit_msm_screening_details", "users"
  add_foreign_key "grit_pi_followup_history", "grit_pi_followups", name: "fk_grit_pi_followup_history_grit_pi_followups"
  add_foreign_key "grit_pi_followup_history", "masters", name: "fk_grit_pi_followup_history_masters"
  add_foreign_key "grit_pi_followup_history", "users", name: "fk_grit_pi_followup_history_users"
  add_foreign_key "grit_pi_followups", "masters"
  add_foreign_key "grit_pi_followups", "users"
  add_foreign_key "grit_protocol_deviation_history", "grit_protocol_deviations", name: "fk_grit_protocol_deviation_history_grit_protocol_deviations"
  add_foreign_key "grit_protocol_deviation_history", "masters", name: "fk_grit_protocol_deviation_history_masters"
  add_foreign_key "grit_protocol_deviation_history", "users", name: "fk_grit_protocol_deviation_history_users"
  add_foreign_key "grit_protocol_deviations", "masters"
  add_foreign_key "grit_protocol_deviations", "users"
  add_foreign_key "grit_protocol_exception_history", "grit_protocol_exceptions", name: "fk_grit_protocol_exception_history_grit_protocol_exceptions"
  add_foreign_key "grit_protocol_exception_history", "masters", name: "fk_grit_protocol_exception_history_masters"
  add_foreign_key "grit_protocol_exception_history", "users", name: "fk_grit_protocol_exception_history_users"
  add_foreign_key "grit_protocol_exceptions", "masters"
  add_foreign_key "grit_protocol_exceptions", "users"
  add_foreign_key "grit_ps_audit_c_question_history", "grit_ps_audit_c_questions", name: "fk_grit_ps_audit_c_question_history_grit_ps_audit_c_questions"
  add_foreign_key "grit_ps_audit_c_question_history", "masters", name: "fk_grit_ps_audit_c_question_history_masters"
  add_foreign_key "grit_ps_audit_c_question_history", "users", name: "fk_grit_ps_audit_c_question_history_users"
  add_foreign_key "grit_ps_audit_c_questions", "masters"
  add_foreign_key "grit_ps_audit_c_questions", "users"
  add_foreign_key "grit_ps_basic_response_history", "grit_ps_basic_responses", name: "fk_grit_ps_basic_response_history_grit_ps_basic_responses"
  add_foreign_key "grit_ps_basic_response_history", "masters", name: "fk_grit_ps_basic_response_history_masters"
  add_foreign_key "grit_ps_basic_response_history", "users", name: "fk_grit_ps_basic_response_history_users"
  add_foreign_key "grit_ps_basic_responses", "masters"
  add_foreign_key "grit_ps_basic_responses", "users"
  add_foreign_key "grit_ps_eligibility_followup_history", "grit_ps_eligibility_followups", name: "fk_grit_ps_eligibility_followup_history_grit_ps_eligibility_fol"
  add_foreign_key "grit_ps_eligibility_followup_history", "masters", name: "fk_grit_ps_eligibility_followup_history_masters"
  add_foreign_key "grit_ps_eligibility_followup_history", "users", name: "fk_grit_ps_eligibility_followup_history_users"
  add_foreign_key "grit_ps_eligibility_followups", "masters"
  add_foreign_key "grit_ps_eligibility_followups", "users"
  add_foreign_key "grit_ps_eligible_history", "grit_ps_eligibles", name: "fk_grit_ps_eligible_history_grit_ps_eligibles"
  add_foreign_key "grit_ps_eligible_history", "masters", name: "fk_grit_ps_eligible_history_masters"
  add_foreign_key "grit_ps_eligible_history", "users", name: "fk_grit_ps_eligible_history_users"
  add_foreign_key "grit_ps_eligibles", "masters"
  add_foreign_key "grit_ps_eligibles", "users"
  add_foreign_key "grit_ps_initial_screening_history", "grit_ps_initial_screenings", name: "fk_grit_ps_initial_screening_history_grit_ps_initial_screenings"
  add_foreign_key "grit_ps_initial_screening_history", "masters", name: "fk_grit_ps_initial_screening_history_masters"
  add_foreign_key "grit_ps_initial_screening_history", "users", name: "fk_grit_ps_initial_screening_history_users"
  add_foreign_key "grit_ps_initial_screenings", "masters"
  add_foreign_key "grit_ps_initial_screenings", "users"
  add_foreign_key "grit_ps_non_eligible_history", "grit_ps_non_eligibles", name: "fk_grit_ps_non_eligible_history_grit_ps_non_eligibles"
  add_foreign_key "grit_ps_non_eligible_history", "masters", name: "fk_grit_ps_non_eligible_history_masters"
  add_foreign_key "grit_ps_non_eligible_history", "users", name: "fk_grit_ps_non_eligible_history_users"
  add_foreign_key "grit_ps_non_eligibles", "masters"
  add_foreign_key "grit_ps_non_eligibles", "users"
  add_foreign_key "grit_ps_pain_question_history", "grit_ps_pain_questions", name: "fk_grit_ps_pain_question_history_grit_ps_pain_questions"
  add_foreign_key "grit_ps_pain_question_history", "masters", name: "fk_grit_ps_pain_question_history_masters"
  add_foreign_key "grit_ps_pain_question_history", "users", name: "fk_grit_ps_pain_question_history_users"
  add_foreign_key "grit_ps_pain_questions", "masters"
  add_foreign_key "grit_ps_pain_questions", "users"
  add_foreign_key "grit_ps_participation_history", "grit_ps_participations", name: "fk_grit_ps_participation_history_grit_ps_participations"
  add_foreign_key "grit_ps_participation_history", "masters", name: "fk_grit_ps_participation_history_masters"
  add_foreign_key "grit_ps_participation_history", "users", name: "fk_grit_ps_participation_history_users"
  add_foreign_key "grit_ps_participations", "masters"
  add_foreign_key "grit_ps_participations", "users"
  add_foreign_key "grit_ps_possibly_eligible_history", "grit_ps_possibly_eligibles", name: "fk_grit_ps_possibly_eligible_history_grit_ps_possibly_eligibles"
  add_foreign_key "grit_ps_possibly_eligible_history", "masters", name: "fk_grit_ps_possibly_eligible_history_masters"
  add_foreign_key "grit_ps_possibly_eligible_history", "users", name: "fk_grit_ps_possibly_eligible_history_users"
  add_foreign_key "grit_ps_possibly_eligibles", "masters"
  add_foreign_key "grit_ps_possibly_eligibles", "users"
  add_foreign_key "grit_ps_screener_response_history", "grit_ps_screener_responses", name: "fk_grit_ps_screener_response_history_grit_ps_screener_responses"
  add_foreign_key "grit_ps_screener_response_history", "masters", name: "fk_grit_ps_screener_response_history_masters"
  add_foreign_key "grit_ps_screener_response_history", "users", name: "fk_grit_ps_screener_response_history_users"
  add_foreign_key "grit_ps_screener_responses", "masters"
  add_foreign_key "grit_ps_screener_responses", "users"
  add_foreign_key "grit_screening_history", "grit_screenings", name: "fk_grit_screening_history_grit_screenings"
  add_foreign_key "grit_screening_history", "masters", name: "fk_grit_screening_history_masters"
  add_foreign_key "grit_screening_history", "users", name: "fk_grit_screening_history_users"
  add_foreign_key "grit_screenings", "masters"
  add_foreign_key "grit_screenings", "users"
  add_foreign_key "grit_secure_note_history", "grit_secure_notes", name: "fk_grit_secure_note_history_grit_secure_notes"
  add_foreign_key "grit_secure_note_history", "masters", name: "fk_grit_secure_note_history_masters"
  add_foreign_key "grit_secure_note_history", "users", name: "fk_grit_secure_note_history_users"
  add_foreign_key "grit_secure_notes", "masters"
  add_foreign_key "grit_secure_notes", "users"
  add_foreign_key "grit_withdrawal_history", "grit_withdrawals", name: "fk_grit_withdrawal_history_grit_withdrawals"
  add_foreign_key "grit_withdrawal_history", "masters", name: "fk_grit_withdrawal_history_masters"
  add_foreign_key "grit_withdrawal_history", "users", name: "fk_grit_withdrawal_history_users"
  add_foreign_key "grit_withdrawals", "masters"
  add_foreign_key "grit_withdrawals", "users"
  add_foreign_key "imports", "users"
  add_foreign_key "ipa_adl_informant_screener_history", "ipa_adl_informant_screeners", name: "fk_ipa_adl_informant_screener_history_ipa_adl_informant_screene"
  add_foreign_key "ipa_adl_informant_screener_history", "masters", name: "fk_ipa_adl_informant_screener_history_masters"
  add_foreign_key "ipa_adl_informant_screener_history", "users", name: "fk_ipa_adl_informant_screener_history_users"
  add_foreign_key "ipa_adl_informant_screeners", "masters"
  add_foreign_key "ipa_adl_informant_screeners", "users"
  add_foreign_key "ipa_adverse_event_history", "ipa_adverse_events", name: "fk_ipa_adverse_event_history_ipa_adverse_events"
  add_foreign_key "ipa_adverse_event_history", "masters", name: "fk_ipa_adverse_event_history_masters"
  add_foreign_key "ipa_adverse_event_history", "users", name: "fk_ipa_adverse_event_history_users"
  add_foreign_key "ipa_adverse_events", "masters"
  add_foreign_key "ipa_adverse_events", "users"
  add_foreign_key "ipa_appointment_history", "ipa_appointments", name: "fk_ipa_appointment_history_ipa_appointments"
  add_foreign_key "ipa_appointment_history", "masters", name: "fk_ipa_appointment_history_masters"
  add_foreign_key "ipa_appointment_history", "users", name: "fk_ipa_appointment_history_users"
  add_foreign_key "ipa_appointments", "masters"
  add_foreign_key "ipa_appointments", "users"
  add_foreign_key "ipa_assignment_history", "admins", name: "fk_ipa_assignment_history_admins"
  add_foreign_key "ipa_assignment_history", "ipa_assignments", column: "ipa_assignment_table_id", name: "fk_ipa_assignment_history_ipa_assignments"
  add_foreign_key "ipa_assignment_history", "masters", name: "fk_ipa_assignment_history_masters"
  add_foreign_key "ipa_assignment_history", "users", name: "fk_ipa_assignment_history_users"
  add_foreign_key "ipa_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "ipa_assignments", "masters"
  add_foreign_key "ipa_assignments", "users"
  add_foreign_key "ipa_consent_mailing_history", "ipa_consent_mailings", name: "fk_ipa_consent_mailing_history_ipa_consent_mailings"
  add_foreign_key "ipa_consent_mailing_history", "masters", name: "fk_ipa_consent_mailing_history_masters"
  add_foreign_key "ipa_consent_mailing_history", "users", name: "fk_ipa_consent_mailing_history_users"
  add_foreign_key "ipa_consent_mailings", "masters"
  add_foreign_key "ipa_consent_mailings", "users"
  add_foreign_key "ipa_covid_prescreening_history", "ipa_covid_prescreenings"
  add_foreign_key "ipa_covid_prescreening_history", "masters"
  add_foreign_key "ipa_covid_prescreening_history", "users"
  add_foreign_key "ipa_covid_prescreenings", "masters"
  add_foreign_key "ipa_covid_prescreenings", "users"
  add_foreign_key "ipa_exit_interview_history", "ipa_exit_interviews", name: "fk_ipa_exit_interview_history_ipa_exit_interviews"
  add_foreign_key "ipa_exit_interview_history", "masters", name: "fk_ipa_exit_interview_history_masters"
  add_foreign_key "ipa_exit_interview_history", "users", name: "fk_ipa_exit_interview_history_users"
  add_foreign_key "ipa_exit_interviews", "masters"
  add_foreign_key "ipa_exit_interviews", "users"
  add_foreign_key "ipa_file_creator_history", "ipa_file_creators", name: "fk_ipa_file_creator_history_ipa_file_creators"
  add_foreign_key "ipa_file_creator_history", "users", name: "fk_ipa_file_creator_history_users"
  add_foreign_key "ipa_file_creators", "users"
  add_foreign_key "ipa_four_wk_followup_history", "ipa_four_wk_followups", name: "fk_ipa_four_wk_followup_history_ipa_four_wk_followups"
  add_foreign_key "ipa_four_wk_followup_history", "masters", name: "fk_ipa_four_wk_followup_history_masters"
  add_foreign_key "ipa_four_wk_followup_history", "users", name: "fk_ipa_four_wk_followup_history_users"
  add_foreign_key "ipa_four_wk_followups", "masters"
  add_foreign_key "ipa_four_wk_followups", "users"
  add_foreign_key "ipa_hotel_history", "ipa_hotels", name: "fk_ipa_hotel_history_ipa_hotels"
  add_foreign_key "ipa_hotel_history", "masters", name: "fk_ipa_hotel_history_masters"
  add_foreign_key "ipa_hotel_history", "users", name: "fk_ipa_hotel_history_users"
  add_foreign_key "ipa_hotels", "masters"
  add_foreign_key "ipa_hotels", "users"
  add_foreign_key "ipa_incidental_finding_history", "ipa_incidental_findings", name: "fk_ipa_incidental_finding_history_ipa_incidental_findings"
  add_foreign_key "ipa_incidental_finding_history", "masters", name: "fk_ipa_incidental_finding_history_masters"
  add_foreign_key "ipa_incidental_finding_history", "users", name: "fk_ipa_incidental_finding_history_users"
  add_foreign_key "ipa_incidental_findings", "masters"
  add_foreign_key "ipa_incidental_findings", "users"
  add_foreign_key "ipa_inex_checklist_history", "ipa_inex_checklists", name: "fk_ipa_inex_checklist_history_ipa_inex_checklists"
  add_foreign_key "ipa_inex_checklist_history", "masters", name: "fk_ipa_inex_checklist_history_masters"
  add_foreign_key "ipa_inex_checklist_history", "users", name: "fk_ipa_inex_checklist_history_users"
  add_foreign_key "ipa_inex_checklists", "masters"
  add_foreign_key "ipa_inex_checklists", "users"
  add_foreign_key "ipa_initial_screening_history", "ipa_initial_screenings", name: "fk_ipa_initial_screening_history_ipa_initial_screenings"
  add_foreign_key "ipa_initial_screening_history", "masters", name: "fk_ipa_initial_screening_history_masters"
  add_foreign_key "ipa_initial_screening_history", "users", name: "fk_ipa_initial_screening_history_users"
  add_foreign_key "ipa_initial_screenings", "masters"
  add_foreign_key "ipa_initial_screenings", "users"
  add_foreign_key "ipa_medical_detail_history", "ipa_medical_details", name: "fk_ipa_medical_detail_history_ipa_medical_details"
  add_foreign_key "ipa_medical_detail_history", "masters", name: "fk_ipa_medical_detail_history_masters"
  add_foreign_key "ipa_medical_detail_history", "users", name: "fk_ipa_medical_detail_history_users"
  add_foreign_key "ipa_medical_details", "masters"
  add_foreign_key "ipa_medical_details", "users"
  add_foreign_key "ipa_medication_history", "ipa_medications", name: "fk_ipa_medication_history_ipa_medications"
  add_foreign_key "ipa_medication_history", "masters", name: "fk_ipa_medication_history_masters"
  add_foreign_key "ipa_medication_history", "users", name: "fk_ipa_medication_history_users"
  add_foreign_key "ipa_medications", "masters"
  add_foreign_key "ipa_medications", "users"
  add_foreign_key "ipa_mednav_followup_history", "ipa_mednav_followups", name: "fk_ipa_mednav_followup_history_ipa_mednav_followups"
  add_foreign_key "ipa_mednav_followup_history", "masters", name: "fk_ipa_mednav_followup_history_masters"
  add_foreign_key "ipa_mednav_followup_history", "users", name: "fk_ipa_mednav_followup_history_users"
  add_foreign_key "ipa_mednav_followups", "masters"
  add_foreign_key "ipa_mednav_followups", "users"
  add_foreign_key "ipa_mednav_provider_comm_history", "ipa_mednav_provider_comms", name: "fk_ipa_mednav_provider_comm_history_ipa_mednav_provider_comms"
  add_foreign_key "ipa_mednav_provider_comm_history", "masters", name: "fk_ipa_mednav_provider_comm_history_masters"
  add_foreign_key "ipa_mednav_provider_comm_history", "users", name: "fk_ipa_mednav_provider_comm_history_users"
  add_foreign_key "ipa_mednav_provider_comms", "masters"
  add_foreign_key "ipa_mednav_provider_comms", "users"
  add_foreign_key "ipa_mednav_provider_report_history", "ipa_mednav_provider_reports", name: "fk_ipa_mednav_provider_report_history_ipa_mednav_provider_repor"
  add_foreign_key "ipa_mednav_provider_report_history", "masters", name: "fk_ipa_mednav_provider_report_history_masters"
  add_foreign_key "ipa_mednav_provider_report_history", "users", name: "fk_ipa_mednav_provider_report_history_users"
  add_foreign_key "ipa_mednav_provider_reports", "masters"
  add_foreign_key "ipa_mednav_provider_reports", "users"
  add_foreign_key "ipa_payment_history", "ipa_payments", name: "fk_ipa_payment_history_ipa_payments"
  add_foreign_key "ipa_payment_history", "masters", name: "fk_ipa_payment_history_masters"
  add_foreign_key "ipa_payment_history", "users", name: "fk_ipa_payment_history_users"
  add_foreign_key "ipa_payments", "masters"
  add_foreign_key "ipa_payments", "users"
  add_foreign_key "ipa_protocol_deviation_history", "ipa_protocol_deviations", name: "fk_ipa_protocol_deviation_history_ipa_protocol_deviations"
  add_foreign_key "ipa_protocol_deviation_history", "masters", name: "fk_ipa_protocol_deviation_history_masters"
  add_foreign_key "ipa_protocol_deviation_history", "users", name: "fk_ipa_protocol_deviation_history_users"
  add_foreign_key "ipa_protocol_deviations", "masters"
  add_foreign_key "ipa_protocol_deviations", "users"
  add_foreign_key "ipa_protocol_exception_history", "ipa_protocol_exceptions", name: "fk_ipa_protocol_exception_history_ipa_protocol_exceptions"
  add_foreign_key "ipa_protocol_exception_history", "masters", name: "fk_ipa_protocol_exception_history_masters"
  add_foreign_key "ipa_protocol_exception_history", "users", name: "fk_ipa_protocol_exception_history_users"
  add_foreign_key "ipa_protocol_exceptions", "masters"
  add_foreign_key "ipa_protocol_exceptions", "users"
  add_foreign_key "ipa_ps_comp_review_history", "ipa_ps_comp_reviews", name: "fk_ipa_ps_comp_review_history_ipa_ps_comp_reviews"
  add_foreign_key "ipa_ps_comp_review_history", "masters", name: "fk_ipa_ps_comp_review_history_masters"
  add_foreign_key "ipa_ps_comp_review_history", "users", name: "fk_ipa_ps_comp_review_history_users"
  add_foreign_key "ipa_ps_comp_reviews", "masters"
  add_foreign_key "ipa_ps_comp_reviews", "users"
  add_foreign_key "ipa_ps_covid_closing_history", "ipa_ps_covid_closings"
  add_foreign_key "ipa_ps_covid_closing_history", "masters"
  add_foreign_key "ipa_ps_covid_closing_history", "users"
  add_foreign_key "ipa_ps_covid_closings", "masters"
  add_foreign_key "ipa_ps_covid_closings", "users"
  add_foreign_key "ipa_ps_football_experience_history", "ipa_ps_football_experiences", name: "fk_ipa_ps_football_experience_history_ipa_ps_football_experienc"
  add_foreign_key "ipa_ps_football_experience_history", "masters", name: "fk_ipa_ps_football_experience_history_masters"
  add_foreign_key "ipa_ps_football_experience_history", "users", name: "fk_ipa_ps_football_experience_history_users"
  add_foreign_key "ipa_ps_football_experiences", "masters"
  add_foreign_key "ipa_ps_football_experiences", "users"
  add_foreign_key "ipa_ps_health_history", "ipa_ps_healths", name: "fk_ipa_ps_health_history_ipa_ps_healths"
  add_foreign_key "ipa_ps_health_history", "masters", name: "fk_ipa_ps_health_history_masters"
  add_foreign_key "ipa_ps_health_history", "users", name: "fk_ipa_ps_health_history_users"
  add_foreign_key "ipa_ps_healths", "masters"
  add_foreign_key "ipa_ps_healths", "users"
  add_foreign_key "ipa_ps_informant_detail_history", "ipa_ps_informant_details", name: "fk_ipa_ps_informant_detail_history_ipa_ps_informant_details"
  add_foreign_key "ipa_ps_informant_detail_history", "masters", name: "fk_ipa_ps_informant_detail_history_masters"
  add_foreign_key "ipa_ps_informant_detail_history", "users", name: "fk_ipa_ps_informant_detail_history_users"
  add_foreign_key "ipa_ps_informant_details", "masters"
  add_foreign_key "ipa_ps_informant_details", "users"
  add_foreign_key "ipa_ps_initial_screening_history", "ipa_ps_initial_screenings", name: "fk_ipa_ps_initial_screening_history_ipa_ps_initial_screenings"
  add_foreign_key "ipa_ps_initial_screening_history", "masters", name: "fk_ipa_ps_initial_screening_history_masters"
  add_foreign_key "ipa_ps_initial_screening_history", "users", name: "fk_ipa_ps_initial_screening_history_users"
  add_foreign_key "ipa_ps_initial_screenings", "masters"
  add_foreign_key "ipa_ps_initial_screenings", "users"
  add_foreign_key "ipa_ps_mri_history", "ipa_ps_mris", name: "fk_ipa_ps_mri_history_ipa_ps_mris"
  add_foreign_key "ipa_ps_mri_history", "masters", name: "fk_ipa_ps_mri_history_masters"
  add_foreign_key "ipa_ps_mri_history", "users", name: "fk_ipa_ps_mri_history_users"
  add_foreign_key "ipa_ps_mris", "masters"
  add_foreign_key "ipa_ps_mris", "users"
  add_foreign_key "ipa_ps_size_history", "ipa_ps_sizes", name: "fk_ipa_ps_size_history_ipa_ps_sizes"
  add_foreign_key "ipa_ps_size_history", "masters", name: "fk_ipa_ps_size_history_masters"
  add_foreign_key "ipa_ps_size_history", "users", name: "fk_ipa_ps_size_history_users"
  add_foreign_key "ipa_ps_sizes", "masters"
  add_foreign_key "ipa_ps_sizes", "users"
  add_foreign_key "ipa_ps_sleep_history", "ipa_ps_sleeps", name: "fk_ipa_ps_sleep_history_ipa_ps_sleeps"
  add_foreign_key "ipa_ps_sleep_history", "masters", name: "fk_ipa_ps_sleep_history_masters"
  add_foreign_key "ipa_ps_sleep_history", "users", name: "fk_ipa_ps_sleep_history_users"
  add_foreign_key "ipa_ps_sleeps", "masters"
  add_foreign_key "ipa_ps_sleeps", "users"
  add_foreign_key "ipa_ps_tmoca_history", "ipa_ps_tmocas", name: "fk_ipa_ps_tmoca_history_ipa_ps_tmocas"
  add_foreign_key "ipa_ps_tmoca_history", "masters", name: "fk_ipa_ps_tmoca_history_masters"
  add_foreign_key "ipa_ps_tmoca_history", "users", name: "fk_ipa_ps_tmoca_history_users"
  add_foreign_key "ipa_ps_tmocas", "masters"
  add_foreign_key "ipa_ps_tmocas", "users"
  add_foreign_key "ipa_ps_tms_test_history", "ipa_ps_tms_tests", name: "fk_ipa_ps_tms_test_history_ipa_ps_tms_tests"
  add_foreign_key "ipa_ps_tms_test_history", "masters", name: "fk_ipa_ps_tms_test_history_masters"
  add_foreign_key "ipa_ps_tms_test_history", "users", name: "fk_ipa_ps_tms_test_history_users"
  add_foreign_key "ipa_ps_tms_tests", "masters"
  add_foreign_key "ipa_ps_tms_tests", "users"
  add_foreign_key "ipa_reimbursement_req_history", "ipa_reimbursement_reqs", name: "fk_ipa_reimbursement_req_history_ipa_reimbursement_reqs"
  add_foreign_key "ipa_reimbursement_req_history", "masters", name: "fk_ipa_reimbursement_req_history_masters"
  add_foreign_key "ipa_reimbursement_req_history", "users", name: "fk_ipa_reimbursement_req_history_users"
  add_foreign_key "ipa_reimbursement_reqs", "masters"
  add_foreign_key "ipa_reimbursement_reqs", "users"
  add_foreign_key "ipa_screening_history", "ipa_screenings", name: "fk_ipa_screening_history_ipa_screenings"
  add_foreign_key "ipa_screening_history", "masters", name: "fk_ipa_screening_history_masters"
  add_foreign_key "ipa_screening_history", "users", name: "fk_ipa_screening_history_users"
  add_foreign_key "ipa_screenings", "masters"
  add_foreign_key "ipa_screenings", "users"
  add_foreign_key "ipa_special_consideration_history", "ipa_special_considerations", name: "fk_ipa_special_consideration_history_ipa_special_considerations"
  add_foreign_key "ipa_special_consideration_history", "masters", name: "fk_ipa_special_consideration_history_masters"
  add_foreign_key "ipa_special_consideration_history", "users", name: "fk_ipa_special_consideration_history_users"
  add_foreign_key "ipa_special_considerations", "masters"
  add_foreign_key "ipa_special_considerations", "users"
  add_foreign_key "ipa_station_contact_history", "ipa_station_contacts", name: "fk_ipa_station_contact_history_ipa_station_contacts"
  add_foreign_key "ipa_station_contact_history", "users", name: "fk_ipa_station_contact_history_users"
  add_foreign_key "ipa_station_contacts", "users"
  add_foreign_key "ipa_survey_history", "ipa_surveys", name: "fk_ipa_survey_history_ipa_surveys"
  add_foreign_key "ipa_survey_history", "masters", name: "fk_ipa_survey_history_masters"
  add_foreign_key "ipa_survey_history", "users", name: "fk_ipa_survey_history_users"
  add_foreign_key "ipa_surveys", "masters"
  add_foreign_key "ipa_surveys", "users"
  add_foreign_key "ipa_transportation_history", "ipa_transportations", name: "fk_ipa_transportation_history_ipa_transportations"
  add_foreign_key "ipa_transportation_history", "masters", name: "fk_ipa_transportation_history_masters"
  add_foreign_key "ipa_transportation_history", "users", name: "fk_ipa_transportation_history_users"
  add_foreign_key "ipa_transportations", "masters"
  add_foreign_key "ipa_transportations", "users"
  add_foreign_key "ipa_two_wk_followup_history", "ipa_two_wk_followups", name: "fk_ipa_two_wk_followup_history_ipa_two_wk_followups"
  add_foreign_key "ipa_two_wk_followup_history", "masters", name: "fk_ipa_two_wk_followup_history_masters"
  add_foreign_key "ipa_two_wk_followup_history", "users", name: "fk_ipa_two_wk_followup_history_users"
  add_foreign_key "ipa_two_wk_followups", "masters"
  add_foreign_key "ipa_two_wk_followups", "users"
  add_foreign_key "ipa_withdrawal_history", "ipa_withdrawals", name: "fk_ipa_withdrawal_history_ipa_withdrawals"
  add_foreign_key "ipa_withdrawal_history", "masters", name: "fk_ipa_withdrawal_history_masters"
  add_foreign_key "ipa_withdrawal_history", "users", name: "fk_ipa_withdrawal_history_users"
  add_foreign_key "ipa_withdrawals", "masters"
  add_foreign_key "ipa_withdrawals", "users"
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
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "grit.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "sleep.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "tbs.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "grit.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "sleep.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "tbs.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "grit.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "sleep.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "tbs.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "admins", name: "fk_mrn_number_history_admins"
  add_foreign_key "mrn_number_history", "grit.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "masters", name: "fk_mrn_number_history_masters"
  add_foreign_key "mrn_number_history", "mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "sleep.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "tbs.mrn_numbers", column: "mrn_number_table_id", name: "fk_mrn_number_history_mrn_numbers"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_number_history", "users", name: "fk_mrn_number_history_users"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "masters"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "mrn_numbers", "users"
  add_foreign_key "msm_grit_id_number_history", "admins", name: "fk_msm_grit_id_number_history_admins"
  add_foreign_key "msm_grit_id_number_history", "masters", name: "fk_msm_grit_id_number_history_masters"
  add_foreign_key "msm_grit_id_number_history", "msm_grit_id_numbers", column: "msm_grit_id_number_table_id", name: "fk_msm_grit_id_number_history_msm_grit_id_numbers"
  add_foreign_key "msm_grit_id_number_history", "users", name: "fk_msm_grit_id_number_history_users"
  add_foreign_key "msm_grit_id_numbers", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "msm_grit_id_numbers", "masters"
  add_foreign_key "msm_grit_id_numbers", "users"
  add_foreign_key "new_test_history", "admins", name: "fk_new_test_history_admins"
  add_foreign_key "new_test_history", "masters", name: "fk_new_test_history_masters"
  add_foreign_key "new_test_history", "new_tests", column: "new_test_table_id", name: "fk_new_test_history_new_tests"
  add_foreign_key "new_test_history", "users", name: "fk_new_test_history_users"
  add_foreign_key "new_tests", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "new_tests", "masters"
  add_foreign_key "new_tests", "users"
  add_foreign_key "nfs_store_archived_file_history", "nfs_store_archived_files", name: "fk_nfs_store_archived_file_history_nfs_store_archived_files"
  add_foreign_key "nfs_store_archived_file_history", "nfs_store_archived_files", name: "fk_nfs_store_archived_file_history_nfs_store_archived_files"
  add_foreign_key "nfs_store_archived_file_history", "users", name: "fk_nfs_store_archived_file_history_users"
  add_foreign_key "nfs_store_archived_file_history", "users", name: "fk_nfs_store_archived_file_history_users"
  add_foreign_key "nfs_store_archived_file_history", "nfs_store_archived_files", name: "fk_nfs_store_archived_file_history_nfs_store_archived_files"
  add_foreign_key "nfs_store_archived_file_history", "nfs_store_archived_files", name: "fk_nfs_store_archived_file_history_nfs_store_archived_files"
  add_foreign_key "nfs_store_archived_file_history", "users", name: "fk_nfs_store_archived_file_history_users"
  add_foreign_key "nfs_store_archived_file_history", "users", name: "fk_nfs_store_archived_file_history_users"
  add_foreign_key "nfs_store_archived_files", "nfs_store_containers"
  add_foreign_key "nfs_store_archived_files", "nfs_store_stored_files"
  add_foreign_key "nfs_store_archived_files", "users"
  add_foreign_key "nfs_store_container_history", "masters", name: "fk_nfs_store_container_history_masters"
  add_foreign_key "nfs_store_container_history", "masters", name: "fk_nfs_store_container_history_masters"
  add_foreign_key "nfs_store_container_history", "nfs_store_containers", name: "fk_nfs_store_container_history_nfs_store_containers"
  add_foreign_key "nfs_store_container_history", "nfs_store_containers", name: "fk_nfs_store_container_history_nfs_store_containers"
  add_foreign_key "nfs_store_container_history", "users", name: "fk_nfs_store_container_history_users"
  add_foreign_key "nfs_store_container_history", "users", name: "fk_nfs_store_container_history_users"
  add_foreign_key "nfs_store_container_history", "masters", name: "fk_nfs_store_container_history_masters"
  add_foreign_key "nfs_store_container_history", "masters", name: "fk_nfs_store_container_history_masters"
  add_foreign_key "nfs_store_container_history", "nfs_store_containers", name: "fk_nfs_store_container_history_nfs_store_containers"
  add_foreign_key "nfs_store_container_history", "nfs_store_containers", name: "fk_nfs_store_container_history_nfs_store_containers"
  add_foreign_key "nfs_store_container_history", "users", name: "fk_nfs_store_container_history_users"
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
  add_foreign_key "nfs_store_stored_file_history", "nfs_store_stored_files", name: "fk_nfs_store_stored_file_history_nfs_store_stored_files"
  add_foreign_key "nfs_store_stored_file_history", "users", name: "fk_nfs_store_stored_file_history_users"
  add_foreign_key "nfs_store_stored_file_history", "users", name: "fk_nfs_store_stored_file_history_users"
  add_foreign_key "nfs_store_stored_file_history", "nfs_store_stored_files", name: "fk_nfs_store_stored_file_history_nfs_store_stored_files"
  add_foreign_key "nfs_store_stored_file_history", "nfs_store_stored_files", name: "fk_nfs_store_stored_file_history_nfs_store_stored_files"
  add_foreign_key "nfs_store_stored_file_history", "users", name: "fk_nfs_store_stored_file_history_users"
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
  add_foreign_key "persnet_assignment_history", "admins", name: "fk_persnet_assignment_history_admins"
  add_foreign_key "persnet_assignment_history", "masters", name: "fk_persnet_assignment_history_masters"
  add_foreign_key "persnet_assignment_history", "persnet_assignments", column: "persnet_assignment_table_id", name: "fk_persnet_assignment_history_persnet_assignments"
  add_foreign_key "persnet_assignment_history", "users", name: "fk_persnet_assignment_history_users"
  add_foreign_key "persnet_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "persnet_assignments", "masters"
  add_foreign_key "persnet_assignments", "users"
  add_foreign_key "pitt_bhi_access_pi_history", "masters"
  add_foreign_key "pitt_bhi_access_pi_history", "pitt_bhi_access_pis"
  add_foreign_key "pitt_bhi_access_pi_history", "users"
  add_foreign_key "pitt_bhi_access_pis", "masters"
  add_foreign_key "pitt_bhi_access_pis", "users"
  add_foreign_key "pitt_bhi_access_pitt_staff_history", "masters"
  add_foreign_key "pitt_bhi_access_pitt_staff_history", "pitt_bhi_access_pitt_staffs"
  add_foreign_key "pitt_bhi_access_pitt_staff_history", "users"
  add_foreign_key "pitt_bhi_access_pitt_staffs", "masters"
  add_foreign_key "pitt_bhi_access_pitt_staffs", "users"
  add_foreign_key "pitt_bhi_appointment_history", "masters"
  add_foreign_key "pitt_bhi_appointment_history", "pitt_bhi_appointments"
  add_foreign_key "pitt_bhi_appointment_history", "users"
  add_foreign_key "pitt_bhi_appointments", "masters"
  add_foreign_key "pitt_bhi_appointments", "users"
  add_foreign_key "pitt_bhi_assignment_history", "admins"
  add_foreign_key "pitt_bhi_assignment_history", "masters"
  add_foreign_key "pitt_bhi_assignment_history", "pitt_bhi_assignments", column: "pitt_bhi_assignment_table_id"
  add_foreign_key "pitt_bhi_assignment_history", "users"
  add_foreign_key "pitt_bhi_assignments", "admins"
  add_foreign_key "pitt_bhi_assignments", "masters"
  add_foreign_key "pitt_bhi_assignments", "users"
  add_foreign_key "pitt_bhi_ps_eligibility_followup_history", "masters"
  add_foreign_key "pitt_bhi_ps_eligibility_followup_history", "pitt_bhi_ps_eligibility_followups"
  add_foreign_key "pitt_bhi_ps_eligibility_followup_history", "users"
  add_foreign_key "pitt_bhi_ps_eligibility_followups", "masters"
  add_foreign_key "pitt_bhi_ps_eligibility_followups", "users"
  add_foreign_key "pitt_bhi_ps_eligible_history", "masters"
  add_foreign_key "pitt_bhi_ps_eligible_history", "pitt_bhi_ps_eligibles"
  add_foreign_key "pitt_bhi_ps_eligible_history", "users"
  add_foreign_key "pitt_bhi_ps_eligibles", "masters"
  add_foreign_key "pitt_bhi_ps_eligibles", "users"
  add_foreign_key "pitt_bhi_ps_initial_screening_history", "masters"
  add_foreign_key "pitt_bhi_ps_initial_screening_history", "pitt_bhi_ps_initial_screenings"
  add_foreign_key "pitt_bhi_ps_initial_screening_history", "users"
  add_foreign_key "pitt_bhi_ps_initial_screenings", "masters"
  add_foreign_key "pitt_bhi_ps_initial_screenings", "users"
  add_foreign_key "pitt_bhi_ps_non_eligible_history", "masters"
  add_foreign_key "pitt_bhi_ps_non_eligible_history", "pitt_bhi_ps_non_eligibles"
  add_foreign_key "pitt_bhi_ps_non_eligible_history", "users"
  add_foreign_key "pitt_bhi_ps_non_eligibles", "masters"
  add_foreign_key "pitt_bhi_ps_non_eligibles", "users"
  add_foreign_key "pitt_bhi_ps_screener_response_history", "masters"
  add_foreign_key "pitt_bhi_ps_screener_response_history", "pitt_bhi_ps_screener_responses"
  add_foreign_key "pitt_bhi_ps_screener_response_history", "users"
  add_foreign_key "pitt_bhi_ps_screener_responses", "masters"
  add_foreign_key "pitt_bhi_ps_screener_responses", "users"
  add_foreign_key "pitt_bhi_ps_suitability_question_history", "masters"
  add_foreign_key "pitt_bhi_ps_suitability_question_history", "pitt_bhi_ps_suitability_questions"
  add_foreign_key "pitt_bhi_ps_suitability_question_history", "users"
  add_foreign_key "pitt_bhi_ps_suitability_questions", "masters"
  add_foreign_key "pitt_bhi_ps_suitability_questions", "users"
  add_foreign_key "pitt_bhi_screening_history", "masters"
  add_foreign_key "pitt_bhi_screening_history", "pitt_bhi_screenings"
  add_foreign_key "pitt_bhi_screening_history", "users"
  add_foreign_key "pitt_bhi_screenings", "masters"
  add_foreign_key "pitt_bhi_screenings", "users"
  add_foreign_key "pitt_bhi_secure_note_history", "masters"
  add_foreign_key "pitt_bhi_secure_note_history", "pitt_bhi_secure_notes"
  add_foreign_key "pitt_bhi_secure_note_history", "users"
  add_foreign_key "pitt_bhi_secure_notes", "masters"
  add_foreign_key "pitt_bhi_secure_notes", "users"
  add_foreign_key "pitt_bhi_withdrawal_history", "masters"
  add_foreign_key "pitt_bhi_withdrawal_history", "pitt_bhi_withdrawals"
  add_foreign_key "pitt_bhi_withdrawal_history", "users"
  add_foreign_key "pitt_bhi_withdrawals", "masters"
  add_foreign_key "pitt_bhi_withdrawals", "users"
  add_foreign_key "player_career_data", "masters"
  add_foreign_key "player_career_data", "users"
  add_foreign_key "player_career_data_history", "masters", name: "fk_player_career_data_history_masters"
  add_foreign_key "player_career_data_history", "player_career_data", column: "player_career_data_id", name: "fk_player_career_data_history_player_career_data"
  add_foreign_key "player_career_data_history", "users", name: "fk_player_career_data_history_users"
  add_foreign_key "player_contact_history", "masters", name: "fk_player_contact_history_masters"
  add_foreign_key "player_contact_history", "player_contacts", name: "fk_player_contact_history_player_contacts"
  add_foreign_key "player_contact_history", "users", name: "fk_player_contact_history_users"
  add_foreign_key "player_contact_phone_info_history", "masters", name: "fk_player_contact_phone_info_history_masters"
  add_foreign_key "player_contact_phone_info_history", "player_contact_phone_infos", name: "fk_player_contact_phone_info_history_player_contact_phone_infos"
  add_foreign_key "player_contact_phone_info_history", "users", name: "fk_player_contact_phone_info_history_users"
  add_foreign_key "player_contact_phone_infos", "masters"
  add_foreign_key "player_contact_phone_infos", "users"
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
  add_foreign_key "rc_femfl_cif", "masters"
  add_foreign_key "report_history", "reports", name: "fk_report_history_reports"
  add_foreign_key "reports", "admins"
  add_foreign_key "sage_assignments", "admins"
  add_foreign_key "sage_assignments", "masters"
  add_foreign_key "sage_assignments", "users"
  add_foreign_key "scantron_history", "masters", name: "fk_scantron_history_masters"
  add_foreign_key "scantron_history", "scantrons", column: "scantron_table_id", name: "fk_scantron_history_scantrons"
  add_foreign_key "scantron_history", "users", name: "fk_scantron_history_users"
  add_foreign_key "scantron_q2_history", "admins", name: "fk_scantron_q2_history_admins"
  add_foreign_key "scantron_q2_history", "masters", name: "fk_scantron_q2_history_masters"
  add_foreign_key "scantron_q2_history", "scantron_q2s", column: "scantron_q2_table_id", name: "fk_scantron_q2_history_scantron_q2s"
  add_foreign_key "scantron_q2_history", "users", name: "fk_scantron_q2_history_users"
  add_foreign_key "scantron_q2s", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "scantron_q2s", "masters"
  add_foreign_key "scantron_q2s", "users"
  add_foreign_key "scantrons", "masters"
  add_foreign_key "scantrons", "users"
  add_foreign_key "sleep_access_bwh_staff_history", "masters", name: "fk_sleep_access_bwh_staff_history_masters"
  add_foreign_key "sleep_access_bwh_staff_history", "sleep_access_bwh_staffs", name: "fk_sleep_access_bwh_staff_history_sleep_access_bwh_staffs"
  add_foreign_key "sleep_access_bwh_staff_history", "users", name: "fk_sleep_access_bwh_staff_history_users"
  add_foreign_key "sleep_access_bwh_staffs", "masters"
  add_foreign_key "sleep_access_bwh_staffs", "users"
  add_foreign_key "sleep_access_interventionist_history", "masters", name: "fk_sleep_access_interventionist_history_masters"
  add_foreign_key "sleep_access_interventionist_history", "sleep_access_interventionists", name: "fk_sleep_access_interventionist_history_sleep_access_interventi"
  add_foreign_key "sleep_access_interventionist_history", "users", name: "fk_sleep_access_interventionist_history_users"
  add_foreign_key "sleep_access_interventionists", "masters"
  add_foreign_key "sleep_access_interventionists", "users"
  add_foreign_key "sleep_access_pi_history", "masters", name: "fk_sleep_access_pi_history_masters"
  add_foreign_key "sleep_access_pi_history", "sleep_access_pis", name: "fk_sleep_access_pi_history_sleep_access_pis"
  add_foreign_key "sleep_access_pi_history", "users", name: "fk_sleep_access_pi_history_users"
  add_foreign_key "sleep_access_pis", "masters"
  add_foreign_key "sleep_access_pis", "users"
  add_foreign_key "sleep_adverse_event_history", "masters", name: "fk_sleep_adverse_event_history_masters"
  add_foreign_key "sleep_adverse_event_history", "sleep_adverse_events", name: "fk_sleep_adverse_event_history_sleep_adverse_events"
  add_foreign_key "sleep_adverse_event_history", "users", name: "fk_sleep_adverse_event_history_users"
  add_foreign_key "sleep_adverse_events", "masters"
  add_foreign_key "sleep_adverse_events", "users"
  add_foreign_key "sleep_appointment_history", "masters", name: "fk_sleep_appointment_history_masters"
  add_foreign_key "sleep_appointment_history", "sleep_appointments", name: "fk_sleep_appointment_history_sleep_appointments"
  add_foreign_key "sleep_appointment_history", "users", name: "fk_sleep_appointment_history_users"
  add_foreign_key "sleep_appointments", "masters"
  add_foreign_key "sleep_appointments", "users"
  add_foreign_key "sleep_assignment_history", "admins", name: "fk_sleep_assignment_history_admins"
  add_foreign_key "sleep_assignment_history", "admins", name: "fk_sleep_assignment_history_admins"
  add_foreign_key "sleep_assignment_history", "masters", name: "fk_sleep_assignment_history_masters"
  add_foreign_key "sleep_assignment_history", "masters", name: "fk_sleep_assignment_history_masters"
  add_foreign_key "sleep_assignment_history", "sleep.sleep_assignments", column: "sleep_assignment_table_id", name: "fk_sleep_assignment_history_sleep_assignments"
  add_foreign_key "sleep_assignment_history", "sleep_assignments", column: "sleep_assignment_table_id", name: "fk_sleep_assignment_history_sleep_assignments"
  add_foreign_key "sleep_assignment_history", "users", name: "fk_sleep_assignment_history_users"
  add_foreign_key "sleep_assignment_history", "users", name: "fk_sleep_assignment_history_users"
  add_foreign_key "sleep_assignment_history", "admins", name: "fk_sleep_assignment_history_admins"
  add_foreign_key "sleep_assignment_history", "admins", name: "fk_sleep_assignment_history_admins"
  add_foreign_key "sleep_assignment_history", "masters", name: "fk_sleep_assignment_history_masters"
  add_foreign_key "sleep_assignment_history", "masters", name: "fk_sleep_assignment_history_masters"
  add_foreign_key "sleep_assignment_history", "sleep.sleep_assignments", column: "sleep_assignment_table_id", name: "fk_sleep_assignment_history_sleep_assignments"
  add_foreign_key "sleep_assignment_history", "sleep_assignments", column: "sleep_assignment_table_id", name: "fk_sleep_assignment_history_sleep_assignments"
  add_foreign_key "sleep_assignment_history", "users", name: "fk_sleep_assignment_history_users"
  add_foreign_key "sleep_assignment_history", "users", name: "fk_sleep_assignment_history_users"
  add_foreign_key "sleep_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "sleep_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "sleep_assignments", "masters"
  add_foreign_key "sleep_assignments", "masters"
  add_foreign_key "sleep_assignments", "users"
  add_foreign_key "sleep_assignments", "users"
  add_foreign_key "sleep_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "sleep_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "sleep_assignments", "masters"
  add_foreign_key "sleep_assignments", "masters"
  add_foreign_key "sleep_assignments", "users"
  add_foreign_key "sleep_assignments", "users"
  add_foreign_key "sleep_consent_mailing_history", "masters", name: "fk_sleep_consent_mailing_history_masters"
  add_foreign_key "sleep_consent_mailing_history", "sleep_consent_mailings", name: "fk_sleep_consent_mailing_history_sleep_consent_mailings"
  add_foreign_key "sleep_consent_mailing_history", "users", name: "fk_sleep_consent_mailing_history_users"
  add_foreign_key "sleep_consent_mailings", "masters"
  add_foreign_key "sleep_consent_mailings", "users"
  add_foreign_key "sleep_ese_question_history", "masters", name: "fk_sleep_ese_question_history_masters"
  add_foreign_key "sleep_ese_question_history", "sleep_ese_questions", name: "fk_sleep_ese_question_history_sleep_ese_questions"
  add_foreign_key "sleep_ese_question_history", "users", name: "fk_sleep_ese_question_history_users"
  add_foreign_key "sleep_ese_questions", "masters"
  add_foreign_key "sleep_ese_questions", "users"
  add_foreign_key "sleep_incidental_finding_history", "masters", name: "fk_sleep_incidental_finding_history_masters"
  add_foreign_key "sleep_incidental_finding_history", "sleep_incidental_findings", name: "fk_sleep_incidental_finding_history_sleep_incidental_findings"
  add_foreign_key "sleep_incidental_finding_history", "users", name: "fk_sleep_incidental_finding_history_users"
  add_foreign_key "sleep_incidental_findings", "masters"
  add_foreign_key "sleep_incidental_findings", "users"
  add_foreign_key "sleep_inex_checklist_history", "masters", name: "fk_sleep_inex_checklist_history_masters"
  add_foreign_key "sleep_inex_checklist_history", "sleep_inex_checklists", name: "fk_sleep_inex_checklist_history_sleep_inex_checklists"
  add_foreign_key "sleep_inex_checklist_history", "users", name: "fk_sleep_inex_checklist_history_users"
  add_foreign_key "sleep_inex_checklists", "masters"
  add_foreign_key "sleep_inex_checklists", "users"
  add_foreign_key "sleep_isi_question_history", "masters", name: "fk_sleep_isi_question_history_masters"
  add_foreign_key "sleep_isi_question_history", "sleep_isi_questions", name: "fk_sleep_isi_question_history_sleep_isi_questions"
  add_foreign_key "sleep_isi_question_history", "users", name: "fk_sleep_isi_question_history_users"
  add_foreign_key "sleep_isi_questions", "masters"
  add_foreign_key "sleep_isi_questions", "users"
  add_foreign_key "sleep_mednav_provider_comm_history", "masters", name: "fk_sleep_mednav_provider_comm_history_masters"
  add_foreign_key "sleep_mednav_provider_comm_history", "sleep_mednav_provider_comms", name: "fk_sleep_mednav_provider_comm_history_sleep_mednav_provider_com"
  add_foreign_key "sleep_mednav_provider_comm_history", "users", name: "fk_sleep_mednav_provider_comm_history_users"
  add_foreign_key "sleep_mednav_provider_comms", "masters"
  add_foreign_key "sleep_mednav_provider_comms", "users"
  add_foreign_key "sleep_mednav_provider_report_history", "masters", name: "fk_sleep_mednav_provider_report_history_masters"
  add_foreign_key "sleep_mednav_provider_report_history", "sleep_mednav_provider_reports", name: "fk_sleep_mednav_provider_report_history_sleep_mednav_provider_r"
  add_foreign_key "sleep_mednav_provider_report_history", "users", name: "fk_sleep_mednav_provider_report_history_users"
  add_foreign_key "sleep_mednav_provider_reports", "masters"
  add_foreign_key "sleep_mednav_provider_reports", "users"
  add_foreign_key "sleep_payment_history", "masters", name: "fk_sleep_payment_history_masters"
  add_foreign_key "sleep_payment_history", "sleep_payments", name: "fk_sleep_payment_history_sleep_payments"
  add_foreign_key "sleep_payment_history", "users", name: "fk_sleep_payment_history_users"
  add_foreign_key "sleep_payments", "masters"
  add_foreign_key "sleep_payments", "users"
  add_foreign_key "sleep_pi_follow_up_history", "masters", name: "fk_sleep_pi_follow_up_history_masters"
  add_foreign_key "sleep_pi_follow_up_history", "sleep_pi_follow_ups", name: "fk_sleep_pi_follow_up_history_sleep_pi_follow_ups"
  add_foreign_key "sleep_pi_follow_up_history", "users", name: "fk_sleep_pi_follow_up_history_users"
  add_foreign_key "sleep_pi_follow_ups", "masters"
  add_foreign_key "sleep_pi_follow_ups", "users"
  add_foreign_key "sleep_protocol_deviation_history", "masters", name: "fk_sleep_protocol_deviation_history_masters"
  add_foreign_key "sleep_protocol_deviation_history", "sleep_protocol_deviations", name: "fk_sleep_protocol_deviation_history_sleep_protocol_deviations"
  add_foreign_key "sleep_protocol_deviation_history", "users", name: "fk_sleep_protocol_deviation_history_users"
  add_foreign_key "sleep_protocol_deviations", "masters"
  add_foreign_key "sleep_protocol_deviations", "users"
  add_foreign_key "sleep_protocol_exception_history", "masters", name: "fk_sleep_protocol_exception_history_masters"
  add_foreign_key "sleep_protocol_exception_history", "sleep_protocol_exceptions", name: "fk_sleep_protocol_exception_history_sleep_protocol_exceptions"
  add_foreign_key "sleep_protocol_exception_history", "users", name: "fk_sleep_protocol_exception_history_users"
  add_foreign_key "sleep_protocol_exceptions", "masters"
  add_foreign_key "sleep_protocol_exceptions", "users"
  add_foreign_key "sleep_ps2_eligible_history", "masters", name: "fk_sleep_ps2_eligible_history_masters"
  add_foreign_key "sleep_ps2_eligible_history", "sleep_ps2_eligibles", name: "fk_sleep_ps2_eligible_history_sleep_ps2_eligibles"
  add_foreign_key "sleep_ps2_eligible_history", "users", name: "fk_sleep_ps2_eligible_history_users"
  add_foreign_key "sleep_ps2_eligibles", "masters"
  add_foreign_key "sleep_ps2_eligibles", "users"
  add_foreign_key "sleep_ps2_initial_screening_history", "masters", name: "fk_sleep_ps2_initial_screening_history_masters"
  add_foreign_key "sleep_ps2_initial_screening_history", "sleep_ps2_initial_screenings", name: "fk_sleep_ps2_initial_screening_history_sleep_ps2_initial_screen"
  add_foreign_key "sleep_ps2_initial_screening_history", "users", name: "fk_sleep_ps2_initial_screening_history_users"
  add_foreign_key "sleep_ps2_initial_screenings", "masters"
  add_foreign_key "sleep_ps2_initial_screenings", "users"
  add_foreign_key "sleep_ps2_non_eligible_history", "masters", name: "fk_sleep_ps2_non_eligible_history_masters"
  add_foreign_key "sleep_ps2_non_eligible_history", "sleep_ps2_non_eligibles", name: "fk_sleep_ps2_non_eligible_history_sleep_ps2_non_eligibles"
  add_foreign_key "sleep_ps2_non_eligible_history", "users", name: "fk_sleep_ps2_non_eligible_history_users"
  add_foreign_key "sleep_ps2_non_eligibles", "masters"
  add_foreign_key "sleep_ps2_non_eligibles", "users"
  add_foreign_key "sleep_ps2_phq8_question_history", "masters", name: "fk_sleep_ps2_phq8_question_history_masters"
  add_foreign_key "sleep_ps2_phq8_question_history", "sleep_ps2_phq8_questions", name: "fk_sleep_ps2_phq8_question_history_sleep_ps2_phq8_questions"
  add_foreign_key "sleep_ps2_phq8_question_history", "users", name: "fk_sleep_ps2_phq8_question_history_users"
  add_foreign_key "sleep_ps2_phq8_questions", "masters"
  add_foreign_key "sleep_ps2_phq8_questions", "users"
  add_foreign_key "sleep_ps_audit_c_question_history", "masters", name: "fk_sleep_ps_audit_c_question_history_masters"
  add_foreign_key "sleep_ps_audit_c_question_history", "sleep_ps_audit_c_questions", name: "fk_sleep_ps_audit_c_question_history_sleep_ps_audit_c_questions"
  add_foreign_key "sleep_ps_audit_c_question_history", "users", name: "fk_sleep_ps_audit_c_question_history_users"
  add_foreign_key "sleep_ps_audit_c_questions", "masters"
  add_foreign_key "sleep_ps_audit_c_questions", "users"
  add_foreign_key "sleep_ps_basic_response_history", "masters", name: "fk_sleep_ps_basic_response_history_masters"
  add_foreign_key "sleep_ps_basic_response_history", "sleep_ps_basic_responses", name: "fk_sleep_ps_basic_response_history_sleep_ps_basic_responses"
  add_foreign_key "sleep_ps_basic_response_history", "users", name: "fk_sleep_ps_basic_response_history_users"
  add_foreign_key "sleep_ps_basic_responses", "masters"
  add_foreign_key "sleep_ps_basic_responses", "users"
  add_foreign_key "sleep_ps_dast2_mod_question_history", "masters", name: "fk_sleep_ps_dast2_mod_question_history_masters"
  add_foreign_key "sleep_ps_dast2_mod_question_history", "sleep_ps_dast2_mod_questions", name: "fk_sleep_ps_dast2_mod_question_history_sleep_ps_dast2_mod_quest"
  add_foreign_key "sleep_ps_dast2_mod_question_history", "users", name: "fk_sleep_ps_dast2_mod_question_history_users"
  add_foreign_key "sleep_ps_dast2_mod_questions", "masters"
  add_foreign_key "sleep_ps_dast2_mod_questions", "users"
  add_foreign_key "sleep_ps_eligibility_followup_history", "masters", name: "fk_sleep_ps_eligibility_followup_history_masters"
  add_foreign_key "sleep_ps_eligibility_followup_history", "sleep_ps_eligibility_followups", name: "fk_sleep_ps_eligibility_followup_history_sleep_ps_eligibility_f"
  add_foreign_key "sleep_ps_eligibility_followup_history", "users", name: "fk_sleep_ps_eligibility_followup_history_users"
  add_foreign_key "sleep_ps_eligibility_followups", "masters"
  add_foreign_key "sleep_ps_eligibility_followups", "users"
  add_foreign_key "sleep_ps_eligible_history", "masters", name: "fk_sleep_ps_eligible_history_masters"
  add_foreign_key "sleep_ps_eligible_history", "sleep_ps_eligibles", name: "fk_sleep_ps_eligible_history_sleep_ps_eligibles"
  add_foreign_key "sleep_ps_eligible_history", "users", name: "fk_sleep_ps_eligible_history_users"
  add_foreign_key "sleep_ps_eligibles", "masters"
  add_foreign_key "sleep_ps_eligibles", "users"
  add_foreign_key "sleep_ps_initial_screening_history", "masters", name: "fk_sleep_ps_initial_screening_history_masters"
  add_foreign_key "sleep_ps_initial_screening_history", "sleep_ps_initial_screenings", name: "fk_sleep_ps_initial_screening_history_sleep_ps_initial_screenin"
  add_foreign_key "sleep_ps_initial_screening_history", "users", name: "fk_sleep_ps_initial_screening_history_users"
  add_foreign_key "sleep_ps_initial_screenings", "masters"
  add_foreign_key "sleep_ps_initial_screenings", "users"
  add_foreign_key "sleep_ps_non_eligible_history", "masters", name: "fk_sleep_ps_non_eligible_history_masters"
  add_foreign_key "sleep_ps_non_eligible_history", "sleep_ps_non_eligibles", name: "fk_sleep_ps_non_eligible_history_sleep_ps_non_eligibles"
  add_foreign_key "sleep_ps_non_eligible_history", "users", name: "fk_sleep_ps_non_eligible_history_users"
  add_foreign_key "sleep_ps_non_eligibles", "masters"
  add_foreign_key "sleep_ps_non_eligibles", "users"
  add_foreign_key "sleep_ps_possibly_eligible_history", "masters", name: "fk_sleep_ps_possibly_eligible_history_masters"
  add_foreign_key "sleep_ps_possibly_eligible_history", "sleep_ps_possibly_eligibles", name: "fk_sleep_ps_possibly_eligible_history_sleep_ps_possibly_eligibl"
  add_foreign_key "sleep_ps_possibly_eligible_history", "users", name: "fk_sleep_ps_possibly_eligible_history_users"
  add_foreign_key "sleep_ps_possibly_eligibles", "masters"
  add_foreign_key "sleep_ps_possibly_eligibles", "users"
  add_foreign_key "sleep_ps_screener_response_history", "masters", name: "fk_sleep_ps_screener_response_history_masters"
  add_foreign_key "sleep_ps_screener_response_history", "sleep_ps_screener_responses", name: "fk_sleep_ps_screener_response_history_sleep_ps_screener_respons"
  add_foreign_key "sleep_ps_screener_response_history", "users", name: "fk_sleep_ps_screener_response_history_users"
  add_foreign_key "sleep_ps_screener_responses", "masters"
  add_foreign_key "sleep_ps_screener_responses", "users"
  add_foreign_key "sleep_ps_sleep_apnea_response_history", "masters", name: "fk_sleep_ps_sleep_apnea_response_history_masters"
  add_foreign_key "sleep_ps_sleep_apnea_response_history", "sleep_ps_sleep_apnea_responses", name: "fk_sleep_ps_sleep_apnea_response_history_sleep_ps_sleep_apnea_r"
  add_foreign_key "sleep_ps_sleep_apnea_response_history", "users", name: "fk_sleep_ps_sleep_apnea_response_history_users"
  add_foreign_key "sleep_ps_sleep_apnea_responses", "masters"
  add_foreign_key "sleep_ps_sleep_apnea_responses", "users"
  add_foreign_key "sleep_ps_subject_contact_history", "masters", name: "fk_sleep_ps_subject_contact_history_masters"
  add_foreign_key "sleep_ps_subject_contact_history", "sleep_ps_subject_contacts", name: "fk_sleep_ps_subject_contact_history_sleep_ps_subject_contacts"
  add_foreign_key "sleep_ps_subject_contact_history", "users", name: "fk_sleep_ps_subject_contact_history_users"
  add_foreign_key "sleep_ps_subject_contacts", "masters"
  add_foreign_key "sleep_ps_subject_contacts", "users"
  add_foreign_key "sleep_screening_history", "masters", name: "fk_sleep_screening_history_masters"
  add_foreign_key "sleep_screening_history", "sleep_screenings", name: "fk_sleep_screening_history_sleep_screenings"
  add_foreign_key "sleep_screening_history", "users", name: "fk_sleep_screening_history_users"
  add_foreign_key "sleep_screenings", "masters"
  add_foreign_key "sleep_screenings", "users"
  add_foreign_key "sleep_withdrawal_history", "masters", name: "fk_sleep_withdrawal_history_masters"
  add_foreign_key "sleep_withdrawal_history", "sleep_withdrawals", name: "fk_sleep_withdrawal_history_sleep_withdrawals"
  add_foreign_key "sleep_withdrawal_history", "users", name: "fk_sleep_withdrawal_history_users"
  add_foreign_key "sleep_withdrawals", "masters"
  add_foreign_key "sleep_withdrawals", "users"
  add_foreign_key "sub_process_history", "sub_processes", name: "fk_sub_process_history_sub_processes"
  add_foreign_key "sub_processes", "admins"
  add_foreign_key "sub_processes", "protocols"
  add_foreign_key "tbs_adl_informant_screener_history", "masters", name: "fk_tbs_adl_informant_screener_history_masters"
  add_foreign_key "tbs_adl_informant_screener_history", "tbs_adl_informant_screeners", name: "fk_tbs_adl_informant_screener_history_tbs_adl_informant_screene"
  add_foreign_key "tbs_adl_informant_screener_history", "users", name: "fk_tbs_adl_informant_screener_history_users"
  add_foreign_key "tbs_adl_informant_screeners", "masters"
  add_foreign_key "tbs_adl_informant_screeners", "users"
  add_foreign_key "tbs_adverse_event_history", "masters", name: "fk_tbs_adverse_event_history_masters"
  add_foreign_key "tbs_adverse_event_history", "tbs_adverse_events", name: "fk_tbs_adverse_event_history_tbs_adverse_events"
  add_foreign_key "tbs_adverse_event_history", "users", name: "fk_tbs_adverse_event_history_users"
  add_foreign_key "tbs_adverse_events", "masters"
  add_foreign_key "tbs_adverse_events", "users"
  add_foreign_key "tbs_appointment_history", "masters", name: "fk_tbs_appointment_history_masters"
  add_foreign_key "tbs_appointment_history", "tbs_appointments", name: "fk_tbs_appointment_history_tbs_appointments"
  add_foreign_key "tbs_appointment_history", "users", name: "fk_tbs_appointment_history_users"
  add_foreign_key "tbs_appointments", "masters"
  add_foreign_key "tbs_appointments", "users"
  add_foreign_key "tbs_assignment_history", "admins", name: "fk_tbs_assignment_history_admins"
  add_foreign_key "tbs_assignment_history", "masters", name: "fk_tbs_assignment_history_masters"
  add_foreign_key "tbs_assignment_history", "tbs_assignments", column: "tbs_assignment_table_id", name: "fk_tbs_assignment_history_tbs_assignments"
  add_foreign_key "tbs_assignment_history", "users", name: "fk_tbs_assignment_history_users"
  add_foreign_key "tbs_assignments", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "tbs_assignments", "masters"
  add_foreign_key "tbs_assignments", "users"
  add_foreign_key "tbs_consent_mailing_history", "masters", name: "fk_tbs_consent_mailing_history_masters"
  add_foreign_key "tbs_consent_mailing_history", "tbs_consent_mailings", name: "fk_tbs_consent_mailing_history_tbs_consent_mailings"
  add_foreign_key "tbs_consent_mailing_history", "users", name: "fk_tbs_consent_mailing_history_users"
  add_foreign_key "tbs_consent_mailings", "masters"
  add_foreign_key "tbs_consent_mailings", "users"
  add_foreign_key "tbs_exit_interview_history", "masters", name: "fk_tbs_exit_interview_history_masters"
  add_foreign_key "tbs_exit_interview_history", "tbs_exit_interviews", name: "fk_tbs_exit_interview_history_tbs_exit_interviews"
  add_foreign_key "tbs_exit_interview_history", "users", name: "fk_tbs_exit_interview_history_users"
  add_foreign_key "tbs_exit_interviews", "masters"
  add_foreign_key "tbs_exit_interviews", "users"
  add_foreign_key "tbs_four_wk_followup_history", "masters", name: "fk_tbs_four_wk_followup_history_masters"
  add_foreign_key "tbs_four_wk_followup_history", "tbs_four_wk_followups", name: "fk_tbs_four_wk_followup_history_tbs_four_wk_followups"
  add_foreign_key "tbs_four_wk_followup_history", "users", name: "fk_tbs_four_wk_followup_history_users"
  add_foreign_key "tbs_four_wk_followups", "masters"
  add_foreign_key "tbs_four_wk_followups", "users"
  add_foreign_key "tbs_hotel_history", "masters", name: "fk_tbs_hotel_history_masters"
  add_foreign_key "tbs_hotel_history", "tbs_hotels", name: "fk_tbs_hotel_history_tbs_hotels"
  add_foreign_key "tbs_hotel_history", "users", name: "fk_tbs_hotel_history_users"
  add_foreign_key "tbs_hotels", "masters"
  add_foreign_key "tbs_hotels", "users"
  add_foreign_key "tbs_incidental_finding_history", "masters", name: "fk_tbs_incidental_finding_history_masters"
  add_foreign_key "tbs_incidental_finding_history", "tbs_incidental_findings", name: "fk_tbs_incidental_finding_history_tbs_incidental_findings"
  add_foreign_key "tbs_incidental_finding_history", "users", name: "fk_tbs_incidental_finding_history_users"
  add_foreign_key "tbs_incidental_findings", "masters"
  add_foreign_key "tbs_incidental_findings", "users"
  add_foreign_key "tbs_inex_checklist_history", "masters", name: "fk_tbs_inex_checklist_history_masters"
  add_foreign_key "tbs_inex_checklist_history", "tbs_inex_checklists", name: "fk_tbs_inex_checklist_history_tbs_inex_checklists"
  add_foreign_key "tbs_inex_checklist_history", "users", name: "fk_tbs_inex_checklist_history_users"
  add_foreign_key "tbs_inex_checklists", "masters"
  add_foreign_key "tbs_inex_checklists", "users"
  add_foreign_key "tbs_mednav_followup_history", "masters", name: "fk_tbs_mednav_followup_history_masters"
  add_foreign_key "tbs_mednav_followup_history", "tbs_mednav_followups", name: "fk_tbs_mednav_followup_history_tbs_mednav_followups"
  add_foreign_key "tbs_mednav_followup_history", "users", name: "fk_tbs_mednav_followup_history_users"
  add_foreign_key "tbs_mednav_followups", "masters"
  add_foreign_key "tbs_mednav_followups", "users"
  add_foreign_key "tbs_mednav_provider_comm_history", "masters", name: "fk_tbs_mednav_provider_comm_history_masters"
  add_foreign_key "tbs_mednav_provider_comm_history", "tbs_mednav_provider_comms", name: "fk_tbs_mednav_provider_comm_history_tbs_mednav_provider_comms"
  add_foreign_key "tbs_mednav_provider_comm_history", "users", name: "fk_tbs_mednav_provider_comm_history_users"
  add_foreign_key "tbs_mednav_provider_comms", "masters"
  add_foreign_key "tbs_mednav_provider_comms", "users"
  add_foreign_key "tbs_mednav_provider_report_history", "masters", name: "fk_tbs_mednav_provider_report_history_masters"
  add_foreign_key "tbs_mednav_provider_report_history", "tbs_mednav_provider_reports", name: "fk_tbs_mednav_provider_report_history_tbs_mednav_provider_repor"
  add_foreign_key "tbs_mednav_provider_report_history", "users", name: "fk_tbs_mednav_provider_report_history_users"
  add_foreign_key "tbs_mednav_provider_reports", "masters"
  add_foreign_key "tbs_mednav_provider_reports", "users"
  add_foreign_key "tbs_payment_history", "masters", name: "fk_tbs_payment_history_masters"
  add_foreign_key "tbs_payment_history", "tbs_payments", name: "fk_tbs_payment_history_tbs_payments"
  add_foreign_key "tbs_payment_history", "users", name: "fk_tbs_payment_history_users"
  add_foreign_key "tbs_payments", "masters"
  add_foreign_key "tbs_payments", "users"
  add_foreign_key "tbs_protocol_deviation_history", "masters", name: "fk_tbs_protocol_deviation_history_masters"
  add_foreign_key "tbs_protocol_deviation_history", "tbs_protocol_deviations", name: "fk_tbs_protocol_deviation_history_tbs_protocol_deviations"
  add_foreign_key "tbs_protocol_deviation_history", "users", name: "fk_tbs_protocol_deviation_history_users"
  add_foreign_key "tbs_protocol_deviations", "masters"
  add_foreign_key "tbs_protocol_deviations", "users"
  add_foreign_key "tbs_protocol_exception_history", "masters", name: "fk_tbs_protocol_exception_history_masters"
  add_foreign_key "tbs_protocol_exception_history", "tbs_protocol_exceptions", name: "fk_tbs_protocol_exception_history_tbs_protocol_exceptions"
  add_foreign_key "tbs_protocol_exception_history", "users", name: "fk_tbs_protocol_exception_history_users"
  add_foreign_key "tbs_protocol_exceptions", "masters"
  add_foreign_key "tbs_protocol_exceptions", "users"
  add_foreign_key "tbs_ps_informant_detail_history", "masters", name: "fk_tbs_ps_informant_detail_history_masters"
  add_foreign_key "tbs_ps_informant_detail_history", "tbs_ps_informant_details", name: "fk_tbs_ps_informant_detail_history_tbs_ps_informant_details"
  add_foreign_key "tbs_ps_informant_detail_history", "users", name: "fk_tbs_ps_informant_detail_history_users"
  add_foreign_key "tbs_ps_informant_details", "masters"
  add_foreign_key "tbs_ps_informant_details", "users"
  add_foreign_key "tbs_ps_initial_screening_history", "masters", name: "fk_tbs_ps_initial_screening_history_masters"
  add_foreign_key "tbs_ps_initial_screening_history", "tbs_ps_initial_screenings", name: "fk_tbs_ps_initial_screening_history_tbs_ps_initial_screenings"
  add_foreign_key "tbs_ps_initial_screening_history", "users", name: "fk_tbs_ps_initial_screening_history_users"
  add_foreign_key "tbs_ps_initial_screenings", "masters"
  add_foreign_key "tbs_ps_initial_screenings", "users"
  add_foreign_key "tbs_screening_history", "masters", name: "fk_tbs_screening_history_masters"
  add_foreign_key "tbs_screening_history", "tbs_screenings", name: "fk_tbs_screening_history_tbs_screenings"
  add_foreign_key "tbs_screening_history", "users", name: "fk_tbs_screening_history_users"
  add_foreign_key "tbs_screenings", "masters"
  add_foreign_key "tbs_screenings", "users"
  add_foreign_key "tbs_station_contact_history", "tbs_station_contacts", name: "fk_tbs_station_contact_history_tbs_station_contacts"
  add_foreign_key "tbs_station_contact_history", "users", name: "fk_tbs_station_contact_history_users"
  add_foreign_key "tbs_station_contacts", "users"
  add_foreign_key "tbs_survey_history", "masters", name: "fk_tbs_survey_history_masters"
  add_foreign_key "tbs_survey_history", "tbs_surveys", name: "fk_tbs_survey_history_tbs_surveys"
  add_foreign_key "tbs_survey_history", "users", name: "fk_tbs_survey_history_users"
  add_foreign_key "tbs_surveys", "masters"
  add_foreign_key "tbs_surveys", "users"
  add_foreign_key "tbs_transportation_history", "masters", name: "fk_tbs_transportation_history_masters"
  add_foreign_key "tbs_transportation_history", "tbs_transportations", name: "fk_tbs_transportation_history_tbs_transportations"
  add_foreign_key "tbs_transportation_history", "users", name: "fk_tbs_transportation_history_users"
  add_foreign_key "tbs_transportations", "masters"
  add_foreign_key "tbs_transportations", "users"
  add_foreign_key "tbs_two_wk_followup_history", "masters", name: "fk_tbs_two_wk_followup_history_masters"
  add_foreign_key "tbs_two_wk_followup_history", "tbs_two_wk_followups", name: "fk_tbs_two_wk_followup_history_tbs_two_wk_followups"
  add_foreign_key "tbs_two_wk_followup_history", "users", name: "fk_tbs_two_wk_followup_history_users"
  add_foreign_key "tbs_two_wk_followups", "masters"
  add_foreign_key "tbs_two_wk_followups", "users"
  add_foreign_key "tbs_withdrawal_history", "masters", name: "fk_tbs_withdrawal_history_masters"
  add_foreign_key "tbs_withdrawal_history", "tbs_withdrawals", name: "fk_tbs_withdrawal_history_tbs_withdrawals"
  add_foreign_key "tbs_withdrawal_history", "users", name: "fk_tbs_withdrawal_history_users"
  add_foreign_key "tbs_withdrawals", "masters"
  add_foreign_key "tbs_withdrawals", "users"
  add_foreign_key "test1_history", "admins", name: "fk_test1_history_admins"
  add_foreign_key "test1_history", "masters", name: "fk_test1_history_masters"
  add_foreign_key "test1_history", "test1s", column: "test1_table_id", name: "fk_test1_history_test1s"
  add_foreign_key "test1_history", "users", name: "fk_test1_history_users"
  add_foreign_key "test1s", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "test1s", "masters"
  add_foreign_key "test1s", "users"
  add_foreign_key "test2_history", "admins", name: "fk_test2_history_admins"
  add_foreign_key "test2_history", "masters", name: "fk_test2_history_masters"
  add_foreign_key "test2_history", "test2s", column: "test2_table_id", name: "fk_test2_history_test2s"
  add_foreign_key "test2_history", "users", name: "fk_test2_history_users"
  add_foreign_key "test2s", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "test2s", "masters"
  add_foreign_key "test2s", "users"
  add_foreign_key "test9_number_history", "admins"
  add_foreign_key "test9_number_history", "masters"
  add_foreign_key "test9_number_history", "test9_numbers", column: "test9_number_table_id_id"
  add_foreign_key "test9_number_history", "users"
  add_foreign_key "test9_numbers", "admins"
  add_foreign_key "test9_numbers", "masters"
  add_foreign_key "test9_numbers", "users"
  add_foreign_key "test_2_history", "admins", name: "fk_test_2_history_admins"
  add_foreign_key "test_2_history", "masters", name: "fk_test_2_history_masters"
  add_foreign_key "test_2_history", "test_2s", column: "test_2_table_id", name: "fk_test_2_history_test_2s"
  add_foreign_key "test_2_history", "users", name: "fk_test_2_history_users"
  add_foreign_key "test_2s", "admins", name: "fk_rails_1a7e2b01e0admin"
  add_foreign_key "test_2s", "masters"
  add_foreign_key "test_2s", "users"
  add_foreign_key "test_ext2_history", "masters", name: "fk_test_ext2_history_masters"
  add_foreign_key "test_ext2_history", "test_ext2s", column: "test_ext2_table_id", name: "fk_test_ext2_history_test_ext2s"
  add_foreign_key "test_ext2_history", "users", name: "fk_test_ext2_history_users"
  add_foreign_key "test_ext2s", "masters"
  add_foreign_key "test_ext2s", "users"
  add_foreign_key "test_ext_history", "masters", name: "fk_test_ext_history_masters"
  add_foreign_key "test_ext_history", "test_exts", column: "test_ext_table_id", name: "fk_test_ext_history_test_exts"
  add_foreign_key "test_ext_history", "users", name: "fk_test_ext_history_users"
  add_foreign_key "test_exts", "masters"
  add_foreign_key "test_exts", "users"
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
  add_foreign_key "user_history", "app_types"
  add_foreign_key "user_history", "users", name: "fk_user_history_users"
  add_foreign_key "user_role_history", "admins", name: "fk_user_role_history_admins"
  add_foreign_key "user_role_history", "admins", name: "fk_user_role_history_admins"
  add_foreign_key "user_role_history", "user_roles", name: "fk_user_role_history_user_roles"
  add_foreign_key "user_role_history", "user_roles", name: "fk_user_role_history_user_roles"
  add_foreign_key "user_role_history", "admins", name: "fk_user_role_history_admins"
  add_foreign_key "user_role_history", "admins", name: "fk_user_role_history_admins"
  add_foreign_key "user_role_history", "user_roles", name: "fk_user_role_history_user_roles"
  add_foreign_key "user_role_history", "user_roles", name: "fk_user_role_history_user_roles"
  add_foreign_key "user_roles", "admins"
  add_foreign_key "user_roles", "app_types"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "admins"
  add_foreign_key "users", "app_types"
  add_foreign_key "users_contact_infos", "admins"
  add_foreign_key "users_contact_infos", "admins"
  add_foreign_key "users_contact_infos", "users"
  add_foreign_key "users_contact_infos", "users"
  add_foreign_key "users_contact_infos", "admins"
  add_foreign_key "users_contact_infos", "admins"
  add_foreign_key "users_contact_infos", "users"
  add_foreign_key "users_contact_infos", "users"
  add_foreign_key "zeus_bulk_message_history", "masters", name: "fk_zeus_bulk_message_history_masters"
  add_foreign_key "zeus_bulk_message_history", "users", name: "fk_zeus_bulk_message_history_users"
  add_foreign_key "zeus_bulk_message_history", "zeus_bulk_messages", name: "fk_zeus_bulk_message_history_zeus_bulk_messages"
  add_foreign_key "zeus_bulk_message_recipient_history", "masters", name: "fk_zeus_bulk_message_recipient_history_masters"
  add_foreign_key "zeus_bulk_message_recipient_history", "users", name: "fk_zeus_bulk_message_recipient_history_users"
  add_foreign_key "zeus_bulk_message_recipient_history", "zeus_bulk_message_recipients", name: "fk_zeus_bulk_message_recipient_history_zeus_bulk_message_recipi"
  add_foreign_key "zeus_bulk_message_recipients", "masters"
  add_foreign_key "zeus_bulk_message_recipients", "users"
  add_foreign_key "zeus_bulk_message_status_history", "masters", name: "fk_zeus_bulk_message_status_history_masters"
  add_foreign_key "zeus_bulk_message_status_history", "users", name: "fk_zeus_bulk_message_status_history_users"
  add_foreign_key "zeus_bulk_message_status_history", "zeus_bulk_message_statuses", name: "fk_zeus_bulk_message_status_history_zeus_bulk_message_statuses"
  add_foreign_key "zeus_bulk_message_statuses", "masters"
  add_foreign_key "zeus_bulk_message_statuses", "users"
  add_foreign_key "zeus_bulk_message_statuses", "zeus_bulk_message_recipients"
  add_foreign_key "zeus_bulk_messages", "masters"
  add_foreign_key "zeus_bulk_messages", "users"
  add_foreign_key "zeus_short_link_clicks", "masters"
  add_foreign_key "zeus_short_link_clicks", "users"
  add_foreign_key "zeus_short_link_history", "masters", name: "fk_zeus_short_link_history_masters"
  add_foreign_key "zeus_short_link_history", "users", name: "fk_zeus_short_link_history_users"
  add_foreign_key "zeus_short_link_history", "zeus_short_links", name: "fk_zeus_short_link_history_zeus_short_links"
  add_foreign_key "zeus_short_links", "masters"
  add_foreign_key "zeus_short_links", "users"
end
