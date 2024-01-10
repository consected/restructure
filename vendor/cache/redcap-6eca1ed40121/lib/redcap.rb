require 'hashie'
require 'json'
require 'rest-client'
require 'logger'
require 'dotenv'
require 'memoist'
require 'redcap/version'
require 'redcap/configuration'
require 'redcap/record'

Dotenv.load

module Redcap
  attr_reader :configuration

  class << self
    def new(options = {})
      if options.empty? && ENV
        options[:host] = ENV['REDCAP_HOST']
        options[:token] = ENV['REDCAP_TOKEN']
      end
      self.configure = options
      Redcap::Client.new
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure=(options)
      @configuration = if options.nil?
                         nil
                       else
                         Configuration.new(options)
                       end
    end

    def configure
      yield configuration
      configuration
    end
  end

  class Client
    extend Memoist

    attr_reader :logger
    attr_writer :log

    def initialize
      @logger = Logger.new STDOUT
    end

    def configuration
      Redcap.configuration
    end

    def log?
      @log ||= false
    end

    def log(message)
      return unless @log

      @logger.debug message
    end

    def project(request_options: nil)
      payload = build_payload content: :project, request_options: request_options
      post payload
    end

    def user(request_options: nil)
      payload = build_payload content: :user, request_options: request_options
      post payload
    end

    def project_xml(request_options: nil)
      payload = build_payload content: :project_xml, request_options: request_options
      post_file_request payload
    end

    def max_id
      records(fields: %w[record_id]).map(&:values).flatten.map(&:to_i).max.to_i
    end

    def fields
      metadata.map { |m| m['field_name'].to_sym }
    end

    def metadata(request_options: nil)
      payload = {
        token: configuration.token,
        format: configuration.format,
        content: :metadata,
        fields: []
      }

      payload.merge! request_options if request_options
      post payload
    end

    def instrument(request_options: nil)
      payload = {
        token: configuration.token,
        format: configuration.format,
        content: :instrument
      }

      payload.merge! request_options if request_options
      post payload
    end

    def records(records: [], fields: [], filter: nil, request_options: nil)
      # add :record_id if not included
      fields |= [:record_id] if fields.any?
      payload = build_payload content: :record,
                              records: records,
                              fields: fields,
                              filter: filter,
                              request_options: request_options
      post payload
    end

    def update(data = [], request_options: nil)
      payload = {
        token: configuration.token,
        format: configuration.format,
        content: :record,
        overwriteBehavior: :normal,
        type: :flat,
        returnContent: :count,
        data: data.to_json
      }
      payload.merge! request_options if request_options
      log flush_cache if ENV['REDCAP_CACHE'] == 'ON'
      result = post payload
      result['count'] == 1
    end

    def create(data = [], request_options: nil)
      payload = {
        token: configuration.token,
        format: configuration.format,
        content: :record,
        overwriteBehavior: :normal,
        type: :flat,
        returnContent: :ids,
        data: data.to_json
      }
      payload.merge! request_options if request_options
      log flush_cache if ENV['REDCAP_CACHE'] == 'ON'
      post payload
    end

    def delete(ids, request_options: nil)
      return unless ids.is_a?(Array) && ids.any?

      payload = build_payload content: :record, records: ids, action: :delete, request_options: request_options
      log flush_cache if ENV['REDCAP_CACHE'] == 'ON'
      post payload
    end

    def file(record_id, field_name)
      payload = build_payload content: :file,
                              action: :export,
                              request_options: { field: field_name, record: record_id }
      post_file_request payload
    end

    private

    def build_payload(content: nil, records: [], fields: [], filter: nil, action: nil, request_options: nil)
      payload = {
        token: configuration.token,
        format: configuration.format,
        content: content
      }
      payload[:action] = action if action

      records&.each_with_index do |record, index|
        payload["records[#{index}]"] = record
      end

      fields&.each_with_index do |field, index|
        payload["fields[#{index}]"] = field
      end

      payload[:filterLogic] = filter if filter
      payload.merge!(request_options) if request_options
      payload
    end

    def post(payload = {})
      log "Redcap POST to #{configuration.host} with #{payload}"
      response = RestClient.post configuration.host, payload
      response = JSON.parse(response)
      log 'Response:'
      log response
      response
    end
    memoize(:post) if ENV['REDCAP_CACHE'] == 'ON'

    def post_file_request(payload = {})
      log "Redcap POST for file field to #{configuration.host} with #{payload}"
      response = RestClient::Request.execute method: :post, url: configuration.host, payload: payload,
                                             raw_response: true
      file = response.file
      log 'File:'
      log file
      file
    end
  end
end
