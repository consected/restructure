# frozen_string_literal: true

class SaveTriggers::CreateReference < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    [
      {
        model_name: {
          if: if_extras,
          in: 'this | referring_record | master (creates no reference, just uses master_id) | master_with_reference (creates a reference to the master, not the item)',
          force_create: 'true to force the creation of a reference and referenced object, independent of user access controls',
          with: {
            field_name: 'now()',
            field_name_2: 'literal value',
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

  def initialize(config, item)
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

        config[:with]&.each do |fn, def_val|
          if def_val.is_a? Hash
            ca = ConditionalActions.new def_val, @item
            res = ca.get_this_val
          else
            res = FieldDefaults.calculate_default @item, def_val
          end

          vals[fn] = res
        end

        @item.transaction do
          force_create = config[:force_create]
          new_item = @master.assoc_named(model_name.to_s.pluralize).new vals
          new_item.force_save! if force_create
          new_item.save!

          if config[:in] == 'this'
            ModelReference.create_with @item, new_item, force_create: force_create
          elsif config[:in] == 'referring_record'
            ModelReference.create_with @item.referring_record, new_item, force_create: force_create
          elsif config[:in] == 'master'
            # ModelReference.create_from_master_with @master, new_item
          elsif config[:in] == 'master_with_reference'
            ModelReference.create_from_master_with @master, new_item, force_create: force_create
          else
            raise FphsException, "Unknown 'in' value in create_reference"
          end
        end
      end
    end
  end
end
