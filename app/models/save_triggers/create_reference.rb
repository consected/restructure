class SaveTriggers::CreateReference < SaveTriggers::SaveTriggersBase

  def self.config_def if_extras: {}
    {
      if: if_extras,
      model_name: {
        in: "this | master",
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
  end

  def initialize config, item
    super

    @model_defs = config

  end

  def perform

    @model_defs.each do |model_name, config|

      vals = {}
      # # We have to calculate the conditional if inside each item, rather than relying
      # # on the outer processing in ExtraLogType#calc_save_trigger_if
      # if config[:if]
      #   ca = ConditionalActions.new config[:if], @item
      #   return unless ca.calc_action_if
      # end

      config[:with].each do |fn, def_val|

        if def_val.is_a? Hash
          ca = ConditionalActions.new def_val, @item
          res = ca.get_this_val
        else
          res = FieldDefaults.calculate_default @item, def_val
        end

        vals[fn] = res
      end

      new_item = @master.create_master_with_assoc(model_name.to_s.pluralize).create! vals

      if config[:in] == 'this'
        ModelReference.create_with @item, new_item
      elsif config[:in] == 'master'
        # ModelReference.create_from_master_with @master, new_item
      else
        raise FphsException.new "Unknown 'in' value in create_reference"
      end

    end

  end

end
