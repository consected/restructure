class Admin::ReportsController < ApplicationController

  include AdminControllerHandler

  protected
    def default_index_order
      { updated_at: :desc }
    end

    def filters_on
      :item_type
    end

    def filters
      Report.categories.map {|g| [g,g.to_s.humanize]}.to_h
    end


    def secure_params
      params.require(:report).permit(:id, :name, :item_type, :primary_table, :sql, :description, :disabled, :report_type, :auto, :searchable, :position, :search_attrs, :edit_model, :edit_field_names, :selection_fields)
    end

end
