# frozen_string_literal: true

module Redcap
  #
  # Direct access to the Redcap gem api_client, set up with details from a ProjectAdmin record
  # Each request to the API is recorded in the redcap_client_requests table for audit
  class ApiClient
    DefaultCacheExpiresIn = 60.seconds
    ExpectedKeys = %i[server_url api_key name current_admin].freeze

    OverwriteBehaviorOptions = %w[normal overwrite].freeze

    attr_accessor :project_admin,
                  :records_request_options,
                  :metadata_request_options,
                  :last_result_from_cache,
                  *ExpectedKeys

    #
    # Setup the api_client against the project admin record:
    # @param [Redcap::ProjectAdmin] req_project_admin - project admin record with current admin:
    def initialize(req_project_admin)
      unless req_project_admin.is_a? Redcap::ProjectAdmin
        raise FphsException,
              'can not initialize Redcap Client without a ProjectAdmin'
      end

      self.project_admin = req_project_admin
      self.records_request_options = project_admin.records_request_options.filtered_hash
      self.metadata_request_options = project_admin.metadata_request_options.filtered_hash
      # We must call the accessors directly, since api_key is overridden to decrypt the value
      # and a current_admin is required, so we can't just access #attributes
      ExpectedKeys.each do |k|
        val = project_admin.send(k)
        raise FphsException, "Initialization with #{k} blank is not valid" unless val.present? || project_admin.disabled

        send("#{k}=", val)
      end

      redcap

      super()
    end

    #
    # Get the project info data
    # @return [Hash] hash with symbolized keys
    def project
      request :project
    end

    #
    # Get the project users
    # @param [Boolean] force_reload - forces reload of the cached user list from the REDCap API
    # @return [Hash] hash with symbolized keys
    def project_users(force_reload: false)
      request :user, force_reload:
    end

    #
    # Remove a user's access from the project.
    # NOTE: the REDCap API user used to make this request requires the following privileges
    # in the project: "API Import/Update", "User Rights" (Full Access), "Delete Records".
    # This does NOT automatically refresh the cached #project_users list. To do so,
    # configure an on_complete hook to call #project_users with force_reload: true
    # (see the redcap_request save_trigger documentation).
    # @param [String] username - a single REDCap username to remove
    # @param [Array{String}] usernames - multiple REDCap usernames to remove, instead of username
    # @return [Integer] the number of users removed, as returned by the REDCap API
    def remove_project_user(username: nil, usernames: nil)
      usernames = Array.wrap(usernames.presence || username).map(&:to_s).select(&:present?)
      raise FphsException, 'remove_project_user requires a username or usernames to be specified' if usernames.blank?

      request_options = { action: :delete }
      usernames.each_with_index do |name, index|
        request_options["users[#{index}]"] = name
      end

      # This request mutates data on the REDCap server, so never cache the result
      request :user, request_options: request_options, cache_expires_in: nil
    end

    #
    # Get the project archive XML file, including study fields.
    # Return a temp file result.
    # @return [File] - temp file result
    def project_archive
      tempfile = redcap.project_xml request_options: {
        returnMetadataOnly: 'false',
        exportSurveyFields: 'true',
        exportDataAccessGroups: 'true',
        returnFormat: 'json'
      }

      project_admin.record_job_request 'project_xml', result: { retrieved_from: 'api' }

      FileUtils.chmod 0o660, tempfile
      tempfile
    end

    #
    # Get the project metadata (data dictionary)
    # @return [Array{Hash}] hash with symbolized keys
    def metadata(request_options: nil)
      request_options ||= metadata_request_options
      request :metadata, request_options: request_options
    end

    #
    # Get the project instrument results (data collection instruments)
    # @return [Array{Hash}] hash with symbolized keys
    def instruments(request_options: nil)
      request_options ||= metadata_request_options
      request :instrument, request_options: request_options
    end

    #
    # Get the project arms results (for longitudinal projects)
    # @return [Array{Hash}] hash with symbolized keys
    def arms(request_options: nil)
      request_options ||= metadata_request_options
      request :arm, request_options: request_options
    end

    #
    # Get the project events results (for longitudinal projects)
    # @return [Array{Hash}] hash with symbolized keys
    def events(request_options: nil)
      request_options ||= metadata_request_options
      request :event, request_options: request_options
    end

    #
    # Get the project events results (for longitudinal projects)
    # @return [Array{Hash}] hash with symbolized keys
    def repeating_forms_events(request_options: nil)
      request_options ||= metadata_request_options
      request :repeating_forms_events, request_options: request_options
    end

    #
    # Get the data records for the project
    # @param [Hash] request_options - options to pass to the REDCap API
    # @param [DateTime | nil] date_range_begin - optional dateRangeBegin filter for retrieving only updated records
    # @param [Boolean] ignore_cache - force pull from REDCap, bypassing cache
    # @return [Array{Hash}] hash with symbolized keys
    def records(request_options: nil, date_range_begin: nil, ignore_cache: false)
      request_options ||= records_request_options.dup
      request_options = request_options.dup if request_options.frozen?
      if date_range_begin
        server_tz = project_admin.data_options.server_time_zone
        date_range_begin = date_range_begin.in_time_zone(server_tz) if server_tz.present?
        request_options[:dateRangeBegin] = date_range_begin.strftime('%Y-%m-%d %H:%M:%S')
      end
      cache_expires_in = ignore_cache ? nil : record_export_cache_time
      request :records, request_options:, cache_expires_in:
    end

    #
    # Get survey link for an instrument and specific record
    # @param [String] instrument - name of instrument to retrieve link for
    # @param [Integer] record_id - record ID to retrieve link for
    # @param [String] event - optional event name for longitudinal projects
    # @return [Array{Hash}] hash with symbolized keys
    def survey_link(instrument:, record_id:, event: nil)
      request_options = {
        instrument:,
        record: record_id.to_s,
        returnFormat: 'json'
      }

      request_options[:event] = event if event.present?
      request :survey_link, request_options: request_options
    end

    #
    # Get survey participants for all records in an instrument
    # @param [String] instrument - name of instrument to retrieve link for
    # @param [String] event - optional event name for longitudinal projects
    # @return [Array{Hash}] hash with symbolized keys
    def survey_participants(instrument:, event: nil)
      request_options = {
        instrument:,
        event:,
        returnFormat: 'json'
      }
      request :participant_list, request_options: request_options
    end

    #
    # Get survey participants for all records in an instrument
    # @param [String] instrument - name of instrument to retrieve link for
    # @return [Array{Hash}] hash with symbolized keys
    def import_records(data:, force_auto_number: true, overwrite_behavior: 'normal')
      unless overwrite_behavior&.in?(OverwriteBehaviorOptions)
        raise FphsException,
              "Invalid import_records overwrite_behavior '#{overwrite_behavior}' - " \
              "must be one of #{OverwriteBehaviorOptions}"
      end

      unless data.is_a?(Array) && data.first.is_a?(Hash)
        raise FphsException, 'Invalid import_records data format - must be an array of hashes'
      end

      data = data.to_json
      return_content = force_auto_number ? 'auto_ids' : 'ids'

      request_options = {
        data:,
        forceAutoNumber: force_auto_number,
        overwriteBehavior: overwrite_behavior,
        returnContent: return_content,
        returnFormat: 'json'
      }
      res = request :create, request_options: request_options
      return res if res.is_a?(Array) && res.length == 2

      # Handle the situation where the API incorrectly returns a string within an array
      if res.is_a?(Array) && res.length == 1 && res.first.is_a?(String)
        Rails.logger.warn "Redcap API returned a string within an array for import_records #{request_options} - #{res}"
        res = res.first.split(',')
      end

      res
    end

    #
    # Export log messages, optionally by record_id, between a date range and for a log type
    # @param [String | Integer | nil] record_id
    # @param [Time | nil] begin_time
    # @param [Time | nil] end_time
    # @param [String | Symbol | nil] log_type - one of Redcap::ApiClient::ValidEventLogTypes keys
    # @return [Array<Hash>] hash with symbolized keys
    def export_logs(record_id: nil, begin_time: nil, end_time: nil, log_type: nil)
      request :export_log, request_options: { record: record_id,
                                              beginTime: begin_time,
                                              endTime: end_time,
                                              logType: log_type }
    end

    #
    # export the instrument-event mappings for a project (i.e., how the data collection instruments are designated for certain events in a longitudinal project).
    # NOTE: This only works for longitudinal projects.
    # @return [Array<Hash>] hash with symbolized keys
    def form_event_mapping
      request :form_event_mapping
    end

    #
    # Export List of Export Field Names (i.e. variables used during exports and imports)
    # @return [Array<Hash>] hash with symbolized keys
    def export_field_names
      request :export_field_names
    end

    #
    # Get a file from a file field.
    # Don't record the file field retrievals in ClientRequest
    # since it will flood them with useless logs
    # @param [String | Integer] record_id
    # @param [String | Symbol] field_name
    # @param [String] event - optional event name for longitudinal projects
    # @return [File] - temp file result
    def file(record_id, field_name, event: nil)
      tempfile = redcap.file(record_id, field_name, event:)
      FileUtils.chmod 0o660, tempfile
      tempfile
    end

    #
    # Configure (or return an existing) Redcap gem client
    # A check is made against the project title to ensure the project is set up correctly,
    # and the API is responding.
    # @return [::Redcap]
    def redcap
      raise FphsException, 'Initialization with current_admin blank is not valid' unless current_admin
      raise FphsException, 'a valid admin is required' unless current_admin.is_a?(Admin) && current_admin.enabled?

      return @redcap if @redcap

      opt = {
        host: server_url,
        token: api_key,
        logger: Rails.logger,
        log_level:
      }

      @redcap = ::Redcap.new(opt)

      raise FphsException, 'Failed Redcap gem configuration' unless @redcap.is_a? Redcap::Client

      got_title = project[:project_title]
      unless got_title == name
        raise FphsException,
              "project title (#{got_title}) does not match the expected name (#{name})"
      end

      @redcap
    end

    def self.symbolize_result(res)
      case res
      when Hash
        res.symbolize_keys!
      when Array
        res.each { |row| row.symbolize_keys! if row.is_a? Hash }
      end
      res
    end

    def response_code
      redcap.response_code
    end

    #
    # Get the cache expiry time for metadata requests
    # @return [ActiveSupport::Duration | nil] - duration or nil if caching disabled
    def metadata_export_cache_time
      cache_time = project_admin.data_options.metadata_export_cache_time
      return DefaultCacheExpiresIn if cache_time.nil?
      return nil if cache_time.to_i.zero?

      cache_time.to_i.seconds
    end

    #
    # Get the cache expiry time for record requests
    # @return [ActiveSupport::Duration | nil] - duration or nil if caching disabled
    def record_export_cache_time
      cache_time = project_admin.data_options.record_export_cache_time
      return DefaultCacheExpiresIn if cache_time.nil?
      return nil if cache_time.to_i.zero?

      cache_time.to_i.seconds
    end

    private

    #
    # Make a request to the Redcap server, and save the request action as an audit record.
    # Requests are cached based on the configurable cache time (default 60 seconds).
    # @param [Symbol] action - the name of the request method to call
    # @param [Boolean] force_reload - forces reload of cached data
    # @param [Hash] request_options - options to pass to the REDCap API
    # @param [ActiveSupport::Duration | nil] cache_expires_in - cache expiry time, nil to skip caching
    # @return [Hash | Array] result
    def request(action, force_reload: nil, request_options: nil, cache_expires_in: DefaultCacheExpiresIn)
      res = nil
      self.last_result_from_cache = false
      ClientRequest.transaction do
        cc = cache_key(action, request_options)
        clear_cache(cc) if force_reload
        retrieved_from = 'cache'

        if cache_expires_in
          res = Rails.cache.fetch(cc, expires_in: cache_expires_in) do
            retrieved_from = 'api'
            post_action action, request_options
          end
        else
          # Caching disabled - always fetch from API
          clear_cache(cc)
          retrieved_from = 'api'
          res = post_action action, request_options
        end

        self.last_result_from_cache = (retrieved_from == 'cache')
        api_action = request_options && (request_options[:action] || request_options['action'])
        count = res.respond_to?(:length) ? res.length : res
        project_admin.record_job_request action, result: { retrieved_from:, count:, api_action: }
      end
      res
    rescue StandardError => e
      r_code = response_code
      r_body = res
      Rails.logger.error "Redcap::ApiClient request failed for action '#{action}' - #{e} - " \
                         "with request options: #{request_options} - " \
                         "code: #{r_code} - body: #{r_body}\n" \
                         "#{e.backtrace.join("\n")}"
      raise
    end

    def cache_key(action, request_options = nil)
      "#{self.class.name}-#{project_admin.id}-#{action}-#{request_options}"
    end

    def clear_cache(cache_key)
      Rails.cache.delete(cache_key)
    end

    def post_action(action, request_options)
      redcap.raw_response = nil
      res = redcap.send(action, request_options: request_options)
      self.class.symbolize_result res
    end

    def log_level
      return @log_level if @log_level.present?

      log_level_s = Settings::LogLevel[:redcap_api].to_s
      @log_level = Logger::Severity.const_get(log_level_s.upcase) if log_level_s.present?
      @log_level ||= Rails.logger.level
    end
  end
end
