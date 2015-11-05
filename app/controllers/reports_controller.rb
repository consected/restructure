class ReportsController < ApplicationController
  include MasterSearch
  require 'csv'
  before_action :authenticate_user_or_admin!
  before_action :authorized?, only: [:index]
  after_action :clear_results, only: [:show, :run]
  after_action :do_log_action

  helper_method :filters, :filters_on, :index_path

  
  ResultsLimit = Master.results_limit
  
  # List of available reports
  def index    
    @no_create = true
    pm = Report.enabled    
    pm = pm.where filter_params if filter_params
    
    @reports = pm
    
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
    
    options = {}
    
    options[:count_only] = true if params[:commit] == 'count'
    
    return unless @report.searchable || authorized?
    
    if search_attrs
      begin        
        @results =  @report.run(search_attrs, options) 
      rescue ActiveRecord::PreparedStatementInvalid => e
        logger.info "Prepared statement invalid in reports_controller (#{search_attrs}) show: #{e.inspect}\n#{e.backtrace.join("\n")}"
        @results = nil
        flash.now[:danger] = "Generated SQL invalid.\n#{@report.clean_sql}\n#{e.to_s}"
        respond_to do |format|
          format.html {
            if params[:part] == 'results'
              render text: "Generated SQL invalid.\n#{@report.clean_sql}\n#{e.to_s}", status: 400
            else
              render :show
            end
          }
          format.json { return bad_request }
        end     
        return
      end
     
      if params[:commit] == 'search'
        run 'REPORT'
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
  
    def filters_on
      :report_type
    end
    
    def filters
      Report::ReportTypes.map {|g| [g,g.to_s.humanize]}.to_h
    end

  
    def filter_params
      return nil if params[:filter].blank?
      params.require(:filter).permit(filters_on)
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
    
    def authorized?
      return true if current_admin
      return true if current_user.can? :view_reports
      
      return not_authorized
    end
    
    def index_path p
      reports_path p
    end
    
    def do_log_action
      len = (@results ? @results.count : 0)
      extras = {}
      
      extras[:master_id] = nil
      extras[:msid] = nil
      
      log_action "#{controller_name}##{action_name}", "AUTO", len, "OK", extras
    end
  
end
