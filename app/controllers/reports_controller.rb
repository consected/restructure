class ReportsController < ApplicationController
  
  include AdminControllerHandler

  def show
    
    @results =  Report.run(params[:id], params[:search_attrs])
     #res.map {|row| row.map {|col,val| res.column_types[col].send(:type_cast, val) } }
    
    respond_to do |format|
      format.html
      format.csv { 
        res_a = []
        res.each {|row| res_a << row.collect {|col,val|  val}.to_csv }
        
        render text: res_a.join("")
      }
    end
    
  end
  
  private

    def secure_params
      params.require(:report).permit(:id, :name, :primary_table, :sql, :description, :disabled, :search_attrs)
    end
    
    def connection
      @connection ||= ActiveRecord::Base.connection
    end
end
