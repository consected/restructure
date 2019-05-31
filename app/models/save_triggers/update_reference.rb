class SaveTriggers::UpdateReference < SaveTriggers::SaveTriggersBase

  def self.config_def if_extras: {}
    [
      {
        model_name: {
          if: if_extras,
          first: "matching reference, specifying {update: return_result}",
          with: {
            field_name: "now()",
            field_name_2: "literal value",
            field_name_3: {
              this: 'field_name'
            },
            field_name_4: {
              reference_name: 'field_name'
            }
          }
        }
      }
    ]
  end

  def initialize config, item
    super

    @model_defs = config

  end

  def perform


    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each do |model_name, config|

        vals = {}

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ExtraLogType#calc_save_trigger_if
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
          # new_item = @master.assoc_named(model_name.to_s.pluralize).first

          ca = ConditionalActions.new config[:first], @item
          res = ca.get_this_val

          res.update! vals.merge(current_user: @item.user)
        end

      end

    end

  end

end
