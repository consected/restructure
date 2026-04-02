# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for e-signature definitions.
    # Migrated from ActivityLogOptions#clean_e_sign_def (issue #986).
    #
    # Transforms e_sign document_reference structure: wraps in {item: ...},
    # singularizes keys, and resolves model references.
    #
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class ESignConfig < BaseConfiguration
      configure_direct :e_sign, type: :hash

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

      def setup_named_configurations
        self.e_sign = hash_configuration
      end
    end
  end
end
