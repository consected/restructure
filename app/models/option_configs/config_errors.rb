# frozen_string_literal: true

module OptionConfigs
  module ConfigErrors
    extend ActiveSupport::Concern

    def self.configuration_notice(config_obj:, type:, message:, name: nil, resource_name: nil,
                                  config_def: {}, extra_details: nil)
      config_resource_name = if config_obj && config_obj.class.respond_to?(:resource_name)
                               config_obj.class.resource_name
                             end
      {
        type:,
        config_class: config_obj&.class&.name,
        name:,
        message:,
        resource_name:,
        config_resource_name:,
        config_object: config_obj,
        config_def:,
        extra_details:
      }
    end

    def self.enrich_configuration_notice(notice, object_instance, configuration)
      resource_name = object_instance.resource_name if object_instance.respond_to?(:resource_name)
      configuration_notice(
        config_obj: object_instance,
        type: "_configurations > #{notice[:type]}",
        name: object_instance.respond_to?(:name) ? object_instance.name : object_instance.class.name,
        resource_name:,
        config_def: { '_configurations' => configuration.hash_configuration.deep_stringify_keys },
        message: notice[:message],
        extra_details: notice[:extra_details]
      )
    end

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
                        extra_details: nil, level: :error, config_obj: nil)
        config_obj ||= from_options&.config_obj
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

      def append_configuration_notices(notices, object_instance, configuration, levels)
        if levels.include?(:errors) && configuration.config_errors
          notices.concat(configuration.config_errors.map do |notice|
            OptionConfigs::ConfigErrors.enrich_configuration_notice(notice, object_instance, configuration)
          end)
        end
        if levels.include?(:warnings) && configuration.config_warnings
          notices.concat(configuration.config_warnings.map do |notice|
            OptionConfigs::ConfigErrors.enrich_configuration_notice(notice, object_instance, configuration)
          end)
        end

        notices
      end

      # OptionsHandler objects, such as page layouts, are object instances even when they have no option_configs
      # of their own. Their notices come from their configurations, the additional_configuration_notices hook,
      # and the condition linter (see ConditionLintNotices).
      # @return [Object, nil] the object instance, or nil when the argument is only a list of option configs
      def notice_object_instance(object_instance_or_config)
        return unless object_instance_or_config.is_a?(OptionsHandler) ||
                      object_instance_or_config.respond_to?(:option_configs)

        object_instance_or_config
      end

      # @return [Array, nil] the option configs of the object instance, or the argument when it is a list
      def notice_option_configs(object_instance, object_instance_or_config)
        if object_instance.nil?
          object_instance_or_config
        elsif object_instance.respond_to?(:option_configs)
          object_instance.option_configs(raise_bad_configs: [FphsOptionsParseError, FphsOptionsGeneralError,
                                                             FphsException])
        else
          []
        end
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
        object_instance = notice_object_instance(object_instance_or_config)
        begin
          option_configs = notice_option_configs(object_instance, object_instance_or_config)
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
          resource_name = object_instance.resource_name if object_instance.respond_to?(:resource_name)
          failed_config(nil, res, :parse_error, msg, 'YAML options', resource_name,
                        extra_details: bt, level: :error, config_obj: object_instance)
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

        if object_instance
          configuration = object_instance.configurations if object_instance.respond_to?(:configurations)
          res = append_configuration_notices(res, object_instance, configuration, levels) if configuration

          if object_instance.respond_to?(:additional_configuration_notices)
            val = object_instance.additional_configuration_notices(levels:)
            res += val if val
          end

          # Condition warnings are non-blocking, so they are only reported at the warnings level
          res += OptionConfigs::ConditionLintNotices.for(object_instance) if levels.include?(:warnings)
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
