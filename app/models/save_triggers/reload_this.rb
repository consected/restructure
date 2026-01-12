# frozen_string_literal: true

#
# Save trigger that reloads the current item from the database.
# This is useful when working with views or after create_reference triggers
# where subsequent triggers need to see updated data in `this.attribute`
# conditions or `{{attribute}}` substitutions.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       - update_reference:
#           - pi:
#               first:
#                 player_infos:
#                   last_name: new name
#       - reload_this:
#           if:
#             always: true
#       - update_reference:
#           - pi:
#               first:
#                 player_infos:
#                   last_name: 'updated - {{last_name}}'
#
# Without reload_this, {{last_name}} would show the original value.
# With reload_this, {{last_name}} shows 'new name' after the first update.
#
class SaveTriggers::ReloadThis < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @this_config = config || {}
  end

  def perform
    # Check conditional if specified
    if @this_config[:if]
      ca = ConditionalActions.new @this_config[:if], @item
      return unless ca.calc_action_if
    end

    Rails.logger.info "[SaveTrigger::ReloadThis] Reloading #{@item.class.name}##{@item.id}"

    # Store attributes that should be preserved across reload
    current_user = @item.current_user
    if @item.respond_to?(:save_trigger_results) && @item.save_trigger_results
      save_trigger_results = @item.save_trigger_results.dup
    end

    # Reload the item from the database
    @item.reload

    # Restore preserved attributes
    @item.current_user = current_user
    if @item.respond_to?(:save_trigger_results=) && save_trigger_results
      @item.save_trigger_results = save_trigger_results
    end

    result = {
      status: 'reloaded',
      item_class: @item.class.name,
      item_id: @item.id,
      reloaded_at: Time.current
    }

    # Store result for potential use by subsequent triggers
    if @item.respond_to?(:save_trigger_results) && @item.save_trigger_results
      @item.save_trigger_results['reload_this'] = result
    end

    result
  end
end
