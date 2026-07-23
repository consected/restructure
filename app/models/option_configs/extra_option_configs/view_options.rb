# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for view options.
    # Schema docs: docs/admin_reference/general/view_options.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the entire hash as a single direct attribute.
    #
    # @example
    #   vo = ViewOptions.new(data_attribute: 'field_1', show_embedded: true)
    #   vo.view_options #=> { data_attribute: 'field_1', show_embedded: true }
    class ViewOptions < BaseConfiguration
      configure_direct :view_options, type: :hash

      key_type :boolean, %i[show_embedded_at_top hide_unless_creatable show_cancel only_create_as_reference]
      key_type :string, %i[always_embed_reference always_embed_creatable_reference
                           header_caption alt_width_classes extra_class]
      key_type :string_or_array, %i[data_attribute alt_order view_handlers]
      key_type :hash, %i[sort_references], allowed_keys: %i[attribute direction keep_top null_value]

      SORT_REFERENCE_DIRECTIONS = %w[asc desc reverse].freeze

      validate :validate_key_types
      validate :validate_view_options_shape

      # Store the entire input hash as the view_options attribute
      # and populate configurations for hash-like [] access.
      # @return [void]
      def setup_named_configurations
        self.view_options = hash_configuration.is_a?(Hash) ? (hash_configuration.presence || {}) : {}
        view_options.each { |k, v| configurations[k] = v }
      end

      private

      def validate_view_options_shape
        return unless validate_hash_attribute(:view_options, hash_configuration)
        return unless hash_configuration.key?(:sort_references)

        validate_sort_references(hash_configuration[:sort_references])
      end

      def validate_sort_references(config)
        # key_type already validates sort_references is a Hash and checks allowed sub-keys
        return unless config.is_a?(Hash)

        if config.key?(:attribute) && !(config[:attribute].is_a?(String) || config[:attribute].is_a?(Symbol))
          add_validation_notice(:view_options, 'sort_references.attribute must be a String')
        end

        if config.key?(:direction) && !SORT_REFERENCE_DIRECTIONS.include?(config[:direction].to_s)
          add_validation_notice(:view_options,
                                "sort_references.direction must be one of #{SORT_REFERENCE_DIRECTIONS}")
        end

        return unless config.key?(:keep_top) && ![true, false].include?(config[:keep_top])

        add_validation_notice(:view_options, 'sort_references.keep_top must be true or false')
      end
    end
  end
end
