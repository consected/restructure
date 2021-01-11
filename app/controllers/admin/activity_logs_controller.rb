# frozen_string_literal: true

class Admin::ActivityLogsController < AdminController
  after_action :routes_reload, only: %i[update create]

  protected

  def routes_reload
    DynamicModel.routes_reload
  end

  def default_index_order
    { updated_at: :desc }
  end

  def filters
    {
      category: ActivityLog.pluck(:category).uniq.compact
    }
  end

  def filters_on
    [:category]
  end

  private

  def permitted_params
    %i[name item_type rec_type process_name category action_when_attribute field_list blank_log_field_list
       disabled blank log_name hide_item_list_panel extra_log_types main_log_name blank_log_name schema_name]
  end
end
