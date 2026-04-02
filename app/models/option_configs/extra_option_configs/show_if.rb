# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for conditional visibility (show_if).
    # Extracted from ExtraOptions#clean_show_if_def
    #
    # Values are arbitrary condition hashes keyed by field name.
    # show_if_condition_strings (REDCap branching logic) are preprocessed
    # via prepare_config before initialization.
    class ShowIf < BaseConfiguration
      # No NamedConfiguration — values are arbitrary condition hashes

      # Pre-process config using parent context to merge
      # show_if_condition_strings (REDCap branching logic).
      # Called by ExtraOptions before initialization.
      # @param [Hash] raw - raw show_if hash from YAML
      # @param [ExtraOptions] parent - parent ExtraOptions instance
      # @return [Hash] merged show_if hash
      def self.prepare_config(raw, parent)
        raw ||= {}

        parent.show_if_condition_strings&.each do |fn, val|
          next if val.nil? || val.empty? || raw[fn]

          begin
            bl = Redcap::DataDictionaries::BranchingLogic.new(val)
            sis = bl&.generate_show_if
            raw[fn] = sis if sis.present?
          rescue StandardError => e
            Rails.logger.warn "Failed to generate real show_if (in #{parent.config_obj&.resource_name}) " \
                              "for #{fn}: #{val}\n#{e}"
            raw[fn] = { generate_show_if: "failed - #{e}" }
          end
        end

        raw
      end
    end
  end
end
