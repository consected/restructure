# frozen_string_literal: true

module TestOptionTypesDmSupport
  def setup_multi_option_types_dm(option_type_field: 'option_type', default_option_type_name: nil)
    dm_options = <<~END_YAML
      _configurations:
        use_current_version: true

      _configurations_extras:
        option_type_attr_name: #{option_type_field}
        #{"default_option_type_name: #{default_option_type_name}" if default_option_type_name}

      _default:
        view_options:
          data_attribute: field_1

        labels:
          field_1: Field 1 Label
          field_2: Field 2 Label
          field_3: Field 3 Label
          field_4: Field 4 Label
          field_5: Field 5 Label
          #{option_type_field}: View Type

      _default_extras:
        field_options:
          field_1:
            no_downcase: true

      _merge_default:
        field_configs:
          placeholder_merge_default:
            caption_before: Default caption will remain set

      _merge_override:
        field_configs:
          placeholder_merge_override:
            caption_before: Override with this caption

      _override:
        valid_if:
          on_save:
            not_any:
              this:
                field_5: never valid

      #{default_option_type_name || 'default'}:
        fields:
          - placeholder_default_top
          - field_1
          - field_2
          - field_3
          - #{option_type_field}
          - placeholder_default_bottom

        field_configs:
          placeholder_default_top:
            caption_before:
              caption: This is the default view placeholder at the top
          field_1:
            caption_before:
              keep_label: true
              caption: This is the default view caption for field 1
          field_2:
            field_options:
              edit_as:
                field_type: select_field_2
                alt_options:
                  'Choice 1': choice 1
                  'Choice 2': choice 2
          field_3:
            show_if:
              field_2: choice 2

          placeholder_default_bottom:
            caption_before: This is the default view placeholder at the bottom

      view_1:
        fields:
          - placeholder_view_1_top
          - field_1
          - field_2
        field_configs:
          placeholder_view_1_top:
            caption_before: This is view 1 placeholder at the top
          field_2:
            field_options:
              edit_as:
                field_type: select_field_2
                alt_options:
                  'Choice v1-1': choice v1-1
                  'Choice v1-2': choice v1-2
                  'Choice v1-3': choice v1-3
      view_2:
        fields:
          - field_3
          - field_4
          - field_5
        field_configs:
          field_3:
            labels: field 3 in view 2
          field_4:
            field_options:
              edit_as:
                field_type: select_field_4
                alt_options:
                  'Choice v2-1': choice v2-1
                  'Choice v2-2': choice v2-2
          field_5:
            show_if:
              field_4: choice v2-2

      view_3:
        fields:
          - placeholder_override
          - placeholder_merge_override
          - placeholder_merge_default
          - field_3
          - field_4
          - field_5
        field_configs:
          placeholder_override:
            caption_before: This caption will be overridden
          placeholder_merge_default:
            caption_before: This caption will remain set
          field_3:
            labels: field 3 in view 3
          field_4:
            field_options:
              edit_as:
                field_type: select_field_4
                alt_options:
                  'Choice v2-1': choice v3-1
                  'Choice v2-2': choice v3-2
          field_5:
            labels: Field 5

        valid_if:
          on_save:
            always: true

      # Simple way to test what the defaults look like before any other configurations are applied
      test_defaults_only:

    END_YAML

    DynamicModel.active.where(table_name: 'test_multi_options').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestMultiOption) if defined? DynamicModel::TestMultiOption

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test all fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_multi_options',
                              category: :details,
                              options: dm_options,
                              field_list: "field_1 field_2 field_3 field_4 field_5 #{option_type_field}",
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

    setup_access :dynamic_model__test_multi_options, user: @user

    dm
  end
end
