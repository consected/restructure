# frozen_string_literal: true

class SaveTriggers::UpdateThis < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    # [
    #   {
    #     this_1: {
    #       if: if_extras,
    #       first: 'update the current object. Note that any reference updates may not be reflected, so take care using referenced data',
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

    @model_defs = self.config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each_value do |config|
        with_entry_lifecycle(config) do
          vals = {}

          # We calculate the conditional if inside each item, rather than relying
          # on the outer processing in ActivityLogOptions#calc_save_trigger_if
          if config[:if]
            ca = ConditionalActions.new config[:if], @item
            next unless ca.calc_action_if
          end

          with_result = config[:with_result]
          update_with = config[:with]
          force_not_editable_save = config[:force_not_editable_save]
          force_not_valid = config[:force_not_valid]

          handle_with_result with_result, vals
          handle_with_attributes update_with, vals

          # Retain the flags so that the #update! doesn't change
          # what we need to report through the API
          res = @item
          created = res._created
          updated = res._updated
          disabled = res._disabled
          @item.transaction do
            res.ignore_configurable_valid_if = true if force_not_valid
            res.force_save! if force_not_editable_save
            new_vals = vals.merge(current_user: @item.current_user || @item.user, skip_save_trigger: true)
            res.update! new_vals

            ei_vals = vals[:embedded_item]
            res.update_embedded_item(ei_vals, force_not_editable_save:, force_not_valid:) if ei_vals
          end
          res._created = created
          res._updated = updated
          res._disabled = disabled
        end
      end
    end
  end
end
