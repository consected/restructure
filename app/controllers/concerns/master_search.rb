module MasterSearch

  extend ActiveSupport::Concern

  included do

  end

  def run search_type
    msid = nil
    begin

      # Search a single or list of items by master id, MSID or pro_id,
      # typically from the URL or nav bar search form
      if search_type == 'MSID'
        if !params[:master][:msid].blank?
          msid = params[:master][:msid].to_s
          if msid.index(/[,| ]/)
            msid = msid.split(/[,| ]/)
            sort_by_ids = msid.map(&:to_i).uniq
          end
          n = msid.length
          @masters = Master.where msid: msid
        elsif !params[:master][:pro_id].blank?
          proid = params[:master][:pro_id].to_s
          if proid.index(/[,| ]/)
            proid = proid.split(/[,| ]/)
            sort_by_ids = pro_id.map(&:to_i).uniq
          end
          n = proid.length
          @masters = Master.where pro_id: proid
        elsif !params[:master][:id].blank?
          id = params[:master][:id].to_s
          if id.index(/[,| ]/)
            id = id.split(/[,| ]/)
            sort_by_ids = id.map(&:to_i).uniq
          end
          n = id.length
          @masters = Master.where(id: id)
        end

      elsif search_type == 'SIMPLE'
        @masters = Master.search_on_params(search_params[:master])
        @masters = @masters.limit(return_results_limit) if @masters
      elsif search_type == 'REPORT'

        search_type = "REPORT: #{@report.name}"

        m_field = @report.field_index('master_id')

        unless m_field
          render text: "<b>query must return a master_id field to function as a search</b>".html_safe
          flash.now[:warning] = "query must return a master_id field to function as a search"
          @no_masters = true
          return
        end

        ids = []
        @results.each_row {|r| ids << r[m_field].to_i}

        #If the msid is an array of items then return the results in the order of the list

        @masters = Master.where(id: ids)

        sort_by_ids = ids


      else
        @masters = Master.search_on_params(search_params[:master])
        @masters = @masters.limit(return_results_limit) if @masters
      end

      if @masters

        @masters = @masters.external_identifier_assignment_scope(current_user)


        # If a list of IDs to sort by is provided (from a report search), sort by it
        if sort_by_ids
          @masters = @masters.sort_by {|m| sort_by_ids.index(m.id)}
        end


        @masters.uniq!
        original_length = @masters.length
        @masters = @masters[0, return_results_limit]

        logger.debug "Masters should return #{@masters.length} items"

        mlen = @masters.length

        if search_type == 'MSID' && mlen > 0 && @masters.first.id >= 0
          @result_message = "Displaying results for a list of #{mlen} record #{'ID'.pluralize(mlen)}."
        end

        # Only return a full set of data for the master record if there is a single item
        # Otherwise we just return the essentials for the index listing, saving loads of DB and processing time
        style = @masters.length < 2 ? :full : :index
        m = {
          masters: @masters.as_json(current_user: current_user, filtered_search_results: true, style: style),
          count: {
            count: original_length,
            show_count: mlen
          },
          search_action: search_type,
          message: @result_message
        }



      else
        # Return no results
        @no_masters = true
        m = {message: "no conditions were specified", masters: [], count: {count: 0, show_count: 0} }
      end
    rescue => e
      @no_masters = true
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
          @no_masters = true
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
