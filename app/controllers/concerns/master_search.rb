# frozen_string_literal: true

module MasterSearch
  extend ActiveSupport::Concern

  DefaultResultsLimit = 100

  # Run a query to get a response for a set of masters.
  # Several different search types can be handled
  # - MSID:
  #   Search a single or list of items by master id, MSID, pro_id,
  #   or another external ID, typically from the URL or nav bar search form
  # - SIMPLE:
  #   A simple Zeus search form
  # - REPORT:
  #   A report
  # - (other)
  #   A preprepared set of search params (for a Zeus advanced search, for example)
  def run(search_type)
    @search_type = search_type

    begin
      if @search_type == 'MSID'
        run_for_master_attribute
      elsif @search_type == 'SIMPLE'
        run_general
      elsif @search_type == 'REPORT'
        res = run_report

        unless res
          render plain: '<b>query must return a master_id field to function as a search</b>'.html_safe
          flash.now[:warning] = 'query must return a master_id field to function as a search'
          @no_masters = true
          return
        end

      else
        run_general
      end

      if @masters
        m = masters_response
      else
        # Return no results
        @no_masters = true
        m = { message: 'no conditions were specified', masters: [], count: { count: 0, show_count: 0 } }
      end
    rescue StandardError => e
      @no_masters = true
      logger.error "Error in MastersController#index: #{e.inspect}\n#{e.backtrace.join("\n")}"
      m = 'error: unable to search - please check your search criteria.'
      return_and_log_error e, m, 400
      return
    end

    respond_to do |format|
      format.json do
        # This is standard, not an export
        render json: m
      end
      format.csv do
        send_csv_response m
      end
    end
  end

  private

  def run_for_master_attribute
    pext = params[:master][:external_id]
    if pext && pext[:id].present?
      ext_id = pext[:id].to_s
      if ext_id.index(/[,| ]/)
        ext_id = ext_id.split(/[,| ]/)
        @sort_by_ids = ext_id.map(&:to_i).uniq
      end
      ext_field = pext[:field]
      m = Master.find_with_alternative_id(ext_field, ext_id, current_user) if ext_field && ext_id
      mids = [m]
      @masters = Master.where(id: mids)
    elsif !params[:master][:id].blank?
      id = params[:master][:id].to_s
      if id.index(/[,| ]/)
        id = id.split(/[,| ]/)
        @sort_by_ids = id.map(&:to_i).uniq
      end
      @masters = Master.where(id: id)
    end
  end

  def run_report
    @search_type = "REPORT: #{@report.name}"

    m_field = @report.runner.field_index('master_id')

    return unless m_field

    ids = []
    @results.each_row { |r| ids << r[m_field].to_i }

    # If the msid is an array of items then return the results in the order of the list
    @masters = Master.where(id: ids)
    @sort_by_ids = ids
  end

  def run_general
    @masters = Master.search_on_params(search_params[:master])
    @masters = @masters.limit(results_limit_value) if @masters
  end

  def preloadables
    Rails.cache.fetch("preloadable_tables_for_user: #{current_user.id}") do
      master = Master.new(current_user: current_user)
      preloadables = []
      tnames = [
        master.subject_info_sym,
        master.secondary_info_sym,
        master.contact_info_sym,
        master.address_info_sym,
        :trackers
      ]

      tnames.each do |tname|
        preloadables << tname if current_user.has_access_to? :access, :table, tname
      end

      preloadables
    end
  end

  def masters_response
    @masters = @masters.limited_access_scope(current_user)

    @masters = @masters.distinct
    # If a list of IDs to sort by is provided (from a report search), sort by it
    # SELECT c.*
    # FROM   comments c
    # JOIN   unnest('{1,3,2,4}'::int[]) WITH ORDINALITY t(id, ord) USING (id)
    # ORDER  BY t.ord
    original_length = @masters.count

    @masters = @masters.preload(*preloadables) if preloadables.present?

    if @sort_by_ids&.present?
      sql = 'masters.id, array_position(array[?], masters.id) order_col'
      safe_sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, [sql, @sort_by_ids])
      @masters = @masters.select(safe_sql).order('order_col')
    end

    if original_length > results_limit_value
      @masters = @masters.limit(results_limit_value)
      mlen = results_limit_value
    else
      mlen = original_length
    end

    if @search_type == 'MSID' && mlen > 0 && @masters.first.id >= 0
      @result_message = "Displaying results for a list of #{mlen} record #{'ID'.pluralize(mlen)}."
    end

    # Only return a full set of data for the master record if there is a single item
    # Otherwise we just return the essentials for the index listing, saving loads of DB and processing time
    style = mlen < 2 ? :full : :index

    {
      masters: @masters.as_json(current_user: current_user, filtered_search_results: true, style: style),
      count: {
        count: original_length,
        show_count: mlen
      },
      search_action: @search_type,
      message: @result_message
    }
  end

  def send_csv_response(m)
    return not_authorized unless current_user.can? :export_csv

    ma = m[:masters].first

    # return bad_request unless ma
    unless ma
      flash[:warning] = 'no results to export'
      redirect_to(child_error_reporter_path)
      @no_masters = true
      return
    end

    res = [(
            ma.map { |k, _v| k } +
            (ma['player_infos'].first || {}).map { |k, _v| "player.#{k}" } +
            (ma['pro_infos'].first || {}).map { |k, _v| "pro.#{k}" }
          ).to_csv]

    m[:masters].each do |mae|
      res << (mae.map { |_k, v| v.is_a?(Hash) || v.is_a?(Array) ? '' : v } +
          (mae['player_infos'].first || {}).map { |_k, v| v } +
          (mae['pro_infos'].first || {}).map { |_k, v| v }).to_csv
    end

    send_data res.join(''), filename: 'report.csv'
  end

  #
  # The number of records to limit results to is either a default 100
  # or the value set in the URL param res_limit
  # @return [<Type>] <description>
  def results_limit_value
    e = 0
    r = params[:res_limit]
    e = r.to_i unless r.blank?
    DefaultResultsLimit if e.zero?
  end
end
