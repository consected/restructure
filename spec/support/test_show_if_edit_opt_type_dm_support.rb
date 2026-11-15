# frozen_string_literal: true

require "#{Rails.root}/db/table_generators/dynamic_models_table.rb"

# Support for system specs testing show_if visibility in edit mode for dynamic models
# that use a custom option_type_attr_name (GitHub issue #1256).
#
# The dynamic model has two option types with DELIBERATELY DIFFERENT show_if rules:
#   type_a: cond_field is visible only when trigger_field == 'show_in_a'
#   type_b: cond_field is visible only when trigger_field == 'show_in_b'
#
# This means a test using a type_b record can assert that setting trigger_field to
# 'show_in_a' keeps cond_field hidden, which would fail if the JS accidentally applied
# type_a rules (the classic option-type cross-contamination described in #1256).
module TestShowIfEditOptTypeDmSupport
  def setup_show_if_edit_opt_type_dm
    dm_options = <<~END_YAML
      _configurations:
        use_current_version: true
        option_type_attr_name: instrument_type

      _db_columns:
        id:
          type: integer
        master_id:
          type: integer
        instrument_type:
          type: string
        trigger_field:
          type: string
        cond_field:
          type: string
        user_id:
          type: integer
        created_at:
          type: datetime
        updated_at:
          type: datetime

      type_a:
        fields:
          - trigger_field
          - cond_field

        labels:
          trigger_field: Trigger Field
          cond_field: Conditional Field

        show_if:
          cond_field:
            trigger_field: show_in_a

      type_b:
        fields:
          - trigger_field
          - cond_field

        labels:
          trigger_field: Trigger Field
          cond_field: Conditional Field

        show_if:
          cond_field:
            trigger_field: show_in_b

    END_YAML

    DynamicModel.active.where(table_name: 'test_show_if_edit_opt_types').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestShowIfEditOptType) if defined? DynamicModel::TestShowIfEditOptType

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test show if edit opt types',
                              schema_name: 'dynamic_test',
                              table_name: 'test_show_if_edit_opt_types',
                              category: :details,
                              options: dm_options,
                              field_list: 'instrument_type trigger_field cond_field',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 13

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel

    app = @user.app_type
    expect(app).to be_a Admin::AppType
    Admin::PageLayout.active.where(app_type_id: app.id).each do |p|
      p.disable! @admin
    end

    setup_access :dynamic_model__test_show_if_edit_opt_types, user: @user

    # Remove any records left over from previous runs
    dm.implementation_class.delete_all

    dm
  end

  # Create a record of the given option type (instrument_type).
  # trigger_field value controls whether the show_if condition is satisfied:
  #   type_a records: 'show_in_a' satisfies the condition
  #   type_b records: 'show_in_b' satisfies the condition
  def create_edit_opt_type_record(instrument_type:, trigger_field: nil, cond_field: 'some value')
    @master.current_user = @user
    @master.dynamic_model__test_show_if_edit_opt_types.create!(
      instrument_type:,
      trigger_field:,
      cond_field:
    )
  end

  # CSS selector for the show-mode block of a specific record
  def edit_opt_type_show_block(rec)
    find("#{show_form_css}[data-sub-id='#{rec.id}']")
  end
end
