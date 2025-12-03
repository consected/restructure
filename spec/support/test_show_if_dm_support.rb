# frozen_string_literal: true

require "#{Rails.root}/db/table_generators/dynamic_models_table.rb"

module TestShowIfDmSupport
  def setup_show_if_dm
    # First, create the embedded records model
    setup_show_if_embedded_model

    dm_options = <<~END_YAML
      _configurations:
        use_current_version: true

      _db_columns:
        id:
          type: integer
        master_id:
          type: integer
        main_field_1:
          type: string
        main_field_2:
          type: string
        main_field_3:
          type: string
        conditional_field_1:
          type: string
        conditional_field_2:
          type: string
        conditional_field_3:
          type: string
        user_id:
          type: integer
        created_at:
          type: datetime
        updated_at:
          type: datetime

      default:
        labels:
          main_field_1: Main Field 1
          main_field_2: Main Field 2
          main_field_3: Main Field 3
          conditional_field_1: Conditional Field 1
          conditional_field_2: Conditional Field 2
          conditional_field_3: Conditional Field 3

        embed:
          resource_name: dynamic_model__test_show_if_embedded_recs

        field_options:
          main_field_1:
            no_downcase: true
          main_field_2:
            edit_as:
              field_type: select_main_field_2
              alt_options:
                'Option A': option_a
                'Option B': option_b
                'Option C': option_c

        show_if:
          conditional_field_1:
            main_field_1: show_conditional_1
          conditional_field_2:
            any:
              main_field_2: option_b
              embedded_item:
                embedded_status: active
          conditional_field_3:
            all:
              main_field_1: show_conditional_3
              embedded_item:
                all:
                  embedded_status: active
                  embedded_score:
                    condition: '>='
                    value: 10

        field_configs:
          main_field_1:
            caption_before:
              keep_label: true
              caption: Enter a value to control conditional field 1 visibility
          main_field_2:
            caption_before:
              keep_label: true
              caption: Select an option to control conditional field 2 visibility
          conditional_field_1:
            caption_before:
              keep_label: true
              caption: This field shows when main_field_1 = 'show_conditional_1'
          conditional_field_2:
            caption_before:
              keep_label: true
              caption: This field shows when main_field_2 = 'option_b' OR embedded_item.embedded_status = 'active'
          conditional_field_3:
            caption_before:
              keep_label: true
              caption: This field shows when main_field_1 = 'show_conditional_3' AND embedded_item.embedded_status = 'active' AND embedded_item.embedded_score >= 10

    END_YAML

    DynamicModel.active.where(table_name: 'test_show_if_fields').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestShowIfField) if defined? DynamicModel::TestShowIfField

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test show if fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_show_if_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'main_field_1 main_field_2 main_field_3 conditional_field_1 conditional_field_2 conditional_field_3',
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

    setup_access :dynamic_model__test_show_if_fields, user: @user

    dm
  end

  def setup_show_if_embedded_model
    # Disable any existing models
    DynamicModel.active.where(table_name: 'test_show_if_embedded_recs').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestShowIfEmbeddedRec) if defined? DynamicModel::TestShowIfEmbeddedRec

    # Create the embedded model configuration
    embedded_options = <<~END_YAML
      default:
        labels:
          embedded_status: Status
          embedded_score: Score

        field_options:
          embedded_status:
            edit_as:
              field_type: select_embedded_status
              alt_options:
                'Active': active
                'Inactive': inactive
                'Pending': pending
          embedded_score:
            edit_as:
              field_type: number

    END_YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test show if embedded recs',
                              schema_name: 'dynamic_test',
                              table_name: 'test_show_if_embedded_recs',
                              category: :details,
                              options: embedded_options,
                              field_list: 'embedded_status embedded_score',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id',
                              position: 11

    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_show_if_embedded_recs, user: @user

    dm
  end
end
