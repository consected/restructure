# frozen_string_literal: true

class SaveTriggers::UpdateReference < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    # [
    #   {
    #     model_name: {
    #       if: if_extras,
    #       first: 'update the first matching reference with this configuration, specifying {update: return_result}',
    #       force_not_editable_save: 'true allows the update to succeed even if the referenced item is set as not_editable',
    #       with: {
    #         field_name: 'now()',
    #         field_name_2: 'literal value',
    #         field_name_3: {
    #           this: 'field_name'
    #         },
    #         field_name_4: {
    #           reference_name: 'field_name'
    #         }
    #       }
    #     }
    #   }
    # ]
  end

  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @item.save_trigger_results['updated_items'] ||= []
    @item.save_trigger_results['updated_results'] ||= []

    @model_defs.each do |model_def|
      model_def.each_value do |config|
        with_entry_lifecycle(config) do
          vals = {}

          # We calculate the conditional if inside each item, rather than relying
          # on the outer processing in ActivityLogOptions#calc_save_trigger_if
          if config[:if]
            ca = ConditionalActions.new config[:if], @item
            unless ca.calc_action_if
              @item.save_trigger_results['updated_results'] << false
              next
            end
          end

          with_result = config[:with_result]
          update_with = config[:with]
          force_not_editable_save = config[:force_not_editable_save]
          force_not_valid = config[:force_not_valid]

          handle_with_result with_result, vals
          handle_with_attributes update_with, vals

          @item.transaction do
            ca = ConditionalActions.new config[:first], @item
            res = ca.get_this_val
            raise FphsException, "No reference found to update: #{config[:first]&.keys}" unless res

            res.ignore_configurable_valid_if = true if force_not_valid
            res.force_save! if force_not_editable_save
            res.update! vals.merge(current_user: @item.current_user || @item.user)

            ei_vals = vals[:embedded_item]
            res.update_embedded_item(ei_vals, force_not_editable_save:, force_not_valid:) if ei_vals

            @item.save_trigger_results['updated_items'] << res
            @item.save_trigger_results['updated_results'] << true
          end
        end
      end
    end
  end
end
