# frozen_string_literal: true

#
# Helper methods for generating API documentation in admin definition panels.
# Used by the admin/common/_api_panel.html.erb partial to display REST API endpoints,
# curl examples, field definitions, and save trigger usage for dynamic definitions and reports.
module AdminApiDefinitionsHelper
  # Standard fields that should be excluded from API field listings
  STANDARD_FIELDS = %w[id created_at updated_at contactid user_id master_id].freeze

  #
  # Generate the base API path for a definition instance.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [String] the base path (e.g., "/masters/{{master_id}}/dynamic_model/contact_infos")
  def api_base_path(object_instance)
    segments = object_instance.base_route_segments
    if api_master_nested?(object_instance)
      "/masters/{{master_id}}/#{segments}"
    else
      "/#{segments}"
    end
  end

  #
  # Check if the resource is nested under /masters/
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [Boolean]
  def api_master_nested?(object_instance)
    if object_instance.respond_to?(:foreign_key_name)
      object_instance.foreign_key_name.present?
    else
      # Activity logs and external identifiers are always master-nested
      true
    end
  end

  #
  # Generate API endpoint definitions for a resource.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [Array<Hash>] list of endpoint definitions with :method, :path, :description keys
  def api_endpoints(object_instance)
    base = api_base_path(object_instance)
    endpoints = [
      { method: 'GET', path: "#{base}.json", description: 'Index (list all)' },
      { method: 'GET', path: "#{base}/{id}.json", description: 'Read (show one)' },
      { method: 'POST', path: "#{base}.json", description: 'Create' },
      { method: 'PUT', path: "#{base}/{id}.json", description: 'Update' }
    ]

    # Activity logs have extra_log_type sub-routes
    if object_instance.is_a?(ActivityLog)
      object_instance.option_configs_names&.each do |elt_name|
        next if elt_name.in?(%i[primary blank_log])

        endpoints << { method: 'POST', path: "#{base}/#{elt_name}.json",
                       description: "Create (#{elt_name})" }
        endpoints << { method: 'GET', path: "#{base}/#{elt_name}/{id}.json",
                       description: "Read (#{elt_name})" }
      end
    end

    endpoints
  end

  #
  # Generate the user-facing fields list, excluding standard fields.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [Array<Hash>] list of field definitions with :name and :type keys
  def api_fields(object_instance)
    return [] unless object_instance.respond_to?(:table_columns) && object_instance.table_or_view_ready?

    object_instance.table_columns.filter_map do |col|
      next if col.name.in?(STANDARD_FIELDS)

      { name: col.name, type: col.type.to_s }
    end
  end

  #
  # Generate an unordered list of fields and types for display.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [String]
  def api_fields_list(object_instance)
    res = '<ul class="api-panel__fields-list">'
    api_fields(object_instance).each do |f|
      res += "<li><code>#{f[:name]}</code>: #{f[:type]}</li>"
    end
    res += '</ul>'
    res.html_safe
  end

  #
  # Generate a YAML-like string of fields and types for display.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [String]
  def api_fields_yaml(object_instance)
    api_fields(object_instance).map do |f|
      "#{f[:name]}:\n  type: #{f[:type]}"
    end.join("\n")
  end

  #
  # Generate a sample JSON body with field names and placeholder values
  # for use in curl examples.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [String] JSON-formatted body string
  def api_sample_json_body(object_instance)
    fields = api_fields(object_instance)
    return '{}' if fields.empty?

    pairs = fields.map do |f|
      value = case f[:type]
              when 'integer', 'bigint' then '0'
              when 'float', 'decimal' then '0.0'
              when 'boolean' then 'false'
              when 'date' then '"YYYY-MM-DD"'
              when 'datetime' then '"YYYY-MM-DDTHH:MM:SS"'
              else '""'
              end
      "  \"#{f[:name]}\": #{value}"
    end

    "{\n#{pairs.join(",\n")}\n}"
  end

  #
  # Generate a curl example for a given HTTP method and path.
  # @param method [String] HTTP method (GET, POST, PUT)
  # @param path [String] the API path
  # @param body [String, nil] optional JSON body
  # @return [String] the curl command
  def api_curl_example(method:, path:, body: nil)
    curl = <<~CURL.chomp
      curl -X#{method} -H "Content-Type: application/json" \\
      "{{base_url}}"\\
      "#{path}"\\
      "?use_app_type={{app_type_id}}&user_email={{user_email}}&user_token={{api_token}}"
    CURL
    curl += " \\\n  -d '\n#{body}\n'" if body.present?
    curl
  end

  #
  # Generate a curl example for a report GET endpoint.
  # @param report [Report] the report record
  # @param format [String] the format extension ('json', 'csv', 'txt')
  # @param sa [String] the search attributes query string (already encoded)
  # @return [String] the curl command
  def api_report_curl_example(report, format:, sa:)
    <<~CURL.chomp
      curl -XGET -H "Content-Type: application/json" \\\
      "{{base_url}}"\\\
      "/reports/#{report.alt_resource_name}.#{format}"\\\
      "?#{sa}"\\\
      "&use_app_type={{app_type_id}}&user_email={{user_email}}&user_token={{api_token}}"
    CURL
  end

  #
  # Generate save trigger YAML usage example for a report's pull_external_data GET.
  # @param report [Report] the report record
  # @param sa [String] the search attributes query string (already encoded)
  # @return [String] YAML-formatted save trigger example
  def api_report_save_trigger_example(report, sa:)
    <<~YAML
      _constants:
        api_user_email: {{user_email}}
        api_app_type: {{app_type_id}}
        api_shared_secret: {{api_token}}

      default:
        save_trigger:
          on_create:

            - pull_external_data:
              - get_report:
                  local_data: get_result
                  from:
                    url: "{{base_url}}/reports/#{report.alt_resource_name}.json?#{sa}&use_app_type={{constants.api_app_type}}&user_email={{constants.api_user_email}}&user_token={{constants.api_shared_secret}}"
                    format: json
                    allow_empty_result: false
    YAML
  end

  #
  # Generate save trigger YAML usage example for pull_external_data.
  # @param object_instance [DynamicModel, ActivityLog, ExternalIdentifier] the definition
  # @return [String] YAML-formatted save trigger example
  def api_save_trigger_example(object_instance)
    base = api_base_path(object_instance)
    fields = api_fields(object_instance)
    field_lines = fields.map do |f|
      value = case f[:type]
              when 'integer', 'bigint' then '0'
              when 'float', 'decimal' then '0.0'
              when 'boolean' then 'false'
              else '""'
              end
      "              #{f[:name]}: #{value}"
    end.join("\n")

    <<~YAML
      _constants:
        api_user_email: {{user_email}}
        api_app_type: {{app_type_id}}
        api_shared_secret: {{api_token}}
        master_id: {master_id}
        item_id: {item_id}

      default:
        save_trigger:
          on_create:

            - pull_external_data:
              - get_record:
                  local_data: get_result
                  from:
                    url: "{{base_url}}#{base}/{{constants.item_id}}.json?use_app_type={{constants.api_app_type}}&user_email={{constants.api_user_email}}&user_token={{constants.api_shared_secret}}"
                    format: json
                    allow_empty_result: false

            - pull_external_data:
              - create_record:
                  force_not_editable_save: true
                  local_data: create_result
                  to:
                    url: "{{base_url}}#{base}.json?use_app_type={{constants.api_app_type}}&user_email={{constants.api_user_email}}&user_token={{constants.api_shared_secret}}"
                    format: json
                    allow_empty_result: false
                    headers:
                      'Content-Type': 'application/json'

                  post_data:
      #{field_lines}
    YAML
  end
end
