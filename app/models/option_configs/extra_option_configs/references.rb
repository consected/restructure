# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for model reference configurations.
    #
    # Uses the source_attribute pattern: the registry key is :references_config,
    # but the raw input is read from :references (a base_key_attribute).
    # After processing:
    # - extra_options.references = enriched hash (views/models consume this)
    # - extra_options.references_config = this References instance (configurations hold ReferenceEntry objects)
    #
    # Handles:
    # - Converting array-style and hash-style references
    # - Singularizing reference keys
    # - Looking up target classes and enriching reference metadata
    # - Warning when referenced models do not exist
    class References < BaseConfiguration
      configure_direct :references, type: :hash

      # Keys added by enrich_ref_metadata that are not part of admin input.
      COMPUTED_KEYS = %i[
        to_record_label no_master_association to_model_name_us
        to_model_class_name to_table_name to_schema_name to_class_type
      ].freeze

      # Named configuration for a single reference entry's admin-configured attributes.
      # Validates that only recognized keys are present in each reference config.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[
          label result_label from without_reference add add_with
          filter_by order_by limit type_config
          view_as view_options showable_if creatable_if
          prevent_disable also_disable_record allow_disable_if_not_editable
          prevent_reload_on_save action_position
        ]
      end

      ReferenceEntry = NamedConfiguration

      def self.source_attribute
        :references
      end

      def self.store_processed_value?
        true
      end

      validate :validate_references

      # Pre-process references using parent context.
      # Normalizes array/hash formats, singularizes keys, resolves target classes,
      # and enriches reference entries with class metadata.
      # @param raw [Array, Hash, nil] the raw references value from YAML config
      # @param parent [ExtraOptions] the parent ExtraOptions instance
      # @return [Hash, nil] the processed references hash
      def self.prepare_config(raw, parent)
        return nil unless raw

        new_ref = normalize_references(raw)
        bad_items = resolve_reference_classes(new_ref, parent)
        new_ref[:_bad_references] = bad_items if bad_items.present?
        new_ref
      end

      # Normalize raw references from Array or Hash format into a unified hash.
      # Each entry maps a composite key to { model_name => config }.
      # Plural keys are singularized (e.g. :player_contacts => :player_contact).
      # @param raw [Array, Hash] raw references from YAML config
      # @return [Hash] normalized references hash
      private_class_method def self.normalize_references(raw)
        ref_items = raw.is_a?(Array) ? raw.map(&:dup) : [raw.dup]

        result = {}
        ref_items.each do |refitem|
          singularize_keys!(refitem)
          refitem.each do |k, v|
            result[composite_ref_key(k, v)] = { k => v }
          end
        end
        result
      end

      # Replace all plural keys with their singular form, mutating the hash.
      # @param hash [Hash] hash whose keys to singularize
      # @return [void]
      private_class_method def self.singularize_keys!(hash)
        hash.keys.each do |k|
          singular = k.to_s.singularize.to_sym
          next if singular == k

          hash[singular] = hash.delete(k)
        end
      end

      # Build a composite reference key from the model name and optional extra_log_type.
      # For example, :player_contact or :player_contact_initial_review.
      # @param model_name [Symbol] the singularized model name
      # @param config [Hash] the reference configuration
      # @return [Symbol] composite key
      private_class_method def self.composite_ref_key(model_name, config)
        elt = config.dig(:add_with, :extra_log_type)
        key = model_name.to_s
        key += "_#{elt}" if elt
        key.to_sym
      end

      # Resolve target classes for each reference and enrich with metadata.
      # Removes entries whose classes cannot be resolved.
      # @param new_ref [Hash] normalized references hash (mutated in place)
      # @param parent [ExtraOptions] the parent ExtraOptions instance (used for log context)
      # @return [Array<Symbol>] model names that could not be resolved
      private_class_method def self.resolve_reference_classes(new_ref, parent)
        all_bad_items = []

        new_ref.each_value do |refitem|
          bad_items = []

          refitem.each do |mn, conf|
            to_class = ModelReference.to_record_class_for_type(mn)

            # Skip references whose target model or definition isn't set up yet,
            # to avoid breaking app type imports.
            if to_class.nil? || (to_class.respond_to?(:definition) && !to_class.definition)
              Rails.logger.warn "Definition for class #{to_class} is not set - skipping reference setup for #{mn}"
              all_bad_items << mn
              bad_items << mn
              break
            end

            enrich_ref_metadata(refitem, mn, conf, to_class)
          end

          bad_items.each { |br| refitem.delete(br) }
        end

        all_bad_items
      end

      # Enrich a single reference entry with resolved class metadata.
      # @param refitem [Hash] the reference item hash (mutated)
      # @param model_name [Symbol] the model name key
      # @param conf [Hash] the reference configuration
      # @param to_class [Class] the resolved target class
      # @return [void]
      private_class_method def self.enrich_ref_metadata(refitem, model_name, conf, to_class)
        elt = conf.dig(:add_with, :extra_log_type)
        add_with_label = to_class.human_name_for(elt) if elt && to_class.respond_to?(:human_name_for)

        entry = refitem[model_name]
        entry[:to_record_label] = conf[:result_label] || conf[:label] || add_with_label || to_class.human_name
        entry[:no_master_association] = to_class.no_master_association if to_class.respond_to?(:no_master_association)
        entry[:to_model_name_us] = to_class.to_s.ns_underscore
        entry[:to_model_class_name] = to_class.to_s
        entry[:to_table_name] = to_class.table_name

        return unless to_class.respond_to?(:definition)

        defn = to_class.definition
        entry[:to_schema_name] = defn.schema_name
        entry[:to_class_type] = defn.class.to_s
      end

      # Re-process references on an already-initialized ExtraOptions instance.
      # Use this after mutating `instance.references` post-initialization.
      # @param instance [ExtraOptions] the ExtraOptions instance to reprocess
      # @return [void]
      def self.reprocess(instance)
        instance.references = prepare_config(instance.references, instance)
      end

      # Store the enriched hash on the direct attribute and create ReferenceEntry
      # named configurations for each entry's input-only keys.
      # @return [void]
      def setup_named_configurations
        self.references = hash_configuration.except(:_bad_references).presence
        return unless references

        references.each do |composite_key, refitem|
          refitem.each_value do |config|
            input_only = config.except(*COMPUTED_KEYS)
            add_named_configuration(composite_key, input_only)
          end
        end
      end

      private

      # Validate that all referenced models exist.
      def validate_references
        bad_refs = hash_configuration[:_bad_references]
        return unless bad_refs&.present?

        bad_refs.each do |mn|
          errors.add(:references, "reference for #{mn} does not exist as a class", type: :warning)
        end
      end
    end
  end
end
