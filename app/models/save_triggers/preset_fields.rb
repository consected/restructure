# frozen_string_literal: true

class SaveTriggers::PresetFields < SaveTriggers::SaveTriggersBase
  # def self.config_def(if_extras: {})
  # end

  def perform
    vals = {}

    nil unless config&.present?

    preset_if = config[:if]
    preset_with = config[:with]
    with_result = config[:with_result]

    if preset_if
      ca = ConditionalActions.new preset_if, @item
      return unless ca.calc_action_if
    end

    handle_with_result with_result, vals
    handle_with_attributes preset_with, vals

    ei = vals[:embedded_item]
    if ei
      @item.prep_embedded_item(ei,
                               force_create: @item.force_save?,
                               force_not_valid: @item.ignore_configurable_valid_if)

      @item.embedded_item&.assign_attributes(ei)
    end

    @item.assign_attributes(vals)
  end
end
