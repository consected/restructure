# frozen_string_literal: true

# Render an edit field for blocks, reports and admin import
module EditFields
  module EditFormFieldHelper
    def edit_form_field(
      form:,
      field_name_sym:,
      field_name:,
      column_type:,
      general_selection_name:,
      form_object_instance:,
      form_object_item_type_us:,
      caption_before:,
      labels:,
      locals:,
      dialog_before: nil,
      embedded: nil
    )
      @matched_name = nil
      dialog_before ||= {}

      local_vars = locals
      local_vars[:locals][:locals] = local_vars[:locals]
      # Get the list of filenames for templates, making them into the matchers we wish to use.
      # Sort by length to ensure the more specific matchers appear before the less specific matchers.
      # For example 'name_starts_with_select_record_from' should be tested before 'name_starts_with_select'
      if @f_names
        f_names = @f_names
      else
        efs = Dir.entries(Rails.root.join('app', 'views', 'common_templates', 'edit_fields'))
        f_names = @f_names = efs.reject { |fn| fn.start_with?('.') }
                                .map { |fn| fn[1..-10] }
                                .sort { |a, b| b.length <=> a.length }
      end

      got = false

      curr_field_name = field_name
      opt = field_options_for(form_object_instance, field_name_sym, reset: true)

      if opt[:edit_as]
        curr_field_name = opt[:edit_as][:field_type] || curr_field_name
        local_vars[:locals][:field_name] = curr_field_name
      end

      curr_field_name_sym = curr_field_name.to_sym

      if !got && curr_field_name.start_with?('redcap_')
        # Use a select rather than just includes? to ensure brakeman doesn't complain about params driving render paths
        resname = f_names.find { |f| f == curr_field_name }
        if resname
          partial_fn = "common_templates/edit_fields/#{resname}"
          got = render partial: partial_fn, locals: local_vars[:locals]
        end
      end

      unless got
        match_name = "name_is_#{curr_field_name_sym}"
        # Use a select rather than just includes? to ensure brakeman doesn't complain about params driving render paths
        resname = f_names.find { |f| f == match_name }
        if resname
          partial_fn = "common_templates/edit_fields/#{resname}"

          got = render partial: partial_fn, locals: local_vars[:locals]
        end
      end

      unless got
        mapped = f_names.select { |fn| fn.start_with?('name_starts_with_') }
                        .map { |fn| fn.sub('name_starts_with_', '') }
        mapped.each do |sw|
          match_name = "name_starts_with_#{sw}"
          next unless curr_field_name.start_with?("#{sw}_") && f_names.include?(match_name)

          partial_fn = "common_templates/edit_fields/#{match_name}"

          got = render partial: partial_fn, locals: local_vars[:locals]
          break
        end
      end

      unless got
        mapped = f_names.select { |fn| fn.start_with?('name_ends_with_') }
                        .map { |fn| fn.sub('name_ends_with_', '') }
        mapped.each do |ew|
          match_name = "name_ends_with_#{ew}"
          next unless curr_field_name.end_with?("_#{ew}") && f_names.include?(match_name)

          partial_fn = "common_templates/edit_fields/#{match_name}"

          got = render partial: partial_fn, locals: local_vars[:locals]
          break
        end
      end

      if !got && respond_to?("#{curr_field_name}_options")

        got = render partial: 'common_templates/edit_fields/respond_to_options', locals: local_vars[:locals]
      end

      unless got

        @gs_exists ||= {}
        ckey = "edit_form_field--#{form_object_instance.class.name}--#{curr_field_name_sym}"
        if @gs_exists[ckey].nil?
          @gs_exists[ckey] =
            !!Classification::GeneralSelection.exists_for?(form_object_instance, curr_field_name_sym)
        end
        gs_exists = @gs_exists[ckey]

        if gs_exists
          gs_item_type = "#{general_selection_name}_#{field_name_sym}"
          is_report = form_object_instance.model_data_type == :report

          if is_report
            # For reports, try to get the general selection with quiet_fail
            fallback_allowed = use_missing_general_selection_text_fallback?(form_object_instance)
            gs = general_selection(gs_item_type.to_sym,
                                   value: form_object_instance.send(field_name_sym),
                                   quiet_fail: true)

            if gs.blank?
              if fallback_allowed
                # Allow fallback to default field for reports without protected view handlers
                Rails.logger.warn(
                  "Edit field fallback to default input for missing general selection: #{gs_item_type} " \
                  "(class #{form_object_instance.class.name})"
                )
              else
                # Raise error for reports with protected view handlers
                raise FphsException,
                      "The general selection #{gs_item_type} has not been defined. Please inform the administrator of this error."
              end
            else
              got = render partial: 'common_templates/edit_fields/is_general_selection',
                           locals: local_vars[:locals]
            end
          else
            # Non-reports always render the general selection field
            got = render partial: 'common_templates/edit_fields/is_general_selection',
                         locals: local_vars[:locals]
          end
        end
      end

      if !got && (form_object_instance.model_data_type == :external_identifier)

        unless @already_shown_external_id
          got = render partial: 'common_templates/edit_fields/is_external_id',
                       locals: local_vars[:locals]
        end
        @already_shown_external_id = true
      end

      unless got
        # Handle Brakeman issue with using column type directly to generate partial path
        valid_col_types = %i[boolean integer decimal float datetime date jsonb json]
        ct = valid_col_types.find { |c| c == column_type.to_sym }

        match_name = "column_type_#{ct}"

        if f_names.include? match_name
          partial_fn = "common_templates/edit_fields/#{match_name}"
          got = render partial: partial_fn, locals: local_vars[:locals]
        end
      end

      got ||= render partial: 'common_templates/edit_fields/default', locals: local_vars[:locals]

      if is_current_admin_sample? && !curr_field_name.start_with?('hidden')
        got = "<div class=\"admin-sample-field-info\"><span>#{field_name}</span></div>#{got}".html_safe
      end

      if opt[:calculate_with]
        cw = opt[:calculate_with]
        if cw
          got ||= ''
          got = got.html_safe
          got += javascript_tag(nonce: true) do
            <<~END_JS.html_safe
              _fpa.calculate_with = _fpa.calculate_with || {};
              var cwdef = _fpa.calculate_with['#{field_name_sym}'] = #{cw.to_json.html_safe};

              _fpa.utils.calc_field('#{field_name_sym}', '#{form_object_item_type_us}');
            END_JS
          end
        end

      end

      @matched_name ||= match_name
      got
    end

    # Whether a missing/empty general selection on a report-backed form should
    # fall back to a plain text input (returning true) instead of raising
    # FphsException (returning false). Strict error behavior is retained for
    # report items backed by dynamic models that declare protected view
    # handlers (address, contact, secondary_info, subject), where the
    # underlying templates require the selection list to operate correctly.
    # Called from edit_fields partials, so kept public.
    def use_missing_general_selection_text_fallback?(form_object_instance)
      !report_item_type_requires_general_selection_error?(form_object_instance)
    end

    # Decision helper for the edit_fields partials when a general selection
    # lookup returns blank. Returns:
    #   - false when the selection list is present (caller renders the select)
    #   - true  when the caller should render the text-input fallback
    # Raises FphsException with the canonical "has not been defined" message
    # when fallback is not permitted for this form_object_instance.
    # Called from edit_fields partials, so kept public.
    def general_selection_missing_fallback?(gs, gs_item_type, form_object_instance)
      return false if gs.present?
      return true if use_missing_general_selection_text_fallback?(form_object_instance)

      raise FphsException,
            "The general selection #{gs_item_type} has not been defined. " \
            'Please inform the administrator of this error.'
    end

    # Render a default text field for a selection-like attribute where the
    # general selection definitions are missing. Logs a warning so the
    # configuration gap is surfaced without breaking the user's workflow.
    # Called from edit_fields partials, so kept public.
    def missing_general_selection_text_fallback(form, field_name_sym, form_object_instance, form_object_item_type_us,
                                                gs_item_type)
      Rails.logger.warn(
        "Edit field fallback to default input for missing general selection: #{gs_item_type} " \
        "(class #{form_object_instance.class.name})"
      )
      form.text_field field_name_sym,
                      data: { attr_name: field_name_sym, object_name: form_object_item_type_us }
    end

    def report_item_type_requires_general_selection_error?(form_object_instance)
      return false unless form_object_instance.model_data_type == :report

      table_name = form_object_instance.class.table_name
      @report_item_type_requires_general_selection_error ||= {}
      if @report_item_type_requires_general_selection_error.key?(table_name)
        return @report_item_type_requires_general_selection_error[table_name]
      end

      view_handlers = DynamicModel.active.find_by(table_name: table_name)&.default_options&.view_options&.dig(:view_handlers)
      protected_handlers = %w[address contact secondary_info subject]

      @report_item_type_requires_general_selection_error[table_name] =
        (Array(view_handlers).map(&:to_s) & protected_handlers).present?
    rescue StandardError => e
      Rails.logger.warn("Failed to detect report view handler for general selection fallback: #{e}")
      false
    end
  end
end
