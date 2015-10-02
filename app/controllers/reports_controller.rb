class ReportsController < ApplicationController
  
  before_action :authenticate_user!

  def index
    
    @report_definition = {
      primary_table: 'tracker_history',
      sql: "select * from tracker_history th inner join masters m on m.id = th.master_id where event_date >= :event_date",
      attributes: {
        event_date: :date
      }      
    }

    sql = @report_definition[:sql]
    primary_table = @report_definition[:primary_table]
    
    attrib_values = params[:attributes]
    
    # get arbitrary data from a table
    res = ActiveRecord::Base.connection.execute(ActiveRecord::Base.send(:sanitize_sql, [sql, attrib_values], primary_table))
    
    #Get data cast correctly:
    logger.info "RES: #{res.inspect}"
    
    @results =  res #res.map {|row| row.map {|col,val| res.column_types[col].send(:type_cast, val) } }
    
    respond_to do |format|
      format.html
      format.csv { 
        res_a = []
        res.each {|row| res_a << row.collect {|col,val|  val}.to_csv }
        
        logger.info "RES A: #{res_a.inspect}"
        render text: res_a.join("")
      }
    end
    
  end
  
  private

    def secure_params
      params.require(:report).permit(:report_uid)
    end
end
