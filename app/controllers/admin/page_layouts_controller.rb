class Admin::PageLayoutsController < AdminController

  protected
    def default_index_order
      "disabled asc nulls first, layout_name asc, panel_position asc"
    end

    def filters_on
      [:layout_name]
    end

    def filters
      { layout_name: Admin::PageLayout.active.pluck(:layout_name) }
    end

    def view_folder
      'admin/common_templates'
    end


  private
    def permitted_params
        [:app_type_id, :layout_name, :panel_name, :panel_label, :panel_position, :options, :disabled]
    end
end
