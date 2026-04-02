# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for model reference configurations.
    # Converted from ConfigBase to BaseConfiguration pattern.
    #
    # Handles:
    # - Converting array-style and hash-style references
    # - Singularizing reference keys
    # - Looking up target classes and enriching reference metadata
    # - Warning when referenced models do not exist
    #
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class References < BaseConfiguration
      configure_direct :references, type: :hash

      def self.store_processed_value?
        true
      end

      validate :validate_references

      # Pre-process references using parent context.
      # Converts array/hash formats, singularizes keys, looks up target classes.
      # @param raw [Array, Hash, nil] the raw references value from YAML config
      # @param parent [ExtraOptions] the parent ExtraOptions instance
      # @return [Hash, nil] the processed references hash
      def self.prepare_config(raw, parent)
        return nil unless raw

        config_obj = parent.config_obj
        new_ref = {}

        if raw.is_a? Array
          raw.each do |refitem|
            # Make all keys singular, to simplify configurations
            add_refitem = {}
            refitem.each do |k, _v|
              if k.to_s != k.to_s.singularize
                new_k = k.to_s.singularize.to_sym
                add_refitem[new_k] = refitem.delete(k)
              end
            end

            refitem.merge! add_refitem

            refitem.each do |k, v|
              vi = v[:add_with] && v[:add_with][:extra_log_type]
              ckey = k.to_s
              ckey += "_#{vi}" if vi
              new_ref[ckey.to_sym] = { k => v }
            end
          end
        else
          refs = raw.dup
          fix_refs = {}

          # Make all keys singular, to simplify configurations
          refs.each do |k, _v|
            fix_refs[k] = refs[k] if k.to_s != k.to_s.singularize
          end

          fix_refs.each do |k, _v|
            new_k = k.to_s.singularize.to_sym
            refs[new_k] = refs.delete(k)
          end

          refs.each do |k, v|
            vi = v[:add_with] && v[:add_with][:extra_log_type]
            ckey = k.to_s
            ckey += "_#{vi}" if vi
            new_ref[ckey.to_sym] = { k => v }
          end
        end

        all_bad_items = []
        bad_items = []
        new_ref.each do |_k, refitem|
          bad_items.clear
          refitem.each do |mn, conf|
            to_class = ModelReference.to_record_class_for_type(mn)

            # Avoid breaking app type imports if the resource being pointed to in the reference
            # hasn't been set up yet.
            if to_class.nil? || (to_class.respond_to?(:definition) && !to_class.definition)
              Rails.logger.warn "Definition for class #{to_class} is not set - skipping reference setup for #{mn}"
              all_bad_items << mn
              bad_items << mn
              break
            end

            if to_class
              elt = conf[:add_with] && conf[:add_with][:extra_log_type]
              add_with_elt = nil
              add_with_elt = to_class.human_name_for(elt) if elt && to_class.respond_to?(:human_name_for)
              refitem[mn][:to_record_label] = conf[:result_label] || conf[:label] || add_with_elt || to_class.human_name

              if to_class.respond_to?(:no_master_association)
                refitem[mn][:no_master_association] = to_class.no_master_association
              end

              refitem[mn][:to_model_name_us] = to_class.to_s&.ns_underscore
              refitem[mn][:to_model_class_name] = to_class.to_s
              refitem[mn][:to_table_name] = to_class.table_name
              nil

              if to_class.respond_to?(:definition)
                cd = to_class.definition
                tsn = cd.schema_name
                tct = cd.class.to_s
                refitem[mn][:to_schema_name] = tsn
                refitem[mn][:to_class_type] = tct
              end
            else
              bad_items << mn
              all_bad_items << mn
              Rails.logger.warn "extra log type reference for #{mn} does not exist as a class in #{parent.name} / #{config_obj.name}"
              Rails.logger.info 'Will clean up reference to avoid it being used again in this session'
            end
          end

          # Cleanup bad items
          bad_items.each do |br|
            refitem.delete(br)
          end
        end

        # Store bad_ref_items on parent for backward compatibility
        parent.bad_ref_items = bad_items

        new_ref[:_bad_references] = all_bad_items if all_bad_items.present?

        new_ref
      end

      # Re-process references on an already-initialized ExtraOptions instance.
      # Use this after mutating `instance.references` post-initialization.
      # @param instance [ExtraOptions] the ExtraOptions instance to reprocess
      # @return [void]
      def self.reprocess(instance)
        instance.references = prepare_config(instance.references, instance)
      end

      # Store the references hash value.
      # @return [void]
      def setup_named_configurations
        self.references = hash_configuration.except(:_bad_references).presence
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
