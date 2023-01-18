module Reports
  #
  # Handle the running of a report, including substitutions of search attribute values
  # and special :flag and {{data_reference}} style substitutions.
  class Runner
    attr_accessor :report, :count_only, :sql, :current_user, :results, :using_defaults
    attr_writer :search_attr_values

    ReportIdAttribName = '_report_id_'.freeze

    def initialize(report)
      self.report = report
      self.current_user = report.current_user
      self.sql = report.sql.dup
    end

    #
    # Run the report
    # @param [Hash | String] search_attr_values - hash of search values, or '_use_defaults_' to force use of
    #                                             default values from the report options
    # @param [Admin] current_admin - (optional) indicates that a full SQL error can be communicated if the report fails to run
    # @return [Array] results array from ActiveRecord::Base.connection.execute
    def run(initial_search_attr_values, current_admin = nil)
      raise FphsException, 'SQL is not set' if sql.blank?

      search_attrs_prep initial_search_attr_values
      sql_substitute_all

      self.results = []

      # Get arbitrary data from a table
      # Perform this within a transaction to avoid unexpected data or definition updates,
      # and to avoid failures from breaking other future queries in this request.
      # Note that Postgres is really a requirement for a transaction to protect against DDL. Either way, limiting grants
      # on DDL to the Rails user is expected.
      Report.connection.transaction do
        begin
          self.sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, [sql, search_attr_values])
        rescue StandardError => e
          Rails.logger.info "Failed to sanitize sql: #{e.inspect}.\n#{e.backtrace.join("\n")}"
          raise Report::BadSearchCriteria, "Failed to sanitize SQL. #{e}"
        end

        begin
          self.results = connection.execute(sql)
          # Set the type_map to handle JSON correctly
          results.type_map = type_map
        rescue StandardError => e
          Rails.logger.info "Failed to run sql: #{e.inspect}.\n#{sql}"
          msg = 'Failed to run query.'
          msg += e.to_s if current_admin
          raise FphsException, msg
        end
        raise ActiveRecord::Rollback
      end

      cache_results
      results
    end

    #
    # Store the results to the cache for previous filtering
    # if a current user is set (not just an admin) and we are not using defaults.
    # Using defaults indicates this is an auto run query and therefore should not affect the cache.
    def cache_results
      return unless current_user && !using_defaults

      # Do the results contain master_id? If so, get a unique list of master id results
      master_ids = results.map { |r| r['master_id'] }.uniq if field_index('master_id')

      # We through other stuff into the search attribute values that are not needed for storing results
      # Just pass over the real key-value pairs that correspond to the configured attributes
      real_search_attr_values = search_attr_values.slice(*search_attributes.keys)

      previous_filtering.store_results(report.id, report.name, master_ids, results.count, real_search_attr_values)
    end

    #
    # The database connection
    def connection
      Report.connection
    end

    #
    # This is needed by results to get real return values for JSON
    def type_map
      @type_map ||= PG::BasicTypeMapForResults.new(connection.raw_connection)
    end

    def data_reference
      @data_reference ||= Reports::DataReference.new self
    end

    def previous_filtering
      @previous_filtering ||= Reports::PreviousFiltering.new self
    end

    #
    # Get the table names corresponding to each column in the results
    # Since PG only returns oid values for each
    def result_tables
      return unless @results

      return @result_tables if @result_tables

      @result_tables = {}

      i = 0
      @results.fields.each do |_col|
        oid = @results.ftable(i).to_i.to_s # make sure it's clean and usable

        unless @result_tables.key? oid
          clean_sql = "select relname from pg_class where oid=#{oid.to_i}"
          get_res = Report.connection.execute(clean_sql)

          table_name = get_res.first.first.last if get_res&.first

          @result_tables[oid] = table_name
        end
        i += 1
      end
      @result_tables
    end

    def result_tables_by_index
      return unless @results && @results.count > 0

      return @result_tables_oid if @result_tables_oid

      l = @results.fields.length

      @result_tables_oid = []
      (0..l - 1).each do |i|
        oid = @results.ftable(i).to_s
        @result_tables_oid[i] = result_tables[oid]
      end
      @result_tables_oid
    end

    #
    # Get the index for a named field
    # @param [String] name
    # @return [Integer]
    def field_index(name)
      @results.fields.index(name)
    end

    def search_attr_values
      @search_attr_values || {}
    end

    #
    # Support substitutions
    # @return [Hash{String:}]
    def attributes
      return @attributes if @attributes

      @attributes = {}
      %i[report count_only sql current_user results using_defaults].each do |k|
        @attributes[k.to_s] = send(k)
      end

      @attributes
    end

    protected

    #
    # Basic cleanup of SQL string for run
    # @return [String] new SQL string
    def prep_sql_for_run
      self.sql = sql.strip
      self.sql = sql[0..-2] if sql.last == ';'
      self.sql = sql.dup
    end

    #
    # Substitutes the flag :file_filtering_conditions_for_[a-z_] with SQL
    # that filters the files the current user can see.
    # The full flag will be something like:
    #    :file_filtering_conditions_for_activity_log__ipa_assignment_session_filestore
    #
    # This indicates that the filtering should be based on the resource name
    # `activity_log__ipa_assignment_session_filestore`
    def substitute_file_filters(sql)
      sql.scan(/:file_filtering_conditions_for_[a-z_]+/) do |file_filter|
        if file_filter.present?
          resource_name = file_filter.sub(':file_filtering_conditions_for_', '')
          ffcond = file_filtering_conditions resource_name
          sql = sql.sub(file_filter, ffcond)
        end
      end
      sql
    end

    #
    # Substitute the flag :current_user in SQL with the current user's ID
    # or NULL if not set
    # @param [String] sql
    # @return [String] SQL with substitutions
    def substitute_current_user(sql)
      sql
        .gsub(':current_user_preference', current_user&.user_preference&.id&.to_s || 'NULL')
        .gsub(':current_user', current_user&.id&.to_s || 'NULL')
    end

    #
    # Substitute with the equivalent of double-curly substitution variables
    # @param [String] sql
    # @return [String] SQL with substitutions
    def substitute_substitutions(sql)
      Formatter::Substitution.substitute(sql, data: self, ignore_missing: true)
    end

    #
    # Import config libraries using:
    # -- @library <category> <name>
    # @param [String] sql
    # @return [String] SQL with substitutions
    def substitute_from_config_libraries(sql)
      Admin::ConfigLibrary.make_substitutions! sql, :sql
      sql
    end

    #
    # If a "count only" request is being made, prepare the SQL to generate the count.
    # @param [String] sql
    # @return [String] SQL with substitutions
    def substitute_count(sql)
      sql = "select count(*) \"result_count\" from (#{sql}) t".dup if count_only
      sql
    end

    def sql_substitute_all(run_once = nil)
      self.sql = prep_sql_for_run
      self.sql = previous_filtering.substitute_filter_previous(sql) unless using_defaults
      self.sql = data_reference.sql_substitutions(sql)
      self.sql = substitute_current_user(sql)
      self.sql = substitute_substitutions(sql)
      self.sql = substitute_file_filters(sql)
      self.sql = substitute_from_config_libraries(sql)
      self.sql = sql_substitute_all(true) unless run_once

      sql
    end

    def search_attributes
      report.search_attributes
    end

    def search_attributes_config
      report.search_attributes_config
    end

    #
    # Assign default values to the search attribute values, based on the search attributes configuration
    # Saves the hash to the #search_attr_values attribute and returns the same value
    # @return [Hash]
    def use_defaults
      self.search_attr_values = {}

      search_attributes_config.each do |k, v|
        search_attr_values[k.to_sym] = FieldDefaults.calculate_default(self, v.default, v.type)
      end
      search_attr_values
    end

    #
    # Prepare search attribute values ready for the report to be run
    # Set any values to nil that don't already exist in the values passed in, but are
    # configured as search attributes, so the query runs correctly when referring to values
    # Only include key / value pairs for configured search_attributes, removing other values
    # we may have injected
    # Set the search values so:
    # - anything blank is set to nil
    # - hash values collect the values as an array
    # - strings with newlines are cleaned if simple, or prepared for regex if multiple-regex requested
    # Set up value for :ids_filter_previous filtering is on
    def search_attrs_prep(initial_search_attr_values)
      self.search_attr_values = initial_search_attr_values
      self.search_attr_values = use_defaults if using_defaults

      if search_attr_values.respond_to? :to_unsafe_h
        self.search_attr_values = search_attr_values.to_unsafe_h.symbolize_keys
      end

      search_attributes = self.search_attributes.symbolize_keys
      ks = search_attributes.keys
      ks.each do |k|
        search_attr_values[k] = nil unless search_attr_values.key? k
      end

      search_attr_values.slice!(*ks)

      search_attr_values.each do |k, v|
        if v.blank?
          search_attr_values[k] = nil
        elsif v.is_a? Hash
          search_attr_values[k] = v.collect { |_, v1| v1 }
        elsif v.is_a?(String) && v.include?("\n")
          search_attr_values[k] = if search_attributes_config[k.to_sym].multiple == 'multiple-regex'
                                    "(#{v.split("\n").map(&:squish).join('|')})"
                                  else
                                    v.split("\n").map(&:squish)
                                  end
        end
      end

      search_attr_values[:ids_filter_previous] = nil

      if previous_filtering.sql_requests_filtering
        previous_filtering.requested = (search_attr_values[:_filter_previous_] == 'true')
        search_attr_values[:ids_filter_previous] = previous_filtering.filtering_ids
      end
    end

    #
    # Returns SQL to be used directly to filter
    # files based on the user's filter configurations
    # @see NfsStore::Filter::Filter.generate_filters_for
    def file_filtering_conditions(resource_name)
      NfsStore::Filter::Filter.generate_filters_for resource_name, user: current_user
    end
  end
end
