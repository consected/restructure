# frozen_string_literal: true

class Admin::PageLayoutsController < AdminController
  protected

  def default_index_order
    Arel.sql 'disabled asc nulls first, app_type_id asc, layout_name asc, panel_position asc'
  end

  def filters_on
    %i[layout_name app_type_id]
  end

  def filters
    {
      layout_name: Admin::PageLayout.active.pluck(:layout_name).uniq,
      app_type_id: Admin::AppType.all_by_name
    }
  end

  private

  def permitted_params
    %i[app_type_id layout_name panel_name panel_label panel_position description options disabled]
  end
end
