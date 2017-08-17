module MasterSearch
  extend ActiveSupport::Concern

  included do

  end
  
  def run search_type
    msid = nil
    begin

      if search_type == 'MSID'
        if !params[:master][:msid].blank?
          msid = params[:master][:msid].to_s 
          msid = msid.split(/[,| ]/) if msid.index(/[,| ]/)        
          @masters = Master.where msid: msid
        elsif !params[:master][:pro_id].blank?
          proid = params[:master][:pro_id].to_s
          proid = proid.split(/[,| ]/) if proid.index(/[,| ]/)        
          @masters = Master.where pro_id: proid
        elsif !params[:master][:id].blank?
          id = params[:master][:id].to_s 
          id = id.split(/[,| ]/) if id.index(/[,| ]/)        
          @masters = Master.where id: id
        end
      elsif search_type == 'SIMPLE'
        @masters = Master.search_on_params search_params[:master]
      elsif search_type == 'REPORT'
        
        search_type = "REPORT: #{@report.name}"
        
        m_field = @report.field_index('master_id')
        
        render text: "query must return a master_id field to function as a search" and return  unless m_field
        
        ids = []
        @results.each_row {|r| ids << r[m_field]}
        
        #If the msid is an array of items then return the results in the order of the list
        
        @masters = Master.where "id in(?)", ids
        
        
        
        
      else
        @masters = Master.search_on_params search_params[:master]
      end
    
      if @masters

        #If the msid is an array of items then return the results in the order of the list
        if msid.is_a? Array
          i = 0
          #@masters = @masters.take(ResultsLimit)
          msid.each do |d|
            m1 = @masters.select {|n| n.msid.to_s == d}.first
            m1.force_order = i if m1
            i += 1
          end

          @masters = @masters.sort {|m,n| m.force_order <=> n.force_order}              
        end
        
        original_length = @masters.length
        @masters = @masters[0, return_results_limit]
        
        m = {
          masters: @masters.as_json(include: {
            player_infos: {order: Master::PlayerInfoRankOrderClause, 
              include: {              
                item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
              },
              methods: [:user_name, :accuracy_score_name, :rank_name, :source_name]
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
            }
#            scantrons: {
#              order: {scantron_id: :asc},
#              methods: [:user_name]
#            },
#            sage_assignments: {
#              order: {sage_id: :asc},
#              methods: [:user_name]
#            }
          }) 
        }

        m[:count] = {count: original_length,  show_count: @masters.length}

        log_action "master search", search_type, @masters.length
      else
        # Return no results      
        m = {message: "no conditions were specified", masters: [], count: {count: 0, show_count: 0} }
        log_action "master search", search_type, 0, "no conditions specified"
      end
    rescue => e
      logger.error "Error in MastersController#index: #{e.inspect}"
      m = {error: ": unable to search - please check your search criteria."}
      render json: m, status: 400
      return
    end

    respond_to do |format|
      format.json {
        # This is standard, not an export
        render json: m        
      }
      format.csv {
        
        return not_authorized unless current_user.can? :export_csv
        
        ma = m[:masters].first 
        
        #return bad_request unless ma
        unless ma
          flash[:warning] = "no results to export"
          redirect_to("/masters/") 
          return 
        end
        
        res = [(ma.map {|k,v| k} + (ma['player_infos'].first ||{}).map {|k,v| "player.#{k}"} +
              (ma['pro_infos'].first ||{}).map {|k,v| "pro.#{k}"}).to_csv]
        
        m[:masters].each do |mae|
          res << (mae.map {|k,v| v.is_a?(Hash) || v.is_a?(Array) ? '' : v }   +  (mae['player_infos'].first || {}).map {|k,v| v} +
              (mae['pro_infos'].first || {}).map {|k,v| v}).to_csv
        end
        
        send_data res.join(""), filename: "report.csv"
        
      }
    end
  end
  
  
  private
    def return_results_limit
      e = 0
      r = params[:res_limit]
      e = r.to_i unless r.blank?    
      e = 100 if e == 0
      @return_results_limit = e

    end
  
end