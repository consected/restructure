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
      category: ActivityLog.pluck(:category).uniq.compact,
      table_name: ActivityLog.active.pluck(:table_name).uniq
    }
  end

  def filters_on
    %i[category table_name]
  end

  private

  def permitted_params
    %i[name item_type rec_type process_name category action_when_attribute field_list blank_log_field_list
       disabled hide_item_list_panel extra_log_types main_log_name blank_log_name schema_name]
  end

  def index_params
    %i[name item_type rec_type process_name category schema_name action_when_attribute
       hide_item_list_panel]
  end
end
