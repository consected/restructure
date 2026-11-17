# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for per-field configuration merging.
    # Converted from ConfigBase to BaseConfiguration pattern.
    #
    # Handles:
    # - Parsing field_configs and distributing values to standalone config attributes
    # - Validating field_configs fields are in the field list
    # - Validating field_configs keys are in ValidFieldConfigs
    # - Merging standalone definitions back into field_configs
    #
    # Note: This config class reads from and writes to multiple parent attributes
    # (field_configs, plus the ValidFieldConfigs attributes like caption_before, labels, etc.)
    # because the clean_field_configs method has cross-cutting behavior.
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class FieldConfigs < BaseConfiguration
      configure_direct :field_configs, type: :hash

      def self.store_processed_value?
        true
      end

      # Pre-process field_configs using parent context.
      # Distributes field config values to standalone parent attributes and validates.
      # @param raw [Hash, nil] the raw field_configs value from YAML config
      # @param parent [ExtraOptions] the parent ExtraOptions instance
      # @return [Hash] the processed field_configs hash
      def self.prepare_config(raw, parent)
        # Fields is already processed at this point (it runs before FieldConfigs in the registry)
        fla = parent.fields || []

        return {} if raw.nil?

        fc = raw.symbolize_keys
        failed = false
        validation_errors = []
        fc.each do |fname, fconfig|
          unless fconfig&.is_a? Hash
            validation_errors << "field '#{fname}' is not a Hash"
            failed = true
            fc[fname] = {}
            next
          end

          OptionConfigs::ExtraOptions::ValidFieldConfigs.each do |vc|
            c = fconfig[vc]
            next unless c

            ivar = parent.instance_variable_get("@#{vc}")
            unless ivar
              parent.instance_variable_set("@#{vc}", {})
              ivar = parent.instance_variable_get("@#{vc}")
            end

            ivar.merge!(fname => c)
          end
        end

        if failed
          fc[:_validation_errors] = validation_errors if validation_errors.present?
          return fc
        end

        # Build the list of errors from the explicitly defined field_configs
        efs = fc.keys.map(&:to_s) - fla
        if efs.present?
          validation_errors << "field_configs includes fields that are not in the field list: #{efs.join(', ')}"
        end

        fc.each do |fname, fconfig|
          extra_keys = fconfig.keys - OptionConfigs::ExtraOptions::ValidFieldConfigs
          next if extra_keys.empty?

          validation_errors << "field_configs for #{fname} includes invalid keys: #{extra_keys}"
        end

        # Merge raw standalone definitions into field_configs BEFORE standalone classes clean them.
        # This matches the old clean_field_configs behavior where add_field_configs_from_standalone_defs
        # was called internally, producing raw_field_configs with uncleaned values.
        OptionConfigs::ExtraOptions::ValidFieldConfigs.each do |vc|
          c = parent.instance_variable_get("@#{vc}")
          next unless c

          c_hash = c.is_a?(Hash) ? c.symbolize_keys : next
          c_hash.each do |k, v|
            next unless fla.include?(k.to_s)

            fc[k] ||= {}
            fc[k].merge!({ vc => v })
          end
        end

        # Save pre-clean snapshot for raw_field_configs
        # Using Marshal for deep cloning is safe here since we're only operating on data already in memory
        parent.raw_field_configs = Marshal.load(Marshal.dump(fc))

        fc[:_validation_errors] = validation_errors if validation_errors.present?

        fc
      end

      validate :validate_field_configs

      # Store the field_configs hash value, defaulting to empty hash.
      # @return [void]
      def setup_named_configurations
        self.field_configs = hash_configuration.except(:_validation_errors).presence || {}
      end

      private

      # Validate field_configs entries via ActiveModel validate callback.
      def validate_field_configs
        stored_errors = hash_configuration[:_validation_errors]
        return unless stored_errors&.present?

        stored_errors.each do |msg|
          errors.add(:field_configs, msg)
        end
      end
    end
  end
end
