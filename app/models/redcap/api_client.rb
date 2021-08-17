# frozen_string_literal: true

module Redcap
  #
  # Direct access to the Redcap gem api_client, set up with details from a ProjectAdmin record
  # Each request to the API is recorded in the redcap_client_requests table for audit
  class ApiClient
    CacheExpiresIn = 60.seconds
    ExpectedKeys = %i[server_url api_key name current_admin].freeze

    attr_accessor :project_admin,
                  :records_request_options,
                  :metadata_request_options,
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
    # @return [Hash] hash with symbolized keys
    def project_users
      request :user
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
    # Get the data records for the project
    # @return [Array{Hash}] hash with symbolized keys
    def records(request_options: nil)
      request_options ||= records_request_options
      request :records, request_options: request_options
    end

    #
    # Get a file from a file field.
    # Don't record the file field retrievals in ClientRequest
    # since it will flood them with useless logs
    # @param [String | Integer] record_id
    # @param [String | Symbol] field_name
    # @return [File] - temp file result
    def file(record_id, field_name)
      tempfile = redcap.file record_id, field_name
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
        token: api_key
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

    private

    #
    # Make a request to the Redcap server, and save the request action as an audit record.
    # All requests are cached for 60 seconds to avoid spamming the server.
    # @param [Symbol] action - the name of the request method to call
    # @param [Boolean] force_reload - forces reload of cached data
    # @return [Hash | Array] result
    def request(action, force_reload: nil, request_options: nil)
      res = nil
      ClientRequest.transaction do
        cc = cache_key(action, request_options)
        clear_cache(cc) if force_reload
        retrieved_from = 'cache'
        res = Rails.cache.fetch(cc, expires_in: CacheExpiresIn) do
          retrieved_from = 'api'
          post_action action, request_options
        end

        project_admin.record_job_request action, result: { retrieved_from: retrieved_from }
      end
      res
    end

    def cache_key(action, request_options = nil)
      "#{self.class.name}-#{project_admin.id}-#{action}-#{request_options}"
    end

    def clear_cache(cache_key)
      Rails.cache.delete(cache_key)
    end

    def post_action(action, request_options)
      res = redcap.send(action, { request_options: request_options })
      self.class.symbolize_result res
    end
  end
end
