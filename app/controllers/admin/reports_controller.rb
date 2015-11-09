class Admin::ReportsController < ApplicationController

  require 'csv'
  include AdminControllerHandler

  protected
    def default_index_order
      { updated_at: :desc }
    end
  
    def filters_on
      :report_type
    end
    
    def filters
      Report::ReportTypes.map {|g| [g,g.to_s.humanize]}.to_h
    end


    def secure_params
      params.require(:report).permit(:id, :name, :primary_table, :sql, :description, :disabled, :report_type, :auto, :searchable, :position, :search_attrs)
    end

end
