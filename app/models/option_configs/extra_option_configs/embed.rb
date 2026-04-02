# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for embedded resource definitions.
    # Converted from ConfigBase to BaseConfiguration pattern.
    #
    # Handles:
    # - Converting 'default_embed_resource' string to resource_name hash
    # - Converting plain string to { resource_name: string } hash
    # - Looking up the resource model definition
    # - Warning when embedded resource does not exist
    #
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class Embed < BaseConfiguration
      configure_direct :embed, type: :hash

      def self.store_processed_value?
        true
      end

      validate :validate_embed_resource

      # Pre-process the embed value using parent context.
      # Converts string values and 'default_embed_resource' to hash format.
      # Looks up the resource model and reports warnings for missing resources.
      # @param raw [String, Hash, nil] the raw embed value from YAML config
      # @param parent [ExtraOptions] the parent ExtraOptions instance
      # @return [Hash, nil] the processed embed hash
      def self.prepare_config(raw, parent)
        return nil unless raw

        config_obj = parent.config_obj

        if raw == 'default_embed_resource'
          rn = config_obj.default_embed_resource_name(parent.name)
          emb = { resource_name: rn }
        elsif raw.is_a?(String)
          rn = raw
          emb = { resource_name: rn }
        else
          emb = raw.is_a?(Hash) ? raw.symbolize_keys : {}
          rn = emb[:resource_name]
        end

        resource = Resources::Models.find_by(resource_name: rn)
        emb[:resource_model_def] = resource

        unless resource && resource[:model]
          Rails.logger.warn "embed for #{rn} does not exist as a class in #{parent.name} / #{config_obj.name}"
        end

        emb
      end

      # Store the embed hash value.
      # Handles string input by converting to resource_name hash.
      # @return [void]
      def setup_named_configurations
        raw = hash_configuration
        self.embed = if raw.is_a?(String)
                       { resource_name: raw }
                     elsif raw.is_a?(Hash) && raw.present?
                       raw
                     else
                       raw.presence
                     end
      end

      private

      # Validate that the embedded resource exists.
      def validate_embed_resource
        emb = hash_configuration
        return if emb.blank? || !emb.is_a?(Hash)

        rn = emb[:resource_name]
        return unless rn

        resource = emb[:resource_model_def]
        return if resource && resource[:model]

        errors.add(:embed, "embed for #{rn} does not exist as a resource", type: :warning)
      end
    end
  end
end
