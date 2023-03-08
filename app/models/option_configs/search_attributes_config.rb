# frozen_string_literal: true

module OptionConfigs
  #
  # Definition of the search attributes that appear on search forms.
  # These become accessible in a report instance as:
  #   report.search_attributes_config
  class SearchAttributesConfig < BaseConfiguration
    class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
      configure_attributes %i[name label type all item_type multiple default disabled hidden selections conditions
                              resource_name defined_selector filter_selector]
    end

    #
    # Override OptionConfigs::BaseConfiguration#setup_named_configurations to
    # reorganize the stored search attribute config YAML structure into
    # a more sensible, flat named configuration format
    # Automatically called when this class is initialized
    def setup_named_configurations
      self.configurations = {}
      hash_configuration.each do |k, v|
        newconf = {
          name: k,
          type: v.first.first
        }

        newconf.merge!(v.first.last) if v.first.last
        newconf = newconf.symbolize_keys

        configurations[k.to_sym] = NamedConfiguration.new self, use_hash_config: newconf
      end
    end

    #
    # The persisted configuration YAML (or JSON) in the report definition record
    # @return [String]
    def config_text
      owner.search_attrs
    end

    def config_text=(value)
      owner.search_attrs = value
    end

    def valid?
      hash_configuration
      true
    rescue StandardError => e
      errors << "Invalid: #{e}"
      nil
    end

    def persisted?
      owner.persisted?
    end
  end
end
