require 'active_record/migration/app_generator'
class CreateTestAllFieldsT0z959 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_all_v2_fields'
    self.class_name = 'DynamicModel::TestAllField'
    self.fields = %i[a_string a_int a_float a_date a_time a_mixed_string a_boolean a_unknown a_string2 state a_timestamp a_decimal json jsonb college protocol_id sub_process_id protocol_event_id source zip e_signed_document e_signed_how fixed_value multi_editable_choices_abc multi_editable_list_def multi_player_contact_ranks select_user_with_role_admin select_value tag_select_users_with_role_admin tag_select_some_values done_yes_no done_blank_yes_no done_no_yes done_blank_yes_no_dont_know done_yes_no_dont_know some_description some_details a_link some_notes player_contact_rank done_true_false a_url done_when some_year country description email message notes phone rank rec_type select_record_from_table_test_with_id_recs select_record_from_test_with_id_recs select_record_id_from_test_with_id_recs tag_select_record_from_table_test_with_id_recs tag_select_record_from_test_with_id_recs pick_multiple_records_from_table_test_with_id_recs tag_select_record_id_from_test_with_id_recs]
    self.table_comment = 'Test from Specs'
    self.fields_comments = { a_string: nil, a_int: nil, a_float: nil, a_date: nil, a_time: nil, a_mixed_string: nil, a_boolean: nil, a_unknown: nil, a_string2: nil, state: nil }
    self.db_configs =
      {
        'a_string' => { 'type' => 'string' },
        'a_int' => { 'type' => 'integer' },
        'a_float' => { 'type' => 'float' },
        'a_date' => { 'type' => 'date' },
        'a_time' => { 'type' => 'datetime' },
        'a_mixed_string' => { 'type' => 'string' },
        'a_boolean' => { 'type' => 'boolean' },
        'a_unknown' => { 'type' => 'string' },
        'a_string2' => { 'type' => 'string' },
        'state' => { 'type' => 'string' },
        'user_id' => { 'type' => 'integer' },
        'created_at' => { 'type' => 'datetime' },
        'updated_at' => { 'type' => 'datetime' },
        'a_timestamp' => { 'type' => 'integer' },
        'a_decimal' => { 'type' => 'string' },
        'json' => { 'type' => 'json' },
        'jsonb' => { 'type' => 'jsonb' },
        'college' => { 'type' => 'string' },
        'protocol_id' => { 'type' => 'integer' },
        'sub_process_id' => { 'type' => 'integer' },
        'protocol_event_id' => { 'type' => 'integer' },
        'source' => { 'type' => 'string' },
        'zip' => { 'type' => 'string' },
        'e_signed_document' => { 'type' => 'string' },
        'e_signed_how' => { 'type' => 'string' },
        'fixed_value' => { 'type' => 'string' },
        'multi_editable_choices_abc' => { 'type' => 'string', 'array' => true },
        'multi_editable_list_def' => { 'type' => 'string', 'array' => true },
        'multi_player_contact_ranks' => { 'type' => 'string', 'array' => true },
        'select_user_with_role_admin' => { 'type' => 'string' },
        'select_value' => { 'type' => 'string' },
        'tag_select_users_with_role_admin' => { 'type' => 'string', 'array' => true },
        'tag_select_some_values' => { 'type' => 'string', 'array' => true },
        'done_yes_no' => { 'type' => 'string' },
        'done_blank_yes_no' => { 'type' => 'string' },
        'done_no_yes' => { 'type' => 'string' },
        'done_blank_yes_no_dont_know' => { 'type' => 'string' },
        'done_yes_no_dont_know' => { 'type' => 'string' },
        'some_description' => { 'type' => 'string' },
        'some_details' => { 'type' => 'string' },
        'a_link' => { 'type' => 'string' },
        'some_notes' => { 'type' => 'string' },
        'player_contact_rank' => { 'type' => 'string' },
        'done_true_false' => { 'type' => 'string' },
        'a_url' => { 'type' => 'string' },
        'done_when' => { 'type' => 'date' },
        'some_year' => { 'type' => 'string' },
        'country' => { 'type' => 'string' },
        'description' => { 'type' => 'string' },
        'email' => { 'type' => 'string' },
        'message' => { 'type' => 'string' },
        'notes' => { 'type' => 'string' },
        'phone' => { 'type' => 'string' },
        'rank' => { 'type' => 'integer' },
        'rec_type' => { 'type' => 'string' },
        'select_record_from_table_test_with_id_recs' => { 'type' => 'string' },
        'select_record_from_test_with_id_recs' => { 'type' => 'string' },
        'select_record_id_from_test_with_id_recs' => { 'type' => 'string' },
        'tag_select_record_from_table_test_with_id_recs' => { 'type' => 'string', 'array' => true },
        'tag_select_record_from_test_with_id_recs' => { 'type' => 'string', 'array' => true },
        'pick_multiple_records_from_table_test_with_id_recs' => { 'type' => 'string' },
        'tag_select_record_id_from_test_with_id_recs' => { 'type' => 'string', 'array' => true }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
