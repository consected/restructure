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
          got = render partial: 'common_templates/edit_fields/is_general_selection',
                       locals: local_vars[:locals]
        end
      end

      if !got && (form_object_instance.model_data_type == :external_identifier)

        @already_shown_external_id = true
        unless @already_shown_external_id
          got = render partial: 'common_templates/edit_fields/is_external_id',
                       locals: local_vars[:locals]
        end
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

      if is_current_admin_sample?
        got = "<div class=\"admin-sample-field-info\"><span>#{field_name}</span></div>#{got}".html_safe
      end

      if opt[:calculate_with]
        cw = opt[:calculate_with]
        if cw
          got ||= ''
          got = got.html_safe
          got += <<~END_SCRIPT
            <script>
              _fpa.calculate_with = _fpa.calculate_with || {};
              var cwdef = _fpa.calculate_with['#{field_name_sym}'] = #{cw.to_json.html_safe};

              _fpa.utils.calc_field('#{field_name_sym}', '#{form_object_item_type_us}');
            </script>
          END_SCRIPT
                 .html_safe
        end

      end

      @matched_name ||= match_name
      got
    end
  end
end
