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

    @model_defs.each do |model_def|
      model_def.each do |_model_name, config|
        vals = {}

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        config[:with].each do |fn, def_val|
          if def_val.is_a? Hash
            ca = ConditionalActions.new def_val, @item
            res = ca.get_this_val
          else
            res = FieldDefaults.calculate_default @item, def_val
          end

          vals[fn] = res
        end

        @item.transaction do
          ca = ConditionalActions.new config[:first], @item
          res = ca.get_this_val
          raise FphsException, "No reference found to update: #{config[:first]&.keys&.first}" unless res

          res.ignore_configurable_valid_if = true if config[:force_not_valid]
          res.force_save! if config[:force_not_editable_save]
          res.update! vals.merge(current_user: @item.current_user || @item.user)
        end
      end
    end
  end
end
