# frozen_string_literal: true

class SaveTriggers::PullExternalData < SaveTriggers::SaveTriggersBase
  def self.config_def(if_extras: {})
    #     this_1:
    #       if: if_extras
    #       force_not_editable_save: true allows the update to succeed even if this item is set as not_editable
    #       data_field: name of json field to update
    #       from:
    #         url: 'url with substitutions',
    #         format: xml|json|text
    #         allow_empty_result: true | false (default)
  end

  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      model_def.each do |_model_name, config|
        vals = {}

        data = pull_data config[:from]

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        fn = config[:data_field]
        vals[fn] = data

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

    url = Formatter::Substitution.substitute(url, data: @item, ignore_missing: false)

    content = Net::HTTP.get(URI.parse(url))

    if content.blank? && !allow_empty_result
      raise FphsException,
            "Pull external data: empty content received from #{url}"
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
