# frozen_string_literal: true

module TestNoUserIdDmRecSupport
  def no_user_id_dm
    'no_user_id_table_recs'
  end

  def setup_test_no_user_id_field_on_table
    options = <<~END_TEXT
      _configurations:
        no_user_id: true
    END_TEXT

    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test User ID on table',
      table_name: no_user_id_dm,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: nil,
      category: :test,
      options:
    )

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel

    setup_access :dynamic_model__no_user_id_table_recs, user: @user
    setup_access :dynamic_model__no_user_id_table_recs, user: @user0
    dm
  end
end
