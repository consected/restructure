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
        vals = {}

        data = pull_data config[:from]

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        vals[data_field] = data
        vals[response_code_field] = response_code if response_code_field

        # Retain the flags so that the #update! doesn't change
        # what we need to report through the API
        res = @item
        created = res._created
        updated = res._updated
        disabled = res._disabled
        @item.transaction do
          res.ignore_configurable_valid_if = true if config[:force_not_valid]
          res.force_save! if config[:force_not_editable_save]
          res.update! vals.merge(current_user: @item.current_user || @item.user)
        end
        res._created = created
        res._updated = updated
        res._disabled = disabled
      end
    end
  end

  def pull_data(config)
    url = config[:url]
    format = config[:format]
    allow_empty_result = config[:allow_empty_result]
    allow_response_codes = config[:allow_response_codes] || []

    url = Formatter::Substitution.substitute(url, data: @item, ignore_missing: false)

    response = Net::HTTP.get_response(URI.parse(url))

    self.response_code = response.code.to_i

    unless response_code == 200
      return if response_code&.in?(allow_response_codes)

      raise FphsException, "Pull external data: failed request with code '#{response_code}' from url #{url}"
    end

    content = response.body

    if content.blank?
      return if allow_empty_result

      raise FphsException, "Pull external data: empty content received from #{url}"
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
end
