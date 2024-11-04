# Handle option type configurations for a dynamic class implementation
module Dynamic
  module ImplementationHandler
    extend ActiveSupport::Concern

    included do
      after_initialize :preset_fields, unless: :persisted?
      after_initialize :force_preset_values, unless: :persisted?

      before_save :handle_before_save_triggers
      after_commit :handle_save_triggers
      after_commit :reset_access_evaluations!

      # skip_save_trigger: Prevent save triggers from running
      # save_trigger_results: Results from stored locally by save triggers
      attr_accessor :skip_save_trigger, :save_trigger_results, :current_admin_sample
    end

    class_methods do
      #
      # Run batch processing as a job, triggering actions before on the existence of each record
      # @param [Integer|nil] limit - optional limit to the number of records to process,
      #                              overriding the configuration if set
      # @param [User|nil] alt_user - alternative user to use, rather than the user defined by each record
      # @param [Admin::AppType|nil] alt_app_type - force user to use app type,
      #                                            rather than current app type set in the record
      def trigger_batch(limit: nil, alt_user: nil, alt_app_type: nil)
        Rails.logger.info "trigger batch job for #{self} - " \
                          "limit: #{limit}, alt_user: #{alt_user}, alt_app_type: #{alt_app_type}"
        HandleBatchJob.perform_later(to_s, limit:, user: alt_user, app_type: alt_app_type)
      end

      #
      # Run batch processing, triggering actions before on the existence of each record
      # @param [Integer|nil] limit - optional limit to the number of records to process, overriding the configuration if set
      # @param [User|nil] alt_user - alternative user to use, rather than the user defined by each record
      def trigger_batch_now(limit: nil, alt_user: nil)
        definition.reload
        definition.option_configs force: true
        limit ||= definition.configurations&.dig(:batch_trigger, :limit)
        cond = definition.configurations&.dig(:batch_trigger, :if)
        Rails.logger.info "trigger batch now for #{self} - limit: #{limit}, alt_user: #{alt_user}, if: #{cond}"
        batch = all

        if cond
          new_batch = []
          batch.each do |obj|
            obj.current_user = alt_user if alt_user
            ca = ConditionalActions.new cond, obj
            new_batch << obj if ca.calc_action_if

            # Within an if condition, we limit based on number of items meeting the condition
            break if limit && new_batch.length >= limit
          end

          batch = new_batch
        elsif limit
          # When there is no if condition, purely limit the query directly
          batch = batch.limit(limit)
        end

        batch.map do |obj|
          obj.handle_record_batch_trigger(alt_user:)
          obj.id
        end
      end
    end

    #
    # List field names that explicitly state *no_downcase: true* or
    # edit_as: field_type: includes the string 'notes'
    # @return [Array{Symbol}]
    def no_downcase_attributes
      fo = option_type_config&.field_options || {}
      res = fo&.filter { |_k, v| v[:no_downcase] || v[:edit_as] && v[:edit_as][:field_type]&.include?('notes') }

      res&.keys
    end

    # Provide a default human message identifying a record
    # If the extra log type config for an activity includes
    #
    #   view_options:
    #     data_attribute: some text {{substitution}}
    #
    # or
    #   view_options:
    #     data_attribute: attrib_name
    #
    # then appropriate substitutions will be made
    #
    # If a list is provided to data_attribute, such as
    #
    # - attr1
    # - ": "
    # - attr2
    #
    # then the attribute names that can be substituted will be and the
    # result of all items will be joined into a single string
    #
    # If no data_attribute configuration is provided then the first of the following is used:
    # - if there is a data attribute, use its value
    # - if a label is specified in the config, use it
    # - otherwise the extra_log_type value is humanized and used
    #
    def data
      dopt = option_type_config
      return unless dopt&.view_options

      da = data_attribute_name

      if da
        @processing_data = true
        res = Formatter::Formatters.format_data_attribute da, self, ignore_missing: :show_tag
        @processing_data = false
        return res
      end

      res = if attribute_names.include? 'data'
              attributes['data']
            else
              dopt&.label || option_type.to_s.humanize
            end
      res.to_s
    end

    #
    # Return the data_attribute as defined in the options, or nil if there is nothing defined
    # @return [String | nil]
    def data_attribute_name
      dopt = option_type_config
      return unless dopt&.view_options

      # Prevent recursion in the creation of the data attribute with substitution
      return if @processing_data

      dopt.view_options[:data_attribute]
    end

    # @return [Boolean | nil] returns true or false based on the result of a conditional calculation,
    #    or nil if there is no `add_reference_if` configuration
    def can_add_reference?
      return @can_add_reference unless @can_add_reference.nil?

      @can_add_reference = false
      dopt = option_type_config
      return unless dopt

      return unless dopt.add_reference_if.is_a?(Hash) && dopt.add_reference_if.first

      res = dopt.calc_if(:add_reference_if, self)
      @can_add_reference = !!res
    end

    # Calculate the can rules for the required type, based on user access controls and showable_if rules
    # Returns true or false if the appropriate showable_if or editable_if rule is defined, or
    # nil if the rule is not defined
    # @param type [Symbol] either :access or :edit for showable_if or editable_if
    # @return [Boolean | nil]
    def calc_can(type)
      dopt = option_type_config
      return unless dopt

      case type
      when :edit
        doptif = dopt.editable_if
      when :access
        doptif = dopt.showable_if
      else
        return
      end

      return unless doptif.is_a?(Hash) && doptif.first && respond_to?(:master)

      # Generate an old version of the object prior to changes
      old_obj = dup
      changes.each do |k, v|
        old_obj.send("#{k}=", v.first) if k.to_s != 'user_id'
      end

      # Set the id, since dup doesn't do this and we may need it
      old_obj.id = id

      # Ensure the duplicate old_obj references the real master, ensuring current user can
      # be referenced correctly in conditional calculations
      old_obj.master = master

      case type
      when :edit
        res = !!dopt.calc_if(:editable_if, old_obj)
      when :access
        res = !!dopt.calc_if(:showable_if, old_obj)
      end

      res
    end

    # If access has changed since an initial check, reset the cached results
    def reset_access_evaluations!
      @can_access = nil
      @can_create = nil
      @can_add_reference = nil
      @can_edit = nil
    end

    #
    # Handle on save save triggers
    def handle_save_triggers
      self.save_trigger_results ||= {}
      option_type_config&.calc_save_trigger_if self unless skip_save_trigger
      true
    end

    #
    # Handle actions that must be performed before on save save triggers
    def handle_before_save_triggers
      self.save_trigger_results ||= {}
      option_type_config&.calc_save_trigger_if self, alt_on: :before_save unless skip_save_trigger
      true
    end

    #
    # Handle batch_trigger action for this record
    # @param [User] alt_user - use a specific user to run the action
    def handle_record_batch_trigger(alt_user: nil)
      as_user = alt_user || user
      self.current_user = as_user
      self.save_trigger_results ||= {}
      option_type_config&.calc_batch_trigger self
    end

    def skip_presets_for(method_name)
      return skip_presets unless skip_presets.is_a?(String)

      skip_presets.split(',').include?(method_name.to_s)
    end

    def preset_fields
      return if skip_presets_for(:preset_fields) || !current_user

      config = option_type_config&.preset_fields
      return unless config&.present?

      st = SaveTriggers::PresetFields.new(config, self)
      st.perform
    end

    #
    # Force fields to be preset before initialization has been completed.
    # This uses the option config {field_options: <field_name>: preset_value:}
    # rather than default: (which only sets the value in the initial form).
    # preset_value: sets the value regardless of what was previously set, so will override values in #create! methods
    # blank_preset_value: only sets the value if it was previously blank, so won't override values in #create! methods
    # By setting ahead of time, things like embed_resource_name can operate.
    def force_preset_values
      return if skip_presets_for(:force_preset_values)

      fo = option_type_config&.field_options
      return unless fo

      fo.each do |name, config|
        next unless config.key?(:preset_value) || config.key?(:blank_preset_value)

        next unless attribute_names.include?(name.to_s)

        init_value = config[:preset_value]
        if init_value
          res = FieldDefaults.calculate_default self, init_value, ignore_missing: current_admin_sample
          send "#{name}=", res
        end

        init_value = config[:blank_preset_value]
        if init_value
          res = FieldDefaults.calculate_default self, init_value, ignore_missing: current_admin_sample
          send "#{name}=", res if attributes[name.to_s].blank?
        end
      end
    end
  end
end
