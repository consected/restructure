# frozen_string_literal: true

module Dynamic
  module ActivityLogSyncHandler
    extend ActiveSupport::Concern

    def self.no_sync_fields_configuration_notice(definition:, message:, invalid_fields: nil)
      details = { semantic_validation: true }
      details[:invalid_fields] = invalid_fields if invalid_fields
      configuration = definition&.configurations

      OptionConfigs::ConfigErrors.configuration_notice(
        config_obj: definition,
        type: :no_sync_fields,
        name: definition&.name,
        resource_name: definition&.resource_name,
        config_def: { 'no_sync_fields' => configuration&.dig(:no_sync_fields) },
        message: "no_sync_fields #{message}",
        extra_details: details
      )
    end

    class_methods do
      # Return the activity log fields that are copied from the parent item.
      #
      # @return [Array<String>] effective parent-synchronized field names
      def fields_to_sync
        inferred_fields_to_sync - normalized_no_sync_fields(definition&.configurations)
      end

      # Return fields shared by the activity log and its parent before opt-outs.
      #
      # @return [Array<String>] inferred parent-synchronized field names
      def inferred_fields_to_sync
        attribute_names & (parent_class.attribute_names - %w[id master_id user_id created_at updated_at item_id])
      rescue NameError, ActiveRecord::StatementInvalid => e
        raise FphsException,
              "Could not determine parent-synchronized fields for #{name}: #{e.message}"
      end

      # Return semantic configuration notices without mutating the definition configuration.
      #
      # @return [Array<Hash>] no-sync configuration errors
      def no_sync_fields_configuration_notices
        configuration = definition&.configurations
        configured_fields = normalized_no_sync_fields(configuration)
        return [] if configured_fields.empty?

        inferred_fields = inferred_fields_to_sync
        invalid_fields = configured_fields - inferred_fields
        return [] if invalid_fields.empty?

        [no_sync_fields_configuration_notice(
          "#{invalid_fields.join(', ')} must be fields shared by the activity log and its parent item type",
          invalid_fields: invalid_fields
        )]
      rescue StandardError => e
        [no_sync_fields_configuration_notice("could not validate configured fields: #{e.message}")]
      end

      # Normalize the configured no-sync field value to field-name strings.
      #
      # @param configuration [OptionConfigs::ExtraOptionConfigs::Configurations, nil]
      # @return [Array<String>] configured field names, or an empty array when invalid or absent
      def normalized_no_sync_fields(configuration)
        value = configuration&.dig(:no_sync_fields)
        values = value.is_a?(Array) ? value : [value]
        return [] unless values.all? { |field| field.is_a?(String) || field.is_a?(Symbol) }

        values.map(&:to_s)
      end

      # Build a semantic no-sync configuration error for the standard notice collector.
      #
      # @param message [String] error detail
      # @return [Hash] configuration error notice
      def no_sync_fields_configuration_notice(message, invalid_fields: nil)
        Dynamic::ActivityLogSyncHandler.no_sync_fields_configuration_notice(
          definition:, message:, invalid_fields:
        )
      end
    end
  end
end
