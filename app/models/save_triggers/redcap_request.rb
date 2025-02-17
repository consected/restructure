# frozen_string_literal: true

class SaveTriggers::RedcapRequest < SaveTriggers::SaveTriggersBase
  attr_accessor :response_code, :content

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
        success_if = config[:success_if]
        vals = {}

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        @this_config = config
        data = run_request
        orig_data = data

        if data_field
          data = data&.to_json if data_field_format == 'json'
          vals[data_field] = data
        end

        vals[response_code_field] = response_code if response_code_field
        if local_data_name
          @item.save_trigger_results[local_data_name] = orig_data
          @item.save_trigger_results["#{local_data_name}_http_response_code"] = response_code
        end

        # We calculate the conditional if inside each item, rather than relying
        # on the outer processing in ActivityLogOptions#calc_save_trigger_if
        success_if_res = nil
        if success_if
          ca = ConditionalActions.new success_if, @item
          success_if_res = !!ca.calc_action_if
          @item.save_trigger_results["#{local_data_name}_success_if_res"] = success_if_res if local_data_name
        end
        
        logmsg = "redcap_request #{method_from_config} -> #{study_name_pair} = response code #{response_code} " \
                 "&& success_if_res #{success_if_res}"
        if response_code == 200 && success_if_res != false
          Rails.logger.info logmsg
        else
          Rails.logger.warn logmsg
        end

        next unless vals.present?

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

  def run_request study:, project_name:
    data = post_data_config

    rc = Redcap::ProjectAdmin.active.find_by(study:, project_name:)
    rc.current_admin = @admin
    pc = rc.api_client

    res = pc.send method_from_config, **request_data
    self.response_code = pc.response_code
    self.content = res
    handle_response(to_config, response)
  end

  def request_data
    data = post_data_config || {}
    if data.is_a? Hash
      data = data.deep_stringify_keys
      data = data.deep_transform_values { |v| FieldDefaults.calculate_default @item, v }
      data = data.to_json
    else
      data = FieldDefaults.calculate_default @item, data
    end
    data
  end  

  def handle_response(sub_config, response)    
    rc_method = method_from_config
    allow_empty_result = sub_config[:allow_empty_result]
    allow_response_codes = sub_config[:allow_response_codes] || []    

    unless response_code == 200
      return if response_code&.in?(allow_response_codes)

      raise FphsException,
            "#{rc_method} external data: failed request with code '#{response_code}' from project #{study_name_pair}"
    end
  end

  def project_name
    @this_config[:project_name]
  end

  def study
    @this_config[:study]
  end

  def study_name_pair
    "#{study} / #{project_name}"
  end

  def method_from_config
    @this_config[:method]
  end

  def post_data_config
    @this_config[:post_data]
  end

end
