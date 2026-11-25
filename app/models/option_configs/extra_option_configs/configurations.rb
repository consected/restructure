# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for top-level _configurations options.
    # Schema docs: docs/admin_reference/general/configurations.md
    # Extracted from ExtraOptions.parse_config
    #
    # Stores definition-level settings such as secondary_key, view_sql,
    # batch_trigger, prevent_migrations, etc. Values are stored in
    # the configurations hash keyed by setting name, supporting
    # Hash-like access via [], dig, reject, etc.
    class Configurations < BaseConfiguration
      key_type :boolean, %i[use_current_version prevent_migrations can_change_master no_user_id view_skip_updates]
      key_type :string, %i[secondary_key view_sql tab_caption foreign_key_through_external_id
                           option_type_attr_name default_option_type_name]
      key_type :string_or_array, %i[uniqueness_fields no_sync_fields]
      key_type :hash, %i[batch_trigger], allowed_keys: %i[frequency run_at limit if app_type user]

      validate :validate_key_types
      validate :validate_view_skip_updates_requires_view_sql
      validate :validate_batch_trigger_frequency
      validate :validate_batch_trigger_run_at

      # Hash-compatible reject returning a Hash (not Array).
      # Used by model_generator to filter existing configurations.
      def reject(&)
        configurations.reject(&)
      end

      private

      # An unparseable frequency would otherwise leave the recurring job to fall back to an hourly schedule
      def validate_batch_trigger_frequency
        return unless hash_configuration.is_a?(Hash)

        batch_trigger = hash_configuration[:batch_trigger]
        return unless batch_trigger.is_a?(Hash)

        frequency = batch_trigger[:frequency]
        if frequency.blank?
          if batch_trigger[:run_at].present?
            add_validation_notice(:batch_trigger, 'batch_trigger run_at requires a frequency')
          end
          return
        end
        return if frequency == 'once' || FieldDefaults.recurring_interval(frequency)

        add_validation_notice(
          :batch_trigger,
          "batch_trigger frequency #{frequency.inspect} is invalid. " \
          "Use 'once' or a positive 'n units' such as '15 minutes', '1 hour', '30 days' or '1 week'"
        )
      end

      # An unparseable run_at would otherwise fail to schedule, or schedule a one-time job far in the future
      def validate_batch_trigger_run_at
        return unless hash_configuration.is_a?(Hash)

        batch_trigger = hash_configuration[:batch_trigger]
        return unless batch_trigger.is_a?(Hash)

        run_at = batch_trigger[:run_at]
        return if run_at.blank?
        return if FieldDefaults.valid_run_at?(run_at, single: batch_trigger[:frequency] == 'once')

        add_validation_notice(
          :batch_trigger,
          "batch_trigger run_at #{run_at.inspect} is not a valid time. " \
          "Use a time such as '6:00pm' or 'monday 8:00am' (a list is allowed for recurring frequencies), " \
          "or a full date and time such as '2026-05-01 02:00' for 'once'"
        )
      end

      # view_skip_updates only makes sense for a view-backed dynamic model
      def validate_view_skip_updates_requires_view_sql
        return unless hash_configuration.is_a?(Hash)
        return unless hash_configuration[:view_skip_updates]
        return if hash_configuration[:view_sql].present?

        add_validation_notice(:view_skip_updates, 'view_skip_updates requires view_sql to be set')
      end
    end
  end
end
