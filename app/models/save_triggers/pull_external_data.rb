# frozen_string_literal: true

class SaveTriggers::PullExternalData < SaveTriggers::SaveTriggersBase
  attr_accessor :response_code

  BODY_METHODS = %w[put patch lock mkcol propfind proppatch unlock].freeze
  NO_BODY_METHODS = %w[head delete options trace copy move].freeze
  MAX_ERROR_BODY_LENGTH = 10_000

  # Re-exposed so existing callers and rescue blocks keep working after the
  # SSRF guard was extracted into Utilities::UrlSafety.
  UnsafeUrlError = Utilities::UrlSafety::UnsafeUrlError

  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    @model_defs = self.config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each_value do |config|
        with_entry_lifecycle(config) do
          data_field = config[:data_field]
          response_code_field = config[:response_code_field]
          data_field_format = config[:data_field_format]
          local_data_name = config[:local_data]
          success_if = config[:success_if]
          vals = {}

          # We calculate the conditional if inside each item, rather than relying
          # on the outer processing in ActivityLogOptions#calc_save_trigger_if
          if config[:if]
            ca = ConditionalActions.new config[:if], @item
            next unless ca.calc_action_if
          end

          @this_config = config
          @submitted_request_data = nil
          data = run_request
          orig_data = data

          if data_field
            data = data&.to_json if data_field_format == 'json'
            vals[data_field] = data
          end

          vals[response_code_field] = response_code if response_code_field
          store_local_data_results(local_data_name, orig_data)

          # We calculate the conditional if inside each item, rather than relying
          # on the outer processing in ActivityLogOptions#calc_save_trigger_if
          success_if_res = nil
          if success_if
            ca = ConditionalActions.new success_if, @item
            success_if_res = !!ca.calc_action_if
            @item.save_trigger_results["#{local_data_name}_success_if_res"] = success_if_res if local_data_name
          end

          uri = url_from_config.split('?').first
          logmsg = "pull_external_data #{method_from_config} -> #{uri} = response code #{response_code} " \
                   "&& success_if_res #{success_if_res}"
          if response_code.between?(200, 299) && success_if_res != false
            Rails.logger.info logmsg
          else
            Rails.logger.warn logmsg
          end

          raise FphsException, "pull_external_data success_if condition failed for #{uri}" if success_if_res == false

          next unless vals.present?

          raise_if_in_before_save_trigger!
          update_item(vals, config)
        end
      end
    end
  end

  def run_request
    method = method_from_config
    case method
    when 'get', *NO_BODY_METHODS
      send_no_body_request(method)
    when 'post'
      if post_data_config
        send_body_request(method)
      else
        post_form
      end
    when *BODY_METHODS
      send_body_request(method)
    else
      raise FphsException, "pull_external_data method '#{method}' is not supported"
    end
  end

  def post_form
    uri = safe_uri_parse(url_from_config)
    form = @this_config[:form] || {}
    form = form.deep_transform_values { |v| FieldDefaults.calculate_default @item, v }
    @submitted_request_data = form.deep_stringify_keys
    response = Net::HTTP.post_form(uri, form)
    handle_response(to_config, response)
  end

  def send_body_request(method)
    uri = safe_uri_parse(url_from_config)
    data = serialize_send_data

    request_class = Net::HTTP.const_get(method.capitalize)
    req = request_class.new(uri)
    req.body = data
    apply_headers(req)

    response = start_http(uri).request(req)
    handle_response(to_config, response)
  end

  def send_no_body_request(method)
    uri = safe_uri_parse(url_from_config)
    request_class = Net::HTTP.const_get(method.capitalize)
    req = request_class.new(uri)
    apply_headers(req)

    response = start_http(uri).request(req)
    handle_response(from_config || to_config, response)
  end

  def start_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http
  end

  def handle_response(sub_config, response)
    url = url_from_config
    http_method = method_from_config
    allow_empty_result = sub_config[:allow_empty_result]
    allow_response_codes = sub_config[:allow_response_codes] || []
    format = sub_config[:format]

    self.response_code = response.code.to_i
    local_data_name = @this_config[:local_data]
    store_response_headers(local_data_name, response_headers(response))
    # Store response code and submitted request details now, before any raise below, so
    # on_failure hooks have them regardless of whether the request ultimately succeeds.
    store_response_metadata(local_data_name)
    content = response.body
    successful_response = response_code.between?(200, 299)
    allowed_non_success_response = !successful_response && response_code.in?(allow_response_codes)

    unless successful_response || allowed_non_success_response
      store_failure_content(local_data_name, content, format)
      uri = url.split('?').first
      raise FphsException,
            "#{http_method} external data: failed request with code '#{response_code}' from url #{uri}; " \
            "response body: #{content.to_s.truncate(MAX_ERROR_BODY_LENGTH)}"
    end

    if content.blank?
      return if allow_empty_result || allowed_non_success_response

      store_local_data_results(local_data_name, content)
      uri = url.split('?').first
      raise FphsException, "#{http_method} external data: empty content received from #{uri}"
    end

    begin
      parse_response_content(content, format, fallback_to_raw: allowed_non_success_response)
    rescue JSON::ParserError, REXML::ParseException, ActiveSupport::XMLConverter::DisallowedType
      store_local_data_results(local_data_name, content)
      raise
    end
  end

  def url_from_config
    sub_config = from_config || to_config
    url = sub_config[:url]
    Formatter::Substitution.substitute(url, data: @item, ignore_missing: false)
  end

  def method_from_config
    @this_config[:method] || 'get'
  end

  def from_config
    @this_config[:from]
  end

  def to_config
    @this_config[:to]
  end

  def post_data_config
    @this_config[:send_data] || @this_config[:post_data]
  end

  def header_config
    sub_config = from_config || to_config
    headers = sub_config[:headers]
    return unless headers

    substitute_values_in_config(headers)
    headers.stringify_keys
  end

  private

  # Reentrant #update! on `this` from within a before_save trigger corrupts the outer
  # save's dirty-tracking, silently breaking on_create/on_update/on_disable dispatch (issue #1384).
  def raise_if_in_before_save_trigger!
    return unless @item.respond_to?(:in_before_save_trigger) && @item.in_before_save_trigger

    raise FphsException,
          'pull_external_data can not update the record being saved from within a ' \
          'before_save trigger - the outer save is still in progress, so this write would ' \
          'be lost or corrupt on_create/on_update/on_disable trigger dispatch (issue #1384); ' \
          'use on_create/on_update/on_disable instead'
  end

  #
  # Serialize the send_data / post_data configuration value to a JSON string
  # or calculate it as a default field value
  # @return [String]
  def serialize_send_data
    data = post_data_config || {}
    if data.is_a? Hash
      data = data.deep_stringify_keys
      data = data.deep_transform_values { |v| FieldDefaults.calculate_default @item, v }
      @submitted_request_data = data.dup
      data.to_json
    else
      @submitted_request_data = FieldDefaults.calculate_default(@item, data)
    end
  end

  #
  # Apply configured headers to a Net::HTTP request object
  # @param [Net::HTTPGenericRequest] req
  def apply_headers(req)
    header_config&.each { |k, v| req[k] = v }
  end

  def parse_response_content(content, format, fallback_to_raw: false)
    case format
    when 'xml'
      Hash.from_xml(content)
    when 'json'
      JSON.parse(content)
    when 'text', nil
      content
    end
  rescue JSON::ParserError, REXML::ParseException, ActiveSupport::XMLConverter::DisallowedType
    raise unless fallback_to_raw

    content
  end

  def response_headers(response)
    response.each_header.with_object({}) do |(name, value), headers|
      headers[name] = value
      headers[name.id_underscore.to_sym] = value
    end
  end

  def store_response_headers(local_data_name, headers)
    return unless local_data_name && headers

    @item.save_trigger_results["#{local_data_name}_http_response_headers"] = headers
  end

  def store_response_metadata(local_data_name)
    return unless local_data_name

    @item.save_trigger_results["#{local_data_name}_http_response_code"] = response_code
    @item.save_trigger_results["#{local_data_name}_submitted_request"] = {
      'data' => @submitted_request_data,
      'url' => url_from_config,
      'method' => method_from_config
    }
  end

  # Best-effort attempt to store a failed response's body under the local_data key, so
  # on_failure hooks can inspect the error content the same way a successful result would be.
  def store_failure_content(local_data_name, content, format)
    return unless local_data_name

    @item.save_trigger_results[local_data_name] = parse_response_content(content, format, fallback_to_raw: true)
  end

  def store_local_data_results(local_data_name, data)
    return unless local_data_name

    @item.save_trigger_results[local_data_name] = data
  end

  def update_item(vals, config)
    # Retain the flags so that the #update! doesn't change
    # what we need to report through the API
    res = @item
    created = res._created
    updated = res._updated
    disabled = res._disabled
    @item.transaction do
      res.ignore_configurable_valid_if = true if config[:force_not_valid]
      res.force_save! if config[:force_not_editable_save]
      res.update! vals.merge(current_user: @item.current_user || @item.user, skip_save_trigger: true)
    end
    res._created = created
    res._updated = updated
    res._disabled = disabled
  end

  #
  # Parse and SSRF-validate the configured URL before opening a connection.
  # Admin configuration and substitutions from record fields can both influence
  # url_from_config, so every URL must be checked. Delegates to the reusable
  # Utilities::UrlSafety validator using pull_external_data-scoped settings.
  # @param [String] url
  # @return [URI::Generic]
  # @raise [UnsafeUrlError]
  def safe_uri_parse(url)
    Utilities::UrlSafety.safe_parse(
      url,
      allowed_hosts: Settings::PullExternalDataAllowedHosts,
      allow_private: Settings::PullExternalDataAllowPrivateHosts,
      context: 'pull_external_data'
    )
  end
end
