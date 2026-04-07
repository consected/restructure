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

      ALLOWED_KEYS = %i[
        show_embedded_at_top hide_unless_creatable data_attribute
        always_embed_reference always_embed_creatable_reference alt_order
        show_cancel only_create_as_reference sort_references view_handlers
        header_caption alt_width_classes extra_class
      ].freeze
      BOOLEAN_KEYS = %i[
        show_embedded_at_top hide_unless_creatable show_cancel only_create_as_reference
      ].freeze
      STRING_OR_ARRAY_KEYS = %i[data_attribute alt_order view_handlers].freeze
      STRING_KEYS = %i[
        always_embed_reference always_embed_creatable_reference
        header_caption alt_width_classes extra_class
      ].freeze
      SORT_REFERENCE_KEYS = %i[attribute direction keep_top null_value].freeze
      SORT_REFERENCE_DIRECTIONS = %w[asc desc reverse].freeze

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

        validate_allowed_hash_keys(:view_options, hash_configuration, ALLOWED_KEYS)

        BOOLEAN_KEYS.each do |key|
          next unless hash_configuration.key?(key)
          next if [true, false].include?(hash_configuration[key])

          add_validation_notice(:view_options, "#{key} must be true or false")
        end

        STRING_OR_ARRAY_KEYS.each do |key|
          next unless hash_configuration.key?(key)
          next if string_or_array_of_strings?(hash_configuration[key])

          add_validation_notice(:view_options, "#{key} must be a String or an Array of Strings")
        end

        STRING_KEYS.each do |key|
          next unless hash_configuration.key?(key)
          next if string_like?(hash_configuration[key])

          add_validation_notice(:view_options, "#{key} must be a String")
        end

        validate_sort_references(hash_configuration[:sort_references]) if hash_configuration.key?(:sort_references)
      end

      def validate_sort_references(config)
        unless validate_hash_attribute(:view_options, config, allow_blank: false)
          add_validation_notice(:view_options, 'sort_references must be a Hash')
          return
        end

        validate_allowed_hash_keys(:view_options, config, SORT_REFERENCE_KEYS)

        if config.key?(:attribute) && !string_like?(config[:attribute])
          add_validation_notice(:view_options, 'sort_references.attribute must be a String')
        end

        if config.key?(:direction) && !SORT_REFERENCE_DIRECTIONS.include?(config[:direction].to_s)
          add_validation_notice(:view_options,
                                "sort_references.direction must be one of #{SORT_REFERENCE_DIRECTIONS}")
        end

        return unless config.key?(:keep_top) && ![true, false].include?(config[:keep_top])

        add_validation_notice(:view_options, 'sort_references.keep_top must be true or false')
      end

      def string_like?(value)
        value.is_a?(String) || value.is_a?(Symbol)
      end

      def string_or_array_of_strings?(value)
        return true if string_like?(value)
        return false unless value.is_a?(Array)

        value.all? { |item| string_like?(item) }
      end
    end
  end
end
