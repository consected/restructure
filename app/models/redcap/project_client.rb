# frozen_string_literal: true

module Redcap
  #
  # Direct access to the Redcap gem client, set up with details from a ProjectAdmin record
  # Each request to the API is recorded in the table for audit
  class ProjectClient
    CacheExpiresIn = 60.seconds
    ExpectedKeys = %i[server_url api_key name current_admin].freeze

    attr_accessor :project_admin, *ExpectedKeys

    #
    # Setup the client against the project admin record:
    # @param [Redcap::ProjectAdmin] req_project_admin - project admin record with current admin:
    def initialize(req_project_admin)
      unless req_project_admin.is_a? Redcap::ProjectAdmin
        raise FphsException,
              'can not initialize Redcap Client without a ProjectAdmin'
      end

      self.project_admin = req_project_admin
      # We must call the accessors directly, since api_key is overridden to decrypt the value
      # and a current_admin is required, so we can't just access #attributes
      ExpectedKeys.each do |k|
        val = project_admin.send(k)
        raise FphsException, "Initialization with #{k} blank is not valid" unless val.present?

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
    # Get the project metadata (data dictionary)
    # @return [Hash] hash with symbolized keys
    def metadata
      request :metadata
    end

    #
    # Configure (or return an existing) Redcap gem client
    # A check is made against the project title to ensure the project is set up correctly,
    # and the API is responding.
    # @return [::Redcap]
    def redcap
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
    # The record insert precedes the request, within a transaction, so erroneous actions are not recorded
    # if the action was not actually requested due to a DB error.
    # All requests are cached for 60 seconds to avoid spamming the server.
    # @param [Symbol] action - the name of the request method to call
    # @param [Boolean] force_reload - forces reload of cached data
    # @return [Hash | Array] result
    def request(action, force_reload: nil)
      ClientRequest.transaction do
        ClientRequest.create! current_admin: current_admin,
                              action: action,
                              server_url: server_url,
                              name: name,
                              redcap_project_admin: project_admin

        Rails.cache.delete(cache_key(action)) if force_reload
        Rails.cache.fetch(cache_key(action), expires_in: CacheExpiresIn) do
          post_action action
        end
      end
    end

    def cache_key(action)
      "#{project_admin.id}-#{action}"
    end

    def post_action(action)
      res = redcap.send(action)
      self.class.symbolize_result res
    end
  end
end
