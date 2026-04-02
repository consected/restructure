# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for e-signature definitions.
    #
    # Uses the source_attribute pattern: the registry key is :e_sign_config,
    # but the raw input is read from :e_sign (an add_key_attribute on ActivityLogOptions).
    # After processing:
    # - extra_options.e_sign = enriched hash (runtime code consumes this)
    # - extra_options.e_sign_config = this ESignConfig instance (input-only attributes)
    #
    # Handles:
    # - Wrapping document_reference in {item: ...}
    # - Singularizing keys within document_reference entries
    # - Resolving model references and enriching with class metadata
    class ESignConfig < BaseConfiguration
      configure_direct :e_sign, type: :hash
      configure_attributes %i[create_document auto_create_document document_reference title intro]

      # Keys added by prepare_config within document_reference model entries
      # that are not part of admin input.
      COMPUTED_KEYS = %i[to_record_label no_master_association to_model_name_us].freeze

      def self.source_attribute
        :e_sign
      end

      def self.store_processed_value?
        true
      end

      # Pre-process the e_sign config: wrap document_reference, singularize keys,
      # and resolve model references.
      # @param raw [Hash, nil] the raw e_sign config
      # @param _parent [ExtraOptions] the parent ExtraOptions instance (unused)
      # @return [Hash, nil] the processed e_sign hash
      def self.prepare_config(raw, _parent)
        return nil unless raw

        raw = raw.symbolize_keys if raw.is_a?(Hash)

        # Wrap document_reference in {item: ...} if not already wrapped
        raw[:document_reference] = { item: raw[:document_reference] } unless raw[:document_reference][:item]

        raw[:document_reference].each_value do |refitem|
          # Singularize all keys
          refitem.transform_keys! do |k|
            k.to_s.singularize.to_sym
          end

          refitem.each do |mn, conf|
            to_class = ModelReference.to_record_class_for_type(mn)

            refitem[mn][:to_record_label] = conf[:label] || to_class&.human_name
            if to_class&.respond_to?(:no_master_association)
              refitem[mn][:no_master_association] = to_class.no_master_association
            end
            refitem[mn][:to_model_name_us] = to_class&.to_s&.ns_underscore
          end
        end

        raw
      end

      # Store enriched hash on the direct attribute and assign input-only
      # configured attributes for round-trip serialization.
      # @return [void]
      def setup_named_configurations
        self.e_sign = hash_configuration.presence
        return unless e_sign

        # Assign top-level input attributes
        e_sign.each do |k, v|
          next if k == :document_reference

          send("#{k}=", v) if respond_to?("#{k}=")
        end

        # Store input-only document_reference (strip computed keys from nested model entries)
        return unless e_sign[:document_reference]

        self.document_reference = strip_doc_ref_computed_keys(e_sign[:document_reference])
      end

      private

      # Strip computed keys from each model entry nested within document_reference.
      # Structure: { item: { model_name: { from: ..., to_record_label: ..., ... } } }
      # @param doc_ref [Hash] the document_reference hash
      # @return [Hash] document_reference with computed keys removed from model entries
      def strip_doc_ref_computed_keys(doc_ref)
        doc_ref.transform_values do |group|
          next group unless group.is_a?(Hash)

          group.transform_values do |entry|
            next entry unless entry.is_a?(Hash)

            entry.except(*COMPUTED_KEYS)
          end
        end
      end
    end
  end
end
