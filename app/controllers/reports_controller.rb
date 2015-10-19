class ReportsController < ApplicationController
  include MasterSearch
  require 'csv'
  before_action :authenticate_user_or_admin!
  after_action :clear_results, only: ['run']

  ResultsLimit = Master.results_limit
  
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
  
  
  def show3
    
    logger.info "Trying show2 with #{@results}"
    begin
      return_results_limit = 100
    
      if @results
        search_type = @report.name
        
        m_field = nil
        
        i = 0
        @results.fields.each do |f|           
          if f == 'master_id'
            m_field = i  
            break
          end
          i+=1          
        end  
        
        render text: "query must return a master_id field to function as a search" and return  unless m_field
        
        ids = []
        @results.each_row {|r| ids << r[m_field]}
        
        #If the msid is an array of items then return the results in the order of the list
        
        @masters = Master.where "id in(?)", ids
        
        
        original_length = @masters.length
        @masters = @masters[0, return_results_limit]
        
        m = {
          masters: @masters.as_json(include: {
            player_infos: {order: Master::PlayerInfoRankOrderClause, 
              include: {              
                item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
              },
              methods: [:user_name, :accuracy_score_name, :source_name]
            },
            pro_infos: {}, 
            player_contacts: {
              order: {rank: :desc},             
              methods: [:user_name, :rank_name, :source_name]
            },
            addresses: {
              order: {rank: :desc},             
              methods: [:user_name, :rank_name, :state_name, :country_name, :source_name]
            },
#           Loading trackers dynamically provides a significant speed up, and this may become more important as the tracker usage grows
#           trackers: {
#              order: "protocol.position #{Master::TrackerEventOrderClause}",                
#              methods: [:protocol_name, :protocol_position, :sub_process_name, :event_name, :tracker_history_length, :user_name, :record_type_us, :record_type, :record_id]
#            },

            latest_tracker_history: {            
              methods: [:protocol_name, :protocol_position, :sub_process_name, :event_name, :user_name, :record_type_us, :record_type, :record_id, :event_description, :event_milestone]
            },
            scantrons: {
              order: {scantron_id: :asc},
              methods: [:user_name]
            }
          }) 
        }

        m[:count] = original_length
        m[:show_count] = @masters.length

        log_action "master search", search_type, @masters.length
      else
        # Return no results      
        m = {message: "no conditions were specified", masters: [], count: 0}
        log_action "master search", search_type, 0, "no conditions specified"
      end
    rescue => e
      logger.error "Error in MastersController#index: #{e.inspect}.}"
      m = {error: ": unable to search - please check your search criteria"}
      render json: m, status: 400
      return
    end

    respond_to do |format|
      format.json {render json: m}
      format.csv {
        ma = m[:masters].first 
        
        return bad_request unless ma
        
        res = [(ma.map {|k,v| k} + (ma['player_infos'].first ||{}).map {|k,v| "player.#{k}"} +
              (ma['pro_infos'].first ||{}).map {|k,v| "pro.#{k}"}).to_csv]
        
        m[:masters].each do |ma| 
          res << (ma.map {|k,v| v.is_a?(Hash) || v.is_a?(Array) ? '' : v }   +  (ma['player_infos'].first || {}).map {|k,v| v} +
              (ma['pro_infos'].first || {}).map {|k,v| v}).to_csv 
        end
        
        render text: res.join("") 
        
      }
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
