# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionImplementers
    #
    # Implement save triggers, as defined in extra options
    module SaveTriggers
      extend ActiveSupport::Concern

      ValidSaveTriggers = %i[notify
                             create_reference
                             create_master
                             update_reference
                             create_filestore_container
                             update_this
                             add_tracker
                             change_user_roles
                             pull_external_data
                             set_item_flags
                             redcap_request
                             run_batch_trigger
                             log
                             transaction
                             background
                             reload_this
                             case].freeze

      class_methods do
        #
        # Handle the processing of triggers for an item,
        # based on the supplied configurations
        # @param [UserBase] obj - the item the action was triggered by (or for)
        # @param [Hash] configs - defining the trigger to be processed
        # @return [<Type>] <description>
        def calc_triggers(obj, configs)
          return if configs.nil?

          # Get a list of results from the triggers
          results = configs.map do |perform, config|
            o = trigger_class(perform).new(config, obj)
            # Add the trigger result to the list
            o.perform
          end

          # If we had any results then check if they were all true. If they were then return true.
          # Otherwise don't
          unless results.empty?
            return true if results.uniq.length == 1 && results.uniq.first

            return nil
          end

          # No results - return true
          true
        end

        #
        # Validate name
        # Use the symbol from the list of valid items, to prevent manipulation that could cause Brakeman warnings
        # @param [Symbol] name
        # @return [<Type>] <description>
        def valid_save_trigger_named(name)
          trigger = ValidSaveTriggers.select { |vt| vt == name }.first
          raise FphsException, "Configuration is not valid when attempting to perform #{name}" unless trigger

          trigger
        end

        #
        # Return the named SaveTriggers::* class
        # @return [SaveTriggersBase]
        def trigger_class(trigger_name)
          trigger_name = valid_save_trigger_named(trigger_name)
          ::SaveTriggers.const_get(trigger_name.to_s.camelize)
        end
      end

      def calc_save_trigger_if(obj, alt_on: nil)
        if alt_on == :before_save
          action = :before_save
        elsif alt_on == :upload
          action = :on_upload
        elsif obj._created
          action = :on_create
        elsif obj._disabled
          action = :on_disable
        elsif obj._updated
          action = :on_update
        else
          # Neither create or update - so just return
          return true
        end

        iterate_triggers_for_action(obj, save_trigger, action)
      end

      def calc_batch_trigger(obj)
        action = :on_record
        iterate_triggers_for_action(obj, batch_trigger, action)
      end

      private

      def iterate_triggers_for_action(obj, trigger, action)
        res = true
        # Only run through configs that were returned in the save_options for this action
        all_configs = trigger[action]
        all_configs = [all_configs] unless all_configs.is_a? Array
        all_configs.each do |configs|
          next unless configs

          iter_configs = configs[:each] || { do: configs }
          # Assuming this is an each: definition, get an if: config
          do_if = configs.dig(:each, :if)

          val_configs = iter_configs[:value]
          iter_values = if val_configs
                          FieldDefaults.calculate_default obj, val_configs
                        else
                          [nil]
                        end

          raise FphsException, "No iterator values were found for save trigger each: #{iter_configs}" unless iter_values

          iter_values.each_with_index do |iter_value, iter_index|
            obj.save_trigger_results['iterator_index'] = iter_index
            obj.save_trigger_results['iterator_value'] = iter_value

            # Provide the ability to skip all triggers for this iteration
            if do_if
              ca = ConditionalActions.new do_if, obj
              next unless ca.calc_action_if
            end

            all_iter_configs = iter_configs[:do]
            all_iter_configs = [all_iter_configs] unless all_iter_configs.is_a? Array
            all_iter_configs.each do |iter_config|
              result = calc_triggers_for_action(obj, action, iter_config)
              res &&= result
            end
          end
        end

        res
      end

      def calc_triggers_for_action(obj, action, configs)
        sub_trigger = { action => configs }
        ca = ConditionalActions.new sub_trigger, obj
        save_options = ca.calc_save_option_if

        return unless save_options.is_a?(Hash) && save_options[action]

        configs = configs.slice(*save_options[action].keys)
        self.class.calc_triggers(obj, configs)
      end
    end
  end
end
