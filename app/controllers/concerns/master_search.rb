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
          n = msid.length
          @masters = Master.where msid: msid
        elsif !params[:master][:pro_id].blank?
          proid = params[:master][:pro_id].to_s
          proid = proid.split(/[,| ]/) if proid.index(/[,| ]/)
          n = proid.length
          @masters = Master.where pro_id: proid
        elsif !params[:master][:id].blank?
          id = params[:master][:id].to_s
          id = id.split(/[,| ]/) if id.index(/[,| ]/)
          n = id.length
          @masters = Master.where id: id
        end
        @result_message = "Displaying results for a list of #{n} record #{'ID'.pluralize(n)}."

      elsif search_type == 'SIMPLE'
        @masters = Master.search_on_params search_params[:master]
      elsif search_type == 'REPORT'

        search_type = "REPORT: #{@report.name}"

        m_field = @report.field_index('master_id')

        unless m_field
          render text: "<b>query must return a master_id field to function as a search</b>".html_safe
          flash.now[:warning] = "query must return a master_id field to function as a search"
          return
        end

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
          masters: @masters.as_json,
          count: {
            count: original_length,
            show_count: @masters.length
          },
          search_action: search_type,
          message: @result_message
        }



      else
        # Return no results
        m = {message: "no conditions were specified", masters: [], count: {count: 0, show_count: 0} }
      end
    rescue => e
      logger.error "Error in MastersController#index: #{e.inspect}\n#{e.backtrace.join("\n")}"
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
          redirect_to(child_error_reporter_path)
          return
        end

        res = [(
                ma.map {|k,v| k} +
                (ma['player_infos'].first ||{}).map {|k,v| "player.#{k}"} +
                (ma['pro_infos'].first ||{}).map {|k,v| "pro.#{k}"}
                ).to_csv]

        m[:masters].each do |mae|
          res << (mae.map {|k,v| v.is_a?(Hash) || v.is_a?(Array) ? '' : v } +  
              (mae['player_infos'].first || {}).map {|k,v| v} +
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
