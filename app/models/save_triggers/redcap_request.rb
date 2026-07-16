# frozen_string_literal: true

# Save trigger to make REDCap API requests
# This should match all the methods in Redcap::ProjectAdmin::ApiClient
# except #redcap and #response_code
class SaveTriggers::RedcapRequest < SaveTriggers::SaveTriggersBase
  attr_accessor :response_code, :content

  ValidMethods = %w[project project_users project_archive metadata
                    instruments records
                    survey_link survey_participants
                    import_records file arms events
                    repeating_forms_events export_logs
                    form_event_mapping export_field_names
                    remove_project_user].freeze

  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    @model_defs = config
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
          run_request
          data = content
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
  end

  def run_request
    request_data

    rc = Redcap::ProjectAdmin.active.find_by(study:, name: project_name)
    raise FphsException, "save_trigger redcap_request: cannot find REDCap project #{study} / {#{project_name}" unless rc

    rc.current_admin = rc.job_admin
    pc = rc.api_client

    res = pc.send method_from_config, **request_data
    self.response_code = pc.response_code
    self.content = res
    handle_response(request_options, res)
  end

  def request_data
    data = post_data || {}
    raise FphsException, 'save_trigger redcap_request post_data must be a Hash' unless data.is_a? Hash

    data = data.deep_symbolize_keys
    data.deep_transform_values { |v| FieldDefaults.calculate_default @item, v }
  end

  def handle_response(sub_config, _result)
    rc_method = method_from_config
    sub_config ||= {}
    sub_config[:allow_empty_result]
    allow_response_codes = sub_config[:allow_response_codes] || []

    return if response_code == 200
    return if response_code&.in?(allow_response_codes)

    raise FphsException,
          "#{rc_method} external data: failed request with code '#{response_code}' from project #{study_name_pair}"
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
    config_m = @this_config[:method]

    unless config_m.in?(ValidMethods)
      raise FphsException,
            "save_trigger redcap_request specifies an invalid method: #{config_m}"
    end

    config_m
  end

  def request_options
    @this_config[:request_options]
  end

  def post_data
    @this_config[:post_data]
  end
end
