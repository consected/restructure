# frozen_string_literal: true

class SaveTriggers::PullExternalData < SaveTriggers::SaveTriggersBase
  attr_accessor :response_code

  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each do |_model_name, config|
        data_field = config[:data_field]
        response_code_field = config[:response_code_field]
        data_field_format = config[:data_field_format]
        local_data_name = config[:local_data]
        vals = {}

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        data = run_request(config)

        if data_field
          data = data&.to_json if data_field_format == 'json'
          vals[data_field] = data
        end

        vals[response_code_field] = response_code if response_code_field
        if local_data_name
          @item.save_trigger_results[local_data_name] = data
          @item.save_trigger_results["#{local_data_name}_http_response_code"] = response_code
        end

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
    end
  end

  def run_request(config)
    from = config[:from]
    to = config[:to]

    case method_from_config(config)
    when 'get'
      pull_data(from)
    when 'post'
      post_data(to, config[:form])
    else
      raise FphsException, "pull_external_data method '#{http_method}' is not supported"
    end
  end

  def pull_data(config)
    url = url_from_config(config)
    response = Net::HTTP.get_response(URI.parse(url))
    handle_response(config, response)
  end

  def post_data(config, form)
    url = url_from_config(config)
    form ||= {}
    response = Net::HTTP.post_form(URI.parse(url), form)
    handle_response(config, response)
  end

  def handle_response(config, response)
    url = url_from_config(config)
    http_method = method_from_config(config)
    allow_empty_result = config[:allow_empty_result]
    allow_response_codes = config[:allow_response_codes] || []
    format = config[:format]

    self.response_code = response.code.to_i

    unless response_code == 200
      return if response_code&.in?(allow_response_codes)

      raise FphsException,
            "#{http_method} external data: failed request with code '#{response_code}' from url #{url}"
    end

    content = response.body

    if content.blank?
      return if allow_empty_result

      raise FphsException, "#{http_method} external data: empty content received from #{url}"
    end

    case format
    when 'xml'
      data = Hash.from_xml(content)
    when 'json'
      data = JSON.parse(content)
    when 'text'
      data = content
    end

    data
  end

  def url_from_config(config)
    url = config[:url]
    Formatter::Substitution.substitute(url, data: @item, ignore_missing: false)
  end

  def method_from_config(config)
    config[:method] || 'get'
  end
end
