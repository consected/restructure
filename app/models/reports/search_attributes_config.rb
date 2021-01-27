module Reports
  class SearchAttributesConfig
    attr_accessor :errors, :report, :configurations

    class NamedConfiguration < OptionConfigs::BaseOptions
      include OptionsHandler

      attr_accessor :owner, :use_hash_config

      def persisted?
        owner&.persisted? || true
      end

      configure_attributes %i[name label type all item_type multiple default disabled hidden selections conditions]
    end

    def initialize(report)
      self.report = report
      self.errors = []
      setup_configurations
    end

    def setup_configurations
      self.configurations = {}
      hash_configuration.each do |k, v|
        newconf = {
          name: k,
          type: v.first.first
        }.merge(v.first.last)
        newconf = newconf.symbolize_keys

        configurations[k.to_sym] = NamedConfiguration.new self, use_hash_config: newconf
      end
    end

    #
    # Access a configuration by symbolized key name
    # @param [Symbol] key
    # @return [NamedConfiguration]
    def [](key)
      configurations[key]
    end

    def each
      configurations.each
    end

    #
    # The persisted configuration YAML (or JSON) in the report definition record
    # @return [String]
    def search_attrs_text
      report.search_attrs
    end

    #
    # Parse the YAML (or JSON) search attributes definition, stored in #search_attrs
    # and return a Hash with the definition
    def hash_configuration
      @search_attributes_config = {} if search_attrs_text.blank?
      begin
        @search_attributes_config ||= JSON.parse search_attrs_text
      rescue StandardError
        @search_attributes_config ||= YAML.safe_load(search_attrs_text, [], [], true)
      end
    end

    def valid?
      hash_configuration
      true
    rescue StandardError => e
      errors << "Invalid: #{e}"
      nil
    end

    def persisted?
      report.persisted?
    end
  end
end
