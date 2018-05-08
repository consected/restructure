class Admin::ReportsController < AdminController


  protected
    def default_index_order
      "disabled asc nulls first, updated_at desc"
    end

    def filters_on
      [:item_type]
    end

    def filters
      { item_type: Report.categories.map {|g| [g,g.to_s.humanize]}.to_h }
    end

  private
    def permitted_params
      [:id, :name, :item_type, :primary_table, :sql, :description, :disabled, :report_type, :auto, :searchable, :position, :search_attrs, :edit_model, :edit_field_names, :selection_fields]
    end

end
