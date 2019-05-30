class Admin::ActivityLogsController < AdminController

  protected
    def default_index_order
      {updated_at: :desc}
    end

  private
    def permitted_params
      [:name, :item_type, :rec_type, :process_name, :action_when_attribute, :field_list, :blank_log_field_list, :disabled, :blank_log_name, :hide_item_list_panel, :extra_log_types, :main_log_name]
    end
end
