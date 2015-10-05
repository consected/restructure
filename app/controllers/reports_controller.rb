class ReportsController < ApplicationController

  require 'csv'
  include AdminControllerHandler

  def show
    
    id = (params[:id] || 0).to_i
    
    redirect_to :index unless id > 0
    
    search_attrs = params[:search_attrs]
    @report = Report.find(id)
    
    if search_attrs
      begin
        @results =  @report.run(search_attrs) 
      rescue Report::BadSearchCriteria
        @results = nil
        flash[:warning] = "Bad search criteria"
        respond_to do |format|
          format.html
        end     
        return
      end
     
    
      #res.map {|row| row.map {|col,val| res.column_types[col].send(:type_cast, val) } }
    
      respond_to do |format|
        format.html
        format.json {
          render json: @results
        }
        format.csv { 
          res_a = []
          
          blank_value = nil
          if params[:csv_blank]
            blank_value = ""
          end
          
          @results.each do |row| 
            res_a << (row.collect {|col,val|  val || blank_value}).to_csv
          end

     
          
          render text: res_a.join("")
        }
      end
    else
      respond_to do |format|
        format.html
      end     
    end
    
    
  end
  protected
  
  

    def secure_params
      params.require(:report).permit(:id, :name, :primary_table, :sql, :description, :disabled, :search_attrs)
    end
    
    def connection
      @connection ||= ActiveRecord::Base.connection
    end
end
