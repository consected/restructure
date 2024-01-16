# frozen_string_literal: true

module OptionConfigs
  module ConfigErrors
    extend ActiveSupport::Concern

    included do
      attr_accessor :config_errors, :config_warnings
    end

    class_methods do
      def raise_bad_configs(option_configs)
        # None defined - override with real checks
        # @todo
      end

      #
      # Return list of config errors across all option_configs, or nil if there are none
      # @param [option_configs] option_configs
      # @return [true | nil]
      def all_option_configs_errors(option_configs)
        res = []
        option_configs.select do |oc|
          res += oc.config_errors
        end
        res = nil if res.empty?
        res
      end

      #
      # Return list of config errors and warnings across all option_configs, or nil if there are none
      # @param [option_configs] option_configs
      # @return [true | nil]
      def all_option_configs_notices(option_configs)
        res = []
        option_configs.select do |oc|
          val = oc.config_errors
          res += val if val
          val = oc.config_warnings
          res += val if val
        end
        res = nil if res.empty?
        res
      end
    end

    def initialize
      self.config_errors = []
      self.config_warnings = []
    end

    protected

    def valid_config_keys?(config, valid_keys)
      config.keys.empty? || (config.keys - valid_keys).empty?
    end

    def failed_config(type, message, level: :error)
      target = if level == :error
                 config_errors
               elsif level == :warn
                 config_warnings
               else
                 config_errors
               end

      target << {
        type: type,
        config_class: @config_obj.class.name,
        name: name,
        message: message,
        resource_name: resource_name,
        config_def: { type.to_s => send(type)&.deep_stringify_keys }
      }
    end
  end
end
