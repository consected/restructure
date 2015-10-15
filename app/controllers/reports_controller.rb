class ReportsController < ApplicationController

  require 'csv'
  before_action :authenticate_user_or_admin!
  after_action :clear_results, only: ['run']

  # List of available reports
  def index    
    pm = Report.enabled    
    pm = pm.where filter_params if filter_params
    
    @reports = pm.order(:id)
    
    respond_to do |format|      
      format.html { render :index }
      format.all { render json: @reports.as_json(except: [:created_at, :updated_at, :id, :admin_id, :user_id])}
    end
  end
  
  
  
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
        flash.now[:alert] = "Bad search criteria"
        respond_to do |format|
          format.html {
            if params[:part] == 'results'              
              render text: "bad search criteria", status: 400
            else
              render :show
            end
          }
        end     
        return
      rescue ActiveRecord::PreparedStatementInvalid => e
        logger.info "Prepared statement invalid in reports_controller (#{search_attrs}) show: #{e.inspect}\n#{e.backtrace.join("\n")}"
        @results = nil
        flash.now[:danger] = "Generated SQL invalid. #{e.to_s}"
        respond_to do |format|
          format.html {
            if params[:part] == 'results'
              render text: "Generated SQL invalid. #{e.to_s}", status: 400
            else
              render :show
            end
          }
          format.json { return bad_request }
        end     
        return
      end
     
    
      respond_to do |format|
        format.html {
          if params[:part] == 'results'
            render partial: 'results'
          else
            render :show
          end
        }
        format.json {
          render json: {results: @results, search_attributes: @report.search_attr_values}
        }
        format.csv { 
          res_a = []
          
          blank_value = nil
          if params[:csv_blank]
            blank_value = ""
          end          
          
          res_a << @results.fields.to_csv
          @results.each_row do |row| 
            res_a << (row.collect {|val|  val || blank_value}).to_csv
          end

     
          
          render text: res_a.join("")
        }
      end
    else
      respond_to do |format|
        format.html { 
          if params[:part] == 'form'
            render partial: 'form'
          else
            render :show
          end
        }        
      end     
    end
    
    
  end
  protected
  
    def filter_params
      nil
    end


    def secure_params
      params.require(:report).permit(:id,  :search_attrs)
    end
    
    def connection
      @connection ||= ActiveRecord::Base.connection
    end
    
  def clear_results
    # Needed to help control memory usage, according to PG:Result documentation
    @results.clear if @results
  end
    
end
