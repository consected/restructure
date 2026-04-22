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

      def failed_config(from_options, target, type, message,
                        name = nil, resource_name = nil,
                        extra_details: nil, level: :error)
        config_obj = from_options&.config_obj
        name ||= self.name if respond_to?(:name)
        resource_name ||= self.resource_name if respond_to?(:resource_name)
        crn = config_obj.class&.resource_name if config_obj
        option_variable = from_options.instance_variable_get("@#{type}")
        cd = { type.to_s => option_variable&.deep_stringify_keys } if option_variable.is_a?(Hash)
        cd ||= {}
      ensure
        target << {
          type: type,
          config_class: config_obj.class.name,
          name: name,
          message: message,
          resource_name: resource_name,
          config_resource_name: crn,
          config_object: config_obj,
          config_def: cd,
          extra_details:
        }
      end

      #
      # Return list of config errors across all option_configs, or nil if there are none
      # @param [option_configs] option_configs
      # @return [true | nil]
      def all_option_configs_errors(object_instance_or_config)
        all_option_configs_notices(object_instance_or_config, levels: %i[errors])
      end

      #
      # Return list of config errors and warnings across all option_configs, or nil if there are none
      # @param [object_instance] object_instance
      # @param [Array[Symbol]] levels to return (:warnings, :errors)
      # @return [true | nil]
      def all_option_configs_notices(object_instance_or_config, levels: nil)
        return unless object_instance_or_config

        levels ||= %i[warnings errors]
        begin
          option_configs = if object_instance_or_config.respond_to?(:option_configs)
                             object_instance = object_instance_or_config
                             object_instance_or_config.option_configs(raise_bad_configs: [FphsOptionsParseError,
                                                                                          FphsOptionsGeneralError,
                                                                                          FphsException])
                           else
                             object_instance_or_config
                           end
        rescue StandardError => e
          msg = if object_instance
                  "Error retrieving option_configs for #{object_instance.class.name}/#{object_instance.id}: #{e}"
                else
                  "Error retrieving option_configs: #{e}"
                end
          Rails.logger.error msg
          Rails.logger.error e.short_string_backtrace
          res = []
          bt = e.short_string_backtrace.presence || e.backtrace.join("\n")
          failed_config(nil, res, :parse_error, msg, 'YAML options', nil, extra_details: bt,
                                                                          level: :error)
          return res
        end

        res = []
        option_configs&.select do |oc|
          if levels.include?(:errors)
            val = oc.config_errors
            res += val if val
          end

          if levels.include?(:warnings)
            val = oc.config_warnings
            res += val if val
          end
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

    def failed_config(type, message, extra_details: nil, level: :error)
      target = if level == :error
                 config_errors
               elsif level == :warn
                 config_warnings
               else
                 config_errors
               end
      self.class.failed_config(self, target, type, message, name, resource_name, extra_details:, level:)
    end
  end
end
