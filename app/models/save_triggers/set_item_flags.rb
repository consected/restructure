# frozen_string_literal: true

class SaveTriggers::SetItemFlags < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    # [
    #   {
    #       if: if_extras,
    #       first: 'set flags on the first matching reference with this configuration, specifying {update: return_result}',
    #       force_not_editable_save: 'true allows the update to succeed even if the referenced item is set as not_editable',
    #       flags: 'list of flag name ids or names'
    #   }
    # ]
  end

  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |config|
      with_entry_lifecycle(config) do
        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        unless config[:flags] || config[:add_flags] || config[:remove_flags]
          raise FphsException, 'Must use one option of flags, add_flags or remove_flags'
        end

        flag_list = config[:flags]&.map { |def_val| calculate_flag(def_val) }
        add_flag_list = config[:add_flags]&.map { |def_val| calculate_flag(def_val) }
        remove_flag_list = config[:remove_flags]&.map { |def_val| calculate_flag(def_val) }

        @item.transaction do
          ca = ConditionalActions.new config[:first], @item
          ref_obj = ca.get_this_val
          raise FphsException, "No reference found to set flags on: #{config[:first]&.keys}" unless ref_obj

          # Convert flag names to ids
          flag_list = if flag_list
                        make_flag_list_ids(ref_obj, flag_list)
                      else
                        # If no flag_list is specified, use the existing set to add and remove from
                        ref_obj.item_flags.map(&:item_flag_name_id).uniq
                      end

          if add_flag_list
            add_flag_list = make_flag_list_ids(ref_obj, add_flag_list)
            flag_list += add_flag_list
          end

          if remove_flag_list
            remove_flag_list = make_flag_list_ids(ref_obj, remove_flag_list)
            flag_list -= remove_flag_list
          end

          curr_user = @item.current_user || @item.user
          ref_obj.current_user = curr_user
          fs = config[:force_not_editable_save]
          ref_obj.force_save! if fs
          ItemFlag.set_flags flag_list, ref_obj, curr_user, force_save: fs
        end
      end
    end
  end

  private

  def calculate_flag(def_val)
    if def_val.is_a? Hash
      ca = ConditionalActions.new def_val, @item
      ca.get_this_val
    else
      FieldDefaults.calculate_default @item, def_val
    end
  end

  def make_flag_list_ids(ref_obj, flag_list)
    return unless flag_list

    if flag_list.first.is_a? String
      Classification::ItemFlagName.available_to_item(ref_obj).where(name: flag_list).ids
    else
      flag_list
    end
  end
end
