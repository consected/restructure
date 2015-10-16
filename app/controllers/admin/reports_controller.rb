class Admin::ReportsController < ApplicationController

  require 'csv'
  include AdminControllerHandler

  protected



    def secure_params
      params.require(:report).permit(:id, :name, :primary_table, :sql, :description, :disabled, :report_type, :auto, :searchable, :position, :search_attrs)
    end

    def connection
      @connection ||= ActiveRecord::Base.connection
    end
end
