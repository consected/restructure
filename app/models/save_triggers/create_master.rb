# frozen_string_literal: true

class SaveTriggers::CreateMaster < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    # [
    #   {
    #     if: if_extras,
    #     force_create: 'true to force the creation of a reference and referenced object, independent of user access controls',
    #     move_this: 'true to move the current instance to the new master',
    #     with: {
    #       field_name: 'now()',
    #       field_name_2: 'literal value',
    #       field_name_3: {
    #         this: 'field_name'
    #       },
    #       field_name_4: {
    #         reference_name: 'field_name'
    #       }
    #     }
    #   }
    # ]
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
        new_master_id = @new_master.id

        @item.master = @new_master
        @item.update_columns(master_id: new_master_id)

        # Avoid embedded item treating this as though the item hasn't already been created,
        # which would fail
        @item.action_name = 'show'

        ei = @item.embedded_item
        if ei
          ei.master = @new_master
          ei.update_columns(master_id: new_master_id)
          mr = @item.model_references.first do |mra|
            mra.to_record_type == ei.class.name && mra.to_record_id == ei.id
          end

          mr.update_columns(from_record_master_id: new_master_id, to_record_master_id: new_master_id)
        end

      end
    end
  end
end
