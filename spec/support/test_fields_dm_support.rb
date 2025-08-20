# frozen_string_literal: true

module TestFieldsDmSupport
  def setup_fields_dm
    DynamicModel.active.where(table_name: 'test_with_id_recs').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestWithIdRec) if defined? DynamicModel::TestWithIdRec

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'Test Records With ID',
                              schema_name: 'dynamic_test',
                              table_name: 'test_with_id_recs',
                              category: :test,
                              field_list: 'value name',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id'
    dm.current_admin = @admin
    dm.update_tracker_events
    expect(dm).to be_a ::DynamicModel
    setup_access :dynamic_model__test_with_id_recs, user: @user

    expect(@user).not_to be_nil
    expect(@master).not_to be_nil
    @master.current_user = @user
    ic = dm.implementation_class
    ic.create!(current_user: @user, master: @master, value: 'test value 1', name: 'Test Name 1')
    ic.create!(current_user: @user, master: @master, value: 'test value 2', name: 'Test Name 2')
    ic.create!(current_user: @user, master: @master, value: 'test value 3', name: 'Test Name 3')

    dm_options = <<~END_YAML
      _configurations: {}

      _db_columns:
        id:
          type: integer
        a_string:
          type: string
        a_int:
          type: integer
        a_float:
          type: float
        a_date:
          type: date
        a_time:
          type: datetime
        a_mixed_string:
          type: string
        a_boolean:
          type: boolean
        a_unknown:
          type: string
        a_string2:
          type: string
        state:
          type: string
        user_id:
          type: integer
        created_at:
          type: datetime
        updated_at:
          type: datetime
        a_timestamp:
          type: integer
        a_decimal:
          type: string
        json:
          type: json
        jsonb:
          type: jsonb
        college:
          type: string
        protocol_id:
          type: integer
        sub_process_id:
          type: integer
        protocol_event_id:
          type: integer
        source:
          type: string
        zip:
          type: string
        e_signed_document:
          type: string
        e_signed_how:
          type: string
        fixed_value:
          type: string
        multi_editable_choices_abc:
          type: string
          array: true
        multi_editable_list_def:
          type: string
          array: true
        multi_player_contact_ranks:
          type: string
          array: true
        select_user_with_role_admin:
          type: string
        select_value:
          type: string
        tag_select_users_with_role_admin:
          type: string
          array: true
        tag_select_some_values:
          type: string
          array: true
        done_yes_no:
          type: string
        done_blank_yes_no:
          type: string
        done_no_yes:
          type: string
        done_blank_yes_no_dont_know:
          type: string
        done_yes_no_dont_know:
          type: string
        some_description:
          type: string
        some_details:
          type: string
        a_link:
          type: string
        some_notes:
          type: string
        player_contact_rank:
          type: string
        done_true_false:
          type: string
        a_url:
          type: string
        done_when:
          type: date
        some_year:
          type: string
        country:
          type: string
        description:
          type: string
        email:
          type: string
        message:
          type: string
        notes:
          type: string
        phone:
          type: string
        rank:
          type: integer
        rec_type:
          type: string
        select_record_from_table_test_with_id_recs:
          type: string
        select_record_from_test_with_id_recs:
          type: string
        select_record_id_from_test_with_id_recs:
          type: string
        tag_select_record_from_table_test_with_id_recs:
          type: string
          array: true
        tag_select_record_from_test_with_id_recs:
          type: string
          array: true
        pick_multiple_records_from_table_test_with_id_recs:
          type: string
        tag_select_record_id_from_test_with_id_recs:
          type: string
          array: true



      default:
        field_options:
          a_string:
            no_downcase: true
          select_value:
            edit_as:
              alt_options:
                'Choice 1': choice 1
                'Choice 2': choice 2
        view_options:
          data_attribute: a_string
      #{'  '}

    END_YAML

    DynamicModel.active.where(table_name: 'test_all_v2_fields').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestCreatedByRec) if defined? DynamicModel::TestCreatedByRec

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test all fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_all_v2_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'a_string a_int a_float a_date a_time a_mixed_string a_boolean a_unknown a_string2 state a_timestamp a_decimal json jsonb college protocol_id sub_process_id protocol_event_id source zip e_signed_document e_signed_how fixed_value multi_editable_choices_abc multi_editable_list_def multi_player_contact_ranks select_user_with_role_admin select_value tag_select_users_with_role_admin tag_select_some_values done_yes_no done_blank_yes_no done_no_yes done_blank_yes_no_dont_know done_yes_no_dont_know some_description some_details a_link some_notes player_contact_rank done_true_false a_url done_when some_year country description email message notes phone rank rec_type select_record_from_table_test_with_id_recs select_record_from_test_with_id_recs select_record_id_from_test_with_id_recs tag_select_record_from_table_test_with_id_recs tag_select_record_from_test_with_id_recs pick_multiple_records_from_table_test_with_id_recs tag_select_record_id_from_test_with_id_recs',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 10

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel

    app = @user.app_type
    expect(app).to be_a Admin::AppType
    Admin::PageLayout.active.where(app_type_id: app.id).each do |p|
      p.disable! @admin
    end

    setup_access :dynamic_model__test_all_v2_fields, user: @user

    item_type = 'dynamic_model__test_all_v2_fields_rank'

    values = [
      { name: 'primary', value: 10, create_with: true, edit_always: true },
      { name: 'secondary', value: 5, create_with: true, edit_always: true },
      { name: 'do not use', value: 0, create_with: true, edit_always: true },
      { name: 'bad contact', value: -1, create_with: true, edit_always: true }
    ]

    values.each do |v|
      v[:current_admin] = @admin
      Classification::GeneralSelection.create(v)
    end

    dm
  end
end
