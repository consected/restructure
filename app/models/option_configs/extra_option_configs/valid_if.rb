# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for validation trigger conditions.
    # Schema docs: docs/admin_reference/general/valid_if.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the entire hash as a single direct attribute after validation and cascade.
    #
    # Handles:
    # - Key validation against ValidValidIfTriggers
    # - on_save cascade to on_create/on_update
    #
    # @example
    #   vi = ValidIf.new(on_save: { all: { this: { field: 'is not null' } } })
    #   vi.valid_if[:on_create] #=> { all: { this: { field: 'is not null' } } }
    class ValidIf < BaseConfiguration
      configure_direct :valid_if, type: :hash

      validate :validate_keys
      validate :validate_trigger_payloads

      # Apply on_save cascade and store as valid_if attribute.
      # Populates configurations for hash-like [] access.
      # @return [void]
      def setup_named_configurations
        vi = hash_configuration.is_a?(Hash) ? hash_configuration.deep_dup : {}
        cascade_on_save(vi)
        self.valid_if = vi
        vi.each { |k, v| configurations[k] = v }
      end

      private

      # Validate keys against the allowed set.
      # @return [void]
      def validate_keys
        return unless validate_hash_attribute(:valid_if, raw_configuration)

        vi = hash_configuration
        return if vi.blank? || vi.keys.empty?

        invalid = vi.keys - OptionConfigs::ExtraOptions::ValidValidIfTriggers
        return if invalid.empty?

        errors.add(:valid_if,
                   "contains invalid keys #{vi.keys} - expected only: #{OptionConfigs::ExtraOptions::ValidValidIfTriggers}")
      end

      def validate_trigger_payloads
        return unless raw_configuration.is_a?(Hash)

        hash_configuration.each do |trigger_name, config|
          next if config.nil? || config.is_a?(Hash)

          add_validation_notice(:valid_if, "#{trigger_name} must be a Hash of conditions")
        end
      end

      # Cascade on_save into on_create and on_update as defaults.
      # on_save values are merged as base, with specific key values taking priority.
      # @param [Hash] vi - the valid_if hash (modified in place)
      # @return [void]
      def cascade_on_save(vi)
        os = vi[:on_save]
        return unless os.is_a?(Hash)

        ou = vi[:on_update].is_a?(Hash) ? vi[:on_update] : {}
        oc = vi[:on_create].is_a?(Hash) ? vi[:on_create] : {}
        vi[:on_update] = os.merge(ou)
        vi[:on_create] = os.merge(oc)
      end
    end
  end
end
