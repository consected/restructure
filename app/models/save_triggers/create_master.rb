# frozen_string_literal: true

class SaveTriggers::CreateMaster < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    [
      {
        if: if_extras,
        force_create: 'true to force the creation of a reference and referenced object, independent of user access controls',
        move_this: 'true to move the current instance to the new master',
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
    ]
  end

  def initialize(config, item)
    super

    @config = config
  end

  def perform
    config = @config
    vals = {}

    if config[:if]
      ca = ConditionalActions.new config[:if], @item
      return unless ca.calc_action_if
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
      # force_create = config[:force_create]
      move_this = config[:move_this]

      @new_master = Master.create_master_record @item.current_user, empty: true, extra_ids: vals

      if move_this
        @item.force_save!
        @item.update!(master: @new_master)

        @item.embedded_item&.update!(master: @new_master)
      end
    end
  end
end
