# frozen_string_literal: true

require "#{Rails.root}/db/table_generators/dynamic_models_table.rb"

# Support for system specs testing show_if visibility of read-only (show mode) field values
# in dynamic models that use option types selected by a custom option_type_attr_name
# (GitHub issue #1254).
module TestShowIfOptionTypeDmSupport
  def setup_show_if_option_type_dm
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
        event_type:
          type: string
        visit_name:
          type: string
        form_label:
          type: string
        flag_field:
          type: boolean
        user_id:
          type: integer
        created_at:
          type: datetime
        updated_at:
          type: datetime

      default:
        fields:
          - event_type
          - visit_name
          - form_label
          - flag_field

        labels:
          event_type: Event Type
          visit_name: Visit Name
          form_label: Form Label
          flag_field: SCR

        field_options:
          event_type:
            no_downcase: true
            edit_as:
              field_type: select_event_type
              alt_options:
                'Lifestage visit': '1'
                'Annual survey': '2'
                'Laboratory assay': '3'
          visit_name:
            no_downcase: true
            edit_as:
              field_type: select_visit_name
              alt_options:
                'Screening': '1'
                'Visit': '2'
          form_label:
            no_downcase: true
            edit_as:
              field_type: select_form_label
              alt_options:
                'SCR': '1'

        caption_before:
          form_label: 'Form Label '

        show_if:
          form_label:
            visit_name: '1'
          flag_field:
            visit_name: '1'

      visit_info:
        fields:
          - event_type
          - visit_name
          - form_label
          - flag_field

        labels:
          event_type: Event Type
          visit_name: Visit Name
          form_label: Form Label
          flag_field: SCR

        field_options:
          event_type:
            no_downcase: true
            edit_as:
              field_type: select_event_type
              alt_options:
                'Lifestage visit': '1'
                'Annual survey': '2'
                'Laboratory assay': '3'
          visit_name:
            no_downcase: true
            edit_as:
              field_type: select_visit_name
              alt_options:
                'Screening': '1'
                'Visit': '2'
          form_label:
            no_downcase: true
            edit_as:
              field_type: select_form_label
              alt_options:
                'SCR': '1'

        caption_before:
          form_label: 'Form Label '

        show_if:
          form_label:
            visit_name: '1'
          flag_field:
            visit_name: '1'

    END_YAML

    DynamicModel.active.where(table_name: 'test_show_if_option_types').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestShowIfOptionType) if defined? DynamicModel::TestShowIfOptionType

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test show if option types',
                              schema_name: 'dynamic_test',
                              table_name: 'test_show_if_option_types',
                              category: :details,
                              options: dm_options,
                              field_list: 'instrument_type event_type visit_name form_label flag_field',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 12

    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel

    app = @user.app_type
    expect(app).to be_a Admin::AppType
    Admin::PageLayout.active.where(app_type_id: app.id).each do |p|
      p.disable! @admin
    end

    setup_access :dynamic_model__test_show_if_option_types, user: @user

    # Remove any records left over from previous runs
    dm.implementation_class.delete_all

    dm
  end

  # Create a record using the visit_info option type.
  # visit_name: '1' satisfies the show_if conditions for form_label and flag_field,
  # any other value should hide those fields.
  def create_option_type_record(visit_name:, event_type: '2')
    @master.current_user = @user
    @master.dynamic_model__test_show_if_option_types.create! instrument_type: 'visit_info',
                                                             event_type:,
                                                             visit_name:,
                                                             form_label: '1',
                                                             flag_field: true
  end

  # The show-mode result block for a specific record
  def option_type_record_block(rec)
    find("#{show_form_css}[data-sub-id='#{rec.id}']")
  end
end
