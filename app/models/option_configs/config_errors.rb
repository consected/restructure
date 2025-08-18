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

      def failed_config(target, type, message, extra_details: nil, level: :error)
        rn = resource_name if respond_to?(:resource_name)
        crn = @config_obj.class&.resource_name if @config_obj
        cd = { type.to_s => send(type)&.deep_stringify_keys } if respond_to?(type)
        cd ||= {}
      ensure
        target << {
          type: type,
          config_class: @config_obj.class.name,
          name: name,
          message: message,
          resource_name: rn,
          config_resource_name: crn,
          config_object: @config_obj,
          config_def: cd,
          extra_details:
        }
      end

      #
      # Return list of config errors across all option_configs, or nil if there are none
      # @param [option_configs] option_configs
      # @return [true | nil]
      def all_option_configs_errors(option_configs)
        return unless option_configs

        res = []
        option_configs.select do |oc|
          res += oc.config_errors
        end
        res = nil if res.empty?
        res
      end

      #
      # Return list of config errors and warnings across all option_configs, or nil if there are none
      # @param [object_instance] object_instance
      # @return [true | nil]
      def all_option_configs_notices(object_instance)
        return unless object_instance

        begin
          option_configs = object_instance.option_configs(raise_bad_configs: true)
        rescue StandardError => e
          msg = "Error retrieving option_configs for #{object_instance.class.name}/#{object_instance.id}: #{e}"
          Rails.logger.error msg
          Rails.logger.error e.short_string_backtrace
          res = []
          failed_config(res, :parse_yaml_config, msg, extra_details: e.backtrace.join("\n"), level: :error)
          return res
        end

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
      self.class.failed_config(target, type, message, level:)
    end
  end
end
