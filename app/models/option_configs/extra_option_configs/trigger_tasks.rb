# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Reusable configuration class for trigger task hashes or arrays.
    # Used by BatchTrigger (on_record), SaveTrigger (on_create, on_update, etc.)
    # to store trigger task configurations.
    #
    # Accepts either a Hash or an Array of trigger task hashes.
    # Hash values get symbolized keys; arrays are stored as-is.
    #
    # @example Hash input
    #   tasks = TriggerTasks.new(notify: { type: 'email' }, update_this: { field: 'val' })
    #   tasks.tasks  #=> { notify: { type: 'email' }, update_this: { field: 'val' } }
    #
    # @example Array input
    #   tasks = TriggerTasks.new([{ notify: { type: 'email' } }])
    #   tasks.tasks  #=> [{ notify: { type: 'email' } }]
    class TriggerTasks < BaseConfiguration
      configure_direct :tasks, type: :array_or_hash

      DIRECT_CONFIG_KEYS = {
        change_user_roles: %i[if add_role_names remove_role_names on_complete on_failure],
        set_item_flags: %i[first if force_not_editable_save flags add_flags remove_flags on_complete on_failure],
        create_filestore_container: %i[name label create_with_role if on_complete on_failure],
        reload_this: %i[if on_complete on_failure]
      }.freeze

      NAMED_ENTRY_KEYS = {
        notify: %i[type role users emails phones phone_records list_type default_country_code from_user_email
                   ignore_no_recipients layout_template content_template content_template_text subject
                   calendar_invite attachments extra_substitutions importance when on_complete on_failure
                   if app_type user],
        create_reference: %i[if in force_create force_not_valid with_result with on_complete on_failure
                             to_existing_record],
        update_reference: %i[if first force_not_editable_save force_not_valid with_result with on_complete on_failure],
        update_this: %i[if force_not_editable_save force_not_valid with_result with on_complete on_failure],
        add_tracker: %i[if with on_complete on_failure],
        pull_external_data: %i[if force_not_editable_save local_data data_field data_field_format response_code_field
                               method from to post_data success_if on_complete on_failure],
        run_batch_trigger: %i[if resource_name mode limit on_complete on_failure],
        set_save_trigger_results: %i[if element value on_complete on_failure],
        set_variables: %i[if name value on_complete on_failure],
        log: %i[if message severity on_complete on_failure],
        generate_document: %i[content_template_name content_template_text layout_template extra_substitutions
                              container filename content_type path skip_existing replace store_as_user
                              store_in_app_type if on_complete on_failure],
        redcap_request: %i[study project_name local_data method post_data success_if force_not_editable_save data_field
                           data_field_format on_complete on_failure if],
        create_master: %i[if force_create move_this with on_complete on_failure],
        full_text_search: %i[source_fields target_column extra_content ts_config if on_complete on_failure]
      }.freeze

      DELEGATE_TRIGGERS = %i[transaction background case].freeze

      validate :validate_tasks_structure
      validate :validate_trigger_actions

      # Override default field-keyed setup to store the value as a single
      # attribute. Handles both Hash and Array inputs.
      # @return [void]
      def setup_named_configurations
        raw = hash_configuration
        self.tasks = normalize_tasks(raw)
      end

      # Returns true when no tasks are defined.
      def blank?
        tasks.blank?
      end

      # Returns the tasks value for backward compatibility.
      # @return [Hash{Symbol => Object}, Array]
      def symbolize_keys
        tasks || {}
      end

      private

      # Validates the raw input is a Hash or Array of Hashes.
      # @return [void]
      def validate_tasks_structure
        raw = hash_configuration
        return if raw.blank?
        return unless validate_array_or_hash_attribute(:tasks, raw)
        return unless raw.is_a?(Array)

        raw.each_with_index do |item, index|
          next if item.is_a?(Hash)

          add_validation_notice(:tasks, "entry #{index + 1} must be a Hash task definition")
        end
      end

      # Validates trigger action names and their configuration keys.
      # @return [void]
      def validate_trigger_actions
        return if tasks.blank?

        case tasks
        when Hash
          validate_trigger_hash(tasks)
        when Array
          tasks.each { |entry| validate_trigger_hash(entry) if entry.is_a?(Hash) }
        end
      end

      # Validates each trigger name in a hash against ValidSaveTriggers.
      # @param hash [Hash] a single trigger task hash
      # @return [void]
      def validate_trigger_hash(hash)
        valid_names = OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers

        hash.each do |trigger_name, config|
          unless valid_names.include?(trigger_name)
            add_validation_notice(:tasks, "unrecognized trigger action name: #{trigger_name}", level: :warn)
            next
          end

          validate_trigger_keys(trigger_name, config)
        end
      end

      # Validates configuration keys for a specific trigger action.
      # @param trigger_name [Symbol] the trigger action name
      # @param config [Hash] the trigger's configuration
      # @return [void]
      def validate_trigger_keys(trigger_name, config)
        return unless config.is_a?(Hash)

        if DIRECT_CONFIG_KEYS.key?(trigger_name)
          validate_allowed_hash_keys(trigger_name, config, DIRECT_CONFIG_KEYS[trigger_name])
        elsif NAMED_ENTRY_KEYS.key?(trigger_name)
          allowed = NAMED_ENTRY_KEYS[trigger_name]
          config.each_value do |inner|
            next unless inner.is_a?(Hash)

            validate_allowed_hash_keys(trigger_name, inner, allowed)
          end
        end
        # DELEGATE_TRIGGERS: no key validation
      end

      # Recursively normalizes task values, symbolizing hash keys.
      # @param value [Object] the value to normalize
      # @return [Hash, Array, Object, nil]
      def normalize_tasks(value)
        return nil if value.nil?

        case value
        when Array
          value.map { |item| normalize_tasks(item) }
        when Hash
          value.each_with_object({}) do |(key, nested_value), normalized|
            normalized[key.to_sym] = normalize_tasks(nested_value)
          end
        else
          if value.respond_to?(:filtered_hash)
            normalize_tasks(value.filtered_hash)
          elsif value.respond_to?(:to_h) && !value.is_a?(String)
            normalize_tasks(value.to_h)
          else
            value
          end
        end
      end
    end
  end
end
