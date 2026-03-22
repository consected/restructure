# frozen_string_literal: true

class SaveTriggers::CreateMaster < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @config = config
  end

  def perform
    config = @config
    vals = {}

    created_masters = @item.save_trigger_results['created_masters'] ||= []

    return created_masters unless if_evaluates(config[:if])

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

      @item.save_trigger_results['created_master'] =
        @new_master =
          Master.create_master_record @item.current_user, empty: true, extra_ids: vals

      @item.save_trigger_results['created_masters'] << @new_master

      if move_this
        new_master_id = @new_master.id

        @item.master = @new_master
        @item.update_columns(master_id: new_master_id)

        # Avoid embedded item treating this as though the item hasn't already been created,
        # which would fail
        @item.action_name = 'show'

        ei = @item.embedded_item
        if ei &&
           !(ei.class.respond_to?(:no_master_association) && ei.class.no_master_association) &&
           ei.respond_to?(:master_id) && ei.respond_to?(:master)
          ei.master = @new_master
          ei.update_columns(master_id: new_master_id)
          mr = @item.model_references.select do |mra|
            mra.to_record_type == ei.class.name && mra.to_record_id == ei.id
          end

          ModelReference.active.where(id: mr.map(&:id)).update_all(from_record_master_id: new_master_id,
                                                                   to_record_master_id: new_master_id)
        end

      end
    end

    created_masters
  end
end
