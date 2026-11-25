# frozen_string_literal: true

# Purpose: Verify every in-repository legacy report configuration still loads and reads back its registered options.

require 'rails_helper'

module ReportOptionsExistingConfigAudit
  LEGACY_REPORT_TYPES = %w[regular_report search count].freeze
  REPORT_COLLECTION_KEYS = %w[associated_reports reports _reports].freeze
  REPORT_ATTRIBUTES = %w[
    name description sql search_attrs disabled report_type auto searchable position
    edit_model edit_field_names selection_fields item_type short_name options
  ].freeze

  # Entries require a verified source exception and must be listed in the final audit report.
  ALLOWED_OPTION_CONFIG_ANOMALIES = {}.freeze
end

RSpec.describe 'report options in existing app configurations', type: :model do
  it 'loads all in-repository reports without changing recognized option values' do
    failures = []
    seen_anomalies = []
    report_count = 0

    in_repo_app_config_files.each do |file_path|
      config = load_config_file(file_path)
      report_definitions(config).each do |report_definition, location|
        report_count += 1
        source = "#{file_path.relative_path_from(Rails.root)} #{location.join(' > ')}"
        report_type = report_definition['report_type']
        unless ReportOptionsExistingConfigAudit::LEGACY_REPORT_TYPES.include?(report_type)
          failures << "#{source}: unexpected legacy report type #{report_type.inspect}"
          next
        end

        report = Report.new(report_definition.slice(*ReportOptionsExistingConfigAudit::REPORT_ATTRIBUTES))
        option_text = report_definition['options']
        parsed_options = parse_options_text(option_text)
        unless parsed_options.is_a?(Hash)
          failures << "#{source}: options did not parse to a hash"
          next
        end

        begin
          options = report.report_options
        rescue StandardError => e
          failures << "#{source}: report_options raised #{e.class}: #{e.message}"
          next
        end

        failures << "#{source}: configuration audit unexpectedly persisted the report" unless report.new_record?

        errors = Array(options.config_errors).map { |error| error[:message] }.compact
        allowed_errors = ReportOptionsExistingConfigAudit::ALLOWED_OPTION_CONFIG_ANOMALIES[source]
        if errors.present?
          if allowed_errors == errors
            seen_anomalies << source
          else
            failures << "#{source}: unexpected config_errors #{errors.inspect}"
          end
        elsif allowed_errors.present?
          failures << "#{source}: stale anomaly allow-list entry #{allowed_errors.inspect}"
        end

        begin
          OptionConfigs::ReportOptions.raise_bad_configs(options)
        rescue StandardError => e
          failures << "#{source}: raise_bad_configs raised #{e.class}: #{e.message}"
        end

        compare_registered_options(options, parsed_options, source, failures)
      end
    end

    failures << 'No reports were found in the repository configuration files' if report_count.zero?
    unobserved_anomalies = ReportOptionsExistingConfigAudit::ALLOWED_OPTION_CONFIG_ANOMALIES.keys - seen_anomalies
    failures << "Unobserved anomaly allow-list entries: #{unobserved_anomalies.inspect}" if unobserved_anomalies.any?

    expect(failures).to be_empty, failures.join("\n")
  end

  private

  # Scope the audit to this repository; sibling configuration repositories are absent in CI.
  def in_repo_app_config_files
    config_directories = [
      Rails.root.join('db/app_configs'),
      Rails.root.join('spec/fixtures/app_configs/config_files')
    ]

    config_directories.flat_map do |directory|
      Dir.children(directory).filter_map do |filename|
        path = directory.join(filename)
        path if path.file? && %w[.yaml .yml .json].include?(path.extname)
      end
    end.sort
  end

  def load_config_file(path)
    if path.extname == '.json'
      JSON.parse(path.read)
    else
      YAML.safe_load(path.read, permitted_classes: [Date, Time], permitted_symbols: [], aliases: true)
    end
  end

  def report_definitions(config, in_report_collection: false, location: [], found: [])
    case config
    when Hash
      if in_report_collection && config.key?('name') && config.key?('sql')
        found << [config, location]
      else
        config.each do |key, value|
          report_definitions(
            value,
            in_report_collection: in_report_collection || ReportOptionsExistingConfigAudit::REPORT_COLLECTION_KEYS.include?(key.to_s),
            location: location + [key.to_s],
            found:
          )
        end
      end
    when Array
      config.each_with_index do |value, index|
        report_definitions(value, in_report_collection:, location: location + [index.to_s], found:)
      end
    end

    found
  end

  def parse_options_text(text)
    return {} if text.blank?
    return text if text.is_a?(Hash)

    begin
      JSON.parse(text)
    rescue JSON::ParserError
      YAML.safe_load(text, permitted_classes: [Date, Time], permitted_symbols: [], aliases: true) || {}
    end
  end

  def compare_registered_options(options, parsed_options, source, failures)
    registered_sections = OptionConfigs::ReportOptions.option_types.values.flatten.map(&:to_s)
    unknown_sections = parsed_options.keys.map(&:to_s) - registered_sections
    failures << "#{source}: unrecognized option sections #{unknown_sections.inspect}" if unknown_sections.any?

    OptionConfigs::ReportOptions.option_types[:multi].each do |section|
      raw_section = parsed_options[section.to_s]
      next unless raw_section.is_a?(Hash)

      configuration_class = OptionConfigs::ReportOptions.const_get(section.to_s.camelize)
      expected = raw_section.each_with_object({}) do |(key, value), recognized|
        symbol_key = key.to_sym
        recognized[symbol_key] = value if configuration_class.configure_with_items.include?(symbol_key)
      end
      actual = options.public_send(section).to_h.slice(*expected.keys)
      next if actual == expected

      failures << "#{source}: #{section} registered values differ; expected #{expected.inspect}, got #{actual.inspect}"
    end
  end
end
