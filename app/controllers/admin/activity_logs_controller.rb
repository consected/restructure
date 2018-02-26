class Admin::ActivityLogsController < AdminController

  private
    def secure_params
      params.require(:activity_log).permit(:name, :item_type, :rec_type, :action_when_attribute, :field_list, :blank_log_field_list, :disabled, :blank_log_name, :hide_item_list_panel, :extra_log_types, :main_log_name)
    end
end
