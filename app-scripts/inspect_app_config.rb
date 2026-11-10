#!/usr/bin/env ruby
# frozen_string_literal: true

# inspect_app_config.rb — analyse an app-type YAML config file.
#
# Usage (from workspace root):
#
#   ruby app-scripts/inspect_app_config.rb [options] [search_term ...]
#
# Options:
#   --config PATH        Path to the YAML config file (default: db/app_configs/play-ipa_config - production.yaml)
#   --diff               Show fields referenced in config options but absent from _db_columns / field_list
#   --db-columns         Show _db_columns for each matching model
#   --options            Show the full parsed options hash for each matching model
#   --sections KEY       Show only the given top-level options section(s), e.g. --sections caption_before,show_if
#   --compare-git REF    Compare current config against a git ref (e.g. HEAD~1, a commit SHA)
#   --compare PATH       Compare current config against another YAML file
#   --class TYPE     Filter by _class_name (e.g. DynamicModel, ActivityLog, ExternalIdentifier)
#   --errors FILE    Read a config-errors log file and extract unique model table names to inspect
#   --page-layouts   List page layout panels (Admin::PageLayout): layout/panel name,
#                    position, contains.resources/categories, tab and view_options
#   --access-controls  List user access controls (Admin::UserAccessControl):
#                    resource_type, resource_name, access level and role_name
#   --help           Show this help
#
# Examples:
#   # Show field diff for a specific model
#   ruby app-scripts/inspect_app_config.rb --diff play_ipa_four_wk_followup
#
#   # Show all models with "phone_screen" in the name and their referenced vs. declared fields
#   ruby app-scripts/inspect_app_config.rb --diff phone_screen
#
#   # Inspect models mentioned in the last error log
#   ruby app-scripts/inspect_app_config.rb --diff --errors tmp/agent-tmp/config_errors_play-ipa.log
#
#   # Show just the show_if and caption_before sections for a model
#   ruby app-scripts/inspect_app_config.rb --sections show_if,caption_before play_ipa_initial_call
#
#   # List the master page layout panels and what each contains
#   ruby app-scripts/inspect_app_config.rb --config "...projects_config.yaml" --page-layouts
#
#   # Show access controls that mention data_request_assignments
#   ruby app-scripts/inspect_app_config.rb --config "...projects_config.yaml" --access-controls data_request

require 'yaml'
require 'optparse'
require 'shellwords'

# Ensure the config inspection script always loads all active app types, even if the
# parent shell has no explicit FPHS_LOAD_APP_TYPES setting.
ENV['FPHS_LOAD_APP_TYPES'] = '-1'

require_relative '../config/environment'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Recursively collect all *hash keys* from a nested structure.
def collect_keys(obj, result = Set.new)
  case obj
  when Hash
    obj.each do |k, v|
      result << k.to_s if k.to_s =~ /\A[a-z_]/
      collect_keys(v, result)
    end
  when Array
    obj.each { |v| collect_keys(v, result) }
  end
  result
end

# Recursively collect only the *top-level keys* of a hash (field names used
# as keys directly inside a config section like caption_before or show_if).
def top_level_field_keys(obj)
  return Set.new unless obj.is_a?(Hash)

  obj.keys.to_set(&:to_s)
end

# Build a YAML preamble from config library options texts so that anchor
# definitions are in scope when parsing individual model options strings.
# @param app_type [Hash] parsed outer app_type hash
# @return [String] combined preamble text (safe to prepend to any options string)
def build_library_preamble(app_type)
  libs = Array(app_type['associated_config_libraries'])
  libs.map { |l| normalize_options_text(l['options'].to_s) }.join("\n")
end

# Return the raw options text for a model record, using the correct attribute
# based on the model type. ActivityLog records store their configuration in
# `extra_log_types`; all other model types use `options`.
def record_options_text(rec)
  raw = rec['options']
  return raw unless raw.to_s.strip.empty?

  rec['extra_log_types']
end

# Strip YAML anchor aliases and merge-key aliases from options text so that
# anchors defined in external standard-option-definition files (e.g. *is_blank,
# *never) do not cause parse errors and their _definitions__* wrapper keys do
# not pollute the parsed result. Alias references are replaced with null;
# merge-key aliases are replaced with an empty mapping.
# Anchor definition tags (&name) are removed but the associated value is kept.
def strip_anchor_refs(text)
  text
    .gsub(/^[^\S\n]*<<:.*\n/, '') # remove merge-key lines entirely
    .gsub(/\*[A-Za-z_][A-Za-z0-9_]*/, 'null') # alias refs → null
    .gsub(/(?<=[: \t])&[A-Za-z_][A-Za-z0-9_]*(?=\s|$)/, '') # anchor defs – remove tag
end

# Normalise raw options text: strip Windows-style CR+LF and bare CR to plain LF.
# The outer YAML.safe_load_file already decodes \n / \r\n escape sequences in
# double-quoted strings, so we only need to normalise actual CR characters that
# appear in the decoded value (common in library options stored with \r\n endings).
def normalize_options_text(text)
  # Normalise line endings, then strip any leading YAML document-start marker
  # (---) so that prepending the library preamble does not create a
  # multi-document stream.  YAML::safe_load only reads the *first* document,
  # which would be the preamble, causing the model's actual options to be lost.
  text.gsub("\r\n", "\n").gsub("\r", "\n").sub(/\A---\s*\n/, '')
end

# Parse the inner options YAML string for a single model record.
# Prepends library preamble so that cross-library anchors are resolved.
# Returns the parsed Hash or nil on failure.
def parse_options(raw, preamble = '')
  if raw.nil? || raw.to_s.strip.empty?
    puts '  (no options provided)'
    return nil
  end

  # Strip anchor aliases and definitions from the model options text so that
  # external anchors (e.g. *is_blank from standard option defs) don't cause
  # parse errors and _definitions__* wrapper keys don't pollute the result.
  text = normalize_options_text(raw.to_s)

  combined = preamble.empty? ? text : "#{preamble}\n#{text}"
  combined = strip_anchor_refs(combined)
  result = attempt_yaml_parse(combined)
  return result if result && !result.to_s.strip.empty?

  # Fallback: try without preamble
  result = attempt_yaml_parse(strip_anchor_refs(text))
  if result.nil? || result.to_s.strip.empty?
    puts '  (no options after parsing YAML)'
    return nil
  end
  result
end

def attempt_yaml_parse(text)
  YAML.safe_load(text, permitted_classes: [Symbol], aliases: true)
rescue Psych::Exception => e
  puts "  (YAML parse error: #{e.message})"
  nil
end

# Extract the default: sub-hash from a parsed options hash (or the hash itself
# when there is no top-level "default" wrapper).
def default_section(parsed)
  return nil unless parsed.is_a?(Hash)

  parsed['default'] || parsed[:default] || parsed
end

# Collect field names referenced as top-level keys inside any of the named
# config sections (caption_before, show_if, field_options, labels, …).
OPTION_SECTIONS = %w[caption_before show_if field_options labels dialog_before
                     preset_fields references db_configs].freeze

def referenced_fields(default_h)
  return Set.new unless default_h.is_a?(Hash)

  result = Set.new
  OPTION_SECTIONS.each do |section|
    next unless default_h.key?(section)

    result.merge(top_level_field_keys(default_h[section]))
  end
  result
end

# ---------------------------------------------------------------------------
# Config diff helper  (used with --compare-git / --compare)
# ---------------------------------------------------------------------------

# Recursively stringify all keys so Symbol vs String key mismatches don't
# cause false positives when comparing two parsed-YAML hashes.
def deep_stringify_keys(obj)
  case obj
  when Hash  then obj.transform_keys(&:to_s).transform_values { |v| deep_stringify_keys(v) }
  when Array then obj.map { |v| deep_stringify_keys(v) }
  else            obj
  end
end

# Returns true when there are any meaningful differences between the two
# model records (used to implement --only-changed).
def config_changed?(new_rec, new_parsed, old_rec, old_preamble, new_preamble = '')
  new_fl = new_rec['field_list'].to_s.split.to_set
  old_fl = old_rec ? old_rec['field_list'].to_s.split.to_set : Set.new
  return true if new_fl != old_fl

  old_raw = old_rec ? record_options_text(old_rec) : nil
  old_parsed = old_rec ? (parse_options(old_raw.to_s, old_preamble) || parse_options(old_raw.to_s, new_preamble)) : nil
  new_dbc = deep_stringify_keys(new_parsed.is_a?(Hash) ? (new_parsed['_db_columns'] || new_parsed[:_db_columns] || {}) : {})
  old_dbc = deep_stringify_keys(old_parsed.is_a?(Hash) ? (old_parsed['_db_columns'] || old_parsed[:_db_columns] || {}) : {})
  return true if new_dbc.keys.to_set != old_dbc.keys.to_set

  new_def = deep_stringify_keys(default_section(new_parsed) || {})
  old_def = deep_stringify_keys(default_section(old_parsed) || {})
  OPTION_SECTIONS.any? { |s| (new_def[s] || {}) != (old_def[s] || {}) }
end

def print_config_diff(new_rec, new_parsed, old_rec, old_preamble, new_preamble = '')
  # ---- field_list diff ----
  new_fl = new_rec['field_list'].to_s.split.to_set
  old_fl = old_rec ? old_rec['field_list'].to_s.split.to_set : Set.new
  fl_added   = new_fl - old_fl
  fl_removed = old_fl - new_fl

  if fl_added.any? || fl_removed.any?
    puts '  field_list changes:'
    fl_added.sort.each   { |f| puts "    + #{f}" }
    fl_removed.sort.each { |f| puts "    - #{f}" }
  end

  # ---- options diff ----
  old_raw = old_rec ? record_options_text(old_rec) : nil
  old_parsed = old_rec ? (parse_options(old_raw.to_s, old_preamble) || parse_options(old_raw.to_s, new_preamble)) : nil
  new_def = deep_stringify_keys(default_section(new_parsed) || {})
  old_def = deep_stringify_keys(default_section(old_parsed) || {})

  # _db_columns diff
  new_dbc = deep_stringify_keys(new_parsed.is_a?(Hash) ? (new_parsed['_db_columns'] || new_parsed[:_db_columns] || {}) : {})
  old_dbc = deep_stringify_keys(old_parsed.is_a?(Hash) ? (old_parsed['_db_columns'] || old_parsed[:_db_columns] || {}) : {})
  dbc_added   = new_dbc.keys.to_set - old_dbc.keys.to_set
  dbc_removed = old_dbc.keys.to_set - new_dbc.keys.to_set
  if dbc_added.any? || dbc_removed.any?
    puts '  _db_columns changes:'
    dbc_added.sort.each   { |f| puts "    + #{f}" }
    dbc_removed.sort.each { |f| puts "    - #{f}" }
  end

  # Per-section diff  (keys are already strings after deep_stringify_keys)
  OPTION_SECTIONS.each do |section|
    new_s = new_def[section] || {}
    old_s = old_def[section] || {}
    next if new_s == old_s

    new_keys = new_s.is_a?(Hash) ? new_s.keys.to_set : Set.new
    old_keys = old_s.is_a?(Hash) ? old_s.keys.to_set : Set.new
    added   = new_keys - old_keys
    removed = old_keys - new_keys
    changed = (new_keys & old_keys).reject { |k| new_s[k] == old_s[k] }

    next unless added.any? || removed.any? || changed.any?

    puts "  #{section} changes:"
    added.sort.each   { |k| puts "    + #{k}: #{new_s[k].inspect}" }
    removed.sort.each { |k| puts "    - #{k}: #{old_s[k].inspect}" }
    changed.sort.each do |k|
      puts "    ~ #{k}:"
      puts "        was: #{old_s[k].inspect}"
      puts "        now: #{new_s[k].inspect}"
    end
  end
end

# ---------------------------------------------------------------------------
# Page layout / access control reporting  (--page-layouts / --access-controls)
# ---------------------------------------------------------------------------

# Compile a case-insensitive OR pattern from search terms, or nil when none.
def build_search_pattern(search_terms)
  return nil if search_terms.empty?

  Regexp.new(search_terms.map { |t| Regexp.escape(t) }.join('|'), Regexp::IGNORECASE)
end

# Report on Admin::PageLayout records: the panels that make up the master,
# nav and view layouts, including what resources/categories each panel
# contains and its view_options. The page layout `options` is a plain YAML
# string (no cross-library anchors), so it parses directly.
def report_page_layouts(app_type, search_terms)
  layouts = %w[page_layouts valid_page_layouts associated_page_layouts]
            .flat_map { |key| Array(app_type[key]) }
  if layouts.empty?
    puts 'No page_layouts found in config.'
    return
  end

  pattern = build_search_pattern(search_terms)
  matched = layouts.select do |pl|
    next true unless pattern

    hay = [pl['panel_name'], pl['layout_name'], pl['panel_label'], pl['options']].compact.join("\n")
    pattern.match?(hay)
  end

  puts "Found #{matched.size} page layout panel(s)#{" matching: #{search_terms.join(', ')}" if pattern}\n\n"

  matched.sort_by { |pl| [pl['layout_name'].to_s, pl['panel_position'].to_i] }.each do |pl|
    opts = attempt_yaml_parse(normalize_options_text(pl['options'].to_s)) || {}
    opts = {} unless opts.is_a?(Hash)
    contains     = opts['contains'] || {}
    view_options = opts['view_options'] || {}
    tab          = opts['tab'] || {}

    disabled_flag = pl['disabled'] ? ', DISABLED' : ''
    puts '=' * 72
    puts "#{pl['layout_name']} / #{pl['panel_name']}  (position #{pl['panel_position']}#{disabled_flag})"
    puts "  label: #{pl['panel_label']}" unless pl['panel_label'].to_s.empty?
    puts '=' * 72

    resources  = Array(contains['resources']).compact
    categories = Array(contains['categories']).compact
    puts "  contains.resources:  #{resources.empty? ? '(none)' : resources.join(', ')}"
    puts "  contains.categories: #{categories.join(', ')}" unless categories.empty?
    puts "  tab.parent: #{tab['parent']}" if tab.is_a?(Hash) && !tab['parent'].to_s.empty?

    if view_options.is_a?(Hash)
      shown = view_options.reject { |_k, v| v.nil? || v.to_s.strip.empty? }
      unless shown.empty?
        puts '  view_options:'
        shown.each { |k, v| puts "    #{k}: #{v}" }
      end
    end
    puts
  end
end

# Report on Admin::UserAccessControl records: which roles have which access
# level to each resource. Filtered by search terms matching resource_type,
# resource_name or role_name.
def report_access_controls(app_type, search_terms)
  controls = %w[user_access_controls valid_user_access_controls associated_user_access_controls]
             .flat_map { |key| Array(app_type[key]) }
  if controls.empty?
    puts 'No user access controls found in config.'
    return
  end

  pattern = build_search_pattern(search_terms)
  matched = controls.select do |ac|
    next true unless pattern

    hay = [ac['resource_type'], ac['resource_name'], ac['role_name']].compact.join(' ')
    pattern.match?(hay)
  end

  puts "Found #{matched.size} access control(s)#{" matching: #{search_terms.join(', ')}" if pattern}\n\n"
  fmt = "  %-18<type>s %-52<name>s %-10<access>s %-28<role>s %<disabled>s\n"
  printf(fmt, type: 'TYPE', name: 'RESOURCE', access: 'ACCESS', role: 'ROLE', disabled: 'DISABLED')

  matched
    .sort_by { |ac| [ac['resource_type'].to_s, ac['resource_name'].to_s, ac['role_name'].to_s] }
    .each do |ac|
      access = ac['access']
      access = access.map { |k, v| "#{k}:#{v}" }.join(',') if access.is_a?(Hash)
      printf(fmt,
             type: ac['resource_type'].to_s,
             name: ac['resource_name'].to_s,
             access: access.to_s,
             role: ac['role_name'].to_s,
             disabled: ac['disabled'] ? 'yes' : '')
    end
  puts
end

# ---------------------------------------------------------------------------
# Validation helper for app-side config schema checks
# ---------------------------------------------------------------------------

def record_model_class(record)
  klass_name = record.is_a?(Hash) ? (record['_class_name'] || record[:_class_name]) : nil
  case klass_name.to_s
  when 'DynamicModel' then DynamicModel
  when 'ActivityLog' then ActivityLog
  when 'ExternalIdentifier' then ExternalIdentifier
  else
    nil
  end
end

def object_blank?(value)
  case value
  when nil
    true
  when String
    value.strip.empty?
  when Hash, Array
    value.empty?
  else
    value.respond_to?(:empty?) ? value.empty? : false
  end
end

def format_validation_notice(_record, notice)
  type = notice.is_a?(Hash) ? notice[:type].to_s : notice.to_s
  message = notice.is_a?(Hash) ? notice[:message].to_s : notice.to_s
  "ERROR: #{type}: #{message}"
end

def validate_option_config_record(record)
  return [] if object_blank?(record)

  klass = record_model_class(record)
  return [] unless klass

  config_obj = klass.new
  record_hash = record.to_h.deep_stringify_keys
  record_hash.delete('_class_name')

  allowed_attrs = %w[
    name table_name schema_name category field_list options extra_log_types disabled
  ].freeze

  safe_attrs = record_hash.each_with_object({}) do |(key, value), attrs|
    next if key.to_s.empty?
    next unless allowed_attrs.include?(key)

    attrs[key] = value
  end

  config_obj.assign_attributes(safe_attrs)
  notices = OptionConfigs::ExtraOptions.all_option_configs_notices(config_obj)
  return [] if notices.nil? || notices.empty?

  notices.map do |notice|
    next notice if object_blank?(notice)

    normalized = notice.to_h.deep_symbolize_keys
    normalized[:type] = normalized[:type].to_s.to_sym if normalized[:type].respond_to?(:to_s)
    normalized
  end
rescue StandardError => e
  [{
    type: :parse_error,
    message: e.message,
    config_object: record,
    extra_details: e.backtrace&.first(10)
  }]
end

# ---------------------------------------------------------------------------
# CLI option parsing
# ---------------------------------------------------------------------------

if $PROGRAM_NAME == __FILE__
  options = {
    config: 'db/app_configs/play-ipa_config - production.yaml',
    diff: false,
    db_cols: false,
    full: false,
    sections: nil,
    class_filter: nil,
    errors_file: nil,
    compare_git: nil,
    compare_path: nil,
    only_changed: false,
    page_layouts: false,
    access_controls: false,
    validate_option_configs: false
  }

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: ruby app-scripts/inspect_app_config.rb [options] [search_term ...]'

    opts.on('--config PATH', 'Path to the app-type YAML config file') { |v| options[:config] = v }
    opts.on('--diff', 'Show fields in config options not in _db_columns / field_list') { options[:diff] = true }
    opts.on('--db-columns', 'Show _db_columns for matching models') { options[:db_cols] = true }
    opts.on('--options', 'Show the full parsed options hash') { options[:full] = true }
    opts.on('--sections KEYS', 'Comma-separated list of option sections to display') { |v| options[:sections] = v.split(',').map(&:strip) }
    opts.on('--class TYPE', 'Filter by _class_name') { |v| options[:class_filter] = v }
    opts.on('--errors FILE', 'Read model names from a config-errors log file') { |v| options[:errors_file] = v }
    opts.on('--compare-git REF', 'Compare config against a git ref (e.g. HEAD~1)') { |v| options[:compare_git] = v }
    opts.on('--compare PATH', 'Compare config against another YAML file') { |v| options[:compare_path] = v }
    opts.on('--only-changed', 'With --compare-git/--compare, only show models that have changes') { options[:only_changed] = true }
    opts.on('--page-layouts', 'List page layout panels (Admin::PageLayout)') { options[:page_layouts] = true }
    opts.on('--access-controls', 'List user access controls (Admin::UserAccessControl)') { options[:access_controls] = true }
    opts.on('--validate-option-configs', 'Validate matching model option text against the live ExtraOptions schema') { options[:validate_option_configs] = true }
    opts.on('--help', 'Show help') do
      puts opts
      exit
    end
  end

  search_terms = parser.parse!(ARGV)

  # ---------------------------------------------------------------------------
  # Load config
  # ---------------------------------------------------------------------------

  config_path = File.expand_path(options[:config], Dir.pwd)
  unless File.exist?(config_path)
    warn "Config file not found: #{config_path}"
    exit 1
  end

  puts "Loading config: #{config_path}"
  outer = YAML.safe_load_file(config_path, permitted_classes: [Symbol], aliases: true)
  unless outer.is_a?(Hash)
    warn 'Unexpected top-level YAML structure (expected Hash)'
    exit 1
  end

  app_type = outer['app_type'] || outer
  preamble = build_library_preamble(app_type)

  # ---------------------------------------------------------------------------
  # Page layout / access control modes short-circuit the model reporting below.
  # ---------------------------------------------------------------------------

  if options[:page_layouts]
    report_page_layouts(app_type, search_terms)
    exit 0
  end

  if options[:access_controls]
    report_access_controls(app_type, search_terms)
    exit 0
  end

  # ---------------------------------------------------------------------------
  # Load comparison config (for --compare-git / --compare)
  # ---------------------------------------------------------------------------

  compare_app_type = nil
  compare_preamble = ''

  if options[:compare_git]
    git_ref = options[:compare_git]
    # Resolve config_path relative to the git repo root
    repo_root = `git -C #{File.dirname(config_path).shellescape} rev-parse --show-toplevel 2>/dev/null`.strip
    rel_path  = config_path.sub("#{repo_root}/", '')
    raw = `git -C #{repo_root.shellescape} show #{git_ref.shellescape}:#{rel_path.shellescape} 2>/dev/null`
    if raw.empty?
      warn "Could not load config from git ref '#{git_ref}' at path '#{rel_path}'"
      exit 1
    end
    puts "Comparing against git ref: #{git_ref}"
    old_outer = YAML.safe_load(raw, permitted_classes: [Symbol], aliases: true)
    compare_app_type = old_outer.is_a?(Hash) ? (old_outer['app_type'] || old_outer) : nil
    compare_preamble = build_library_preamble(compare_app_type) if compare_app_type
  elsif options[:compare_path]
    cmp_path = File.expand_path(options[:compare_path], Dir.pwd)
    unless File.exist?(cmp_path)
      warn "Compare file not found: #{cmp_path}"
      exit 1
    end
    puts "Comparing against: #{cmp_path}"
    old_outer = YAML.safe_load_file(cmp_path, permitted_classes: [Symbol], aliases: true)
    compare_app_type = old_outer.is_a?(Hash) ? (old_outer['app_type'] || old_outer) : nil
    compare_preamble = build_library_preamble(compare_app_type) if compare_app_type
  end

  # ---------------------------------------------------------------------------
  # Extract model names from an error log (if --errors given)
  # ---------------------------------------------------------------------------

  if options[:errors_file]
    errors_path = File.expand_path(options[:errors_file], Dir.pwd)
    unless File.exist?(errors_path)
      warn "Errors file not found: #{errors_path}"
      exit 1
    end

    lines = File.readlines(errors_path)
    # Lines look like:  - [dynamic_model__play_ipa_foo__default (DynamicModel)] ...
    # or                  - [ipa_sample__default (ExternalIdentifier)] ...
    extracted = lines.flat_map do |line|
      line.scan(/\[([^\]]+)\]/).flatten
          .map { |tag| tag.split(/\s+/).first } # strip "(ClassName)"
          .map { |rn| rn.sub(/__default$/, '') } # strip trailing __default
          .map { |rn| rn.sub(/\Adynamic_model__/, '') } # strip prefix
    end.compact.uniq

    # Convert resource names back to table_names (pluralise last segment)
    search_terms.concat(extracted.map { |rn| rn.split('__').last })
    search_terms.uniq!
  end

  # ---------------------------------------------------------------------------
  # Collect all model records from the config
  # ---------------------------------------------------------------------------

  MODEL_KEYS = %w[
    dynamic_models activity_logs external_identifiers
    associated_dynamic_models associated_activity_logs associated_external_identifiers
    valid_dynamic_models valid_activity_logs valid_external_identifiers
    valid_associated_dynamic_models valid_associated_activity_logs valid_associated_external_identifiers
  ].freeze

  all_records     = MODEL_KEYS.flat_map { |key| Array(app_type[key]) }
  compare_records = compare_app_type ? MODEL_KEYS.flat_map { |key| Array(compare_app_type[key]) } : []

  if all_records.empty?
    warn "No model records found in config (looked for keys: #{MODEL_KEYS.join(', ')})"
    exit 1
  end

  # Filter by _class_name if requested
  all_records.select! { |r| r['_class_name'].to_s.include?(options[:class_filter]) } if options[:class_filter]

  # Filter by search terms (table_name or name)
  if search_terms.any?
    pattern = Regexp.new(search_terms.map { |t| Regexp.escape(t) }.join('|'), Regexp::IGNORECASE)
    all_records.select! do |r|
      pattern.match?(r['table_name'].to_s) || pattern.match?(r['name'].to_s)
    end
  end

  if all_records.empty?
    puts 'No matching models found.'
    exit 0
  end

  if options[:validate_option_configs]
    puts "Validating option schemas for #{all_records.size} matching model(s)\n\n"
    all_records.each do |rec|
      table = rec['table_name'] || rec['name']
      cls = rec['_class_name']
      label = rec['name']
      notices = validate_option_config_record(rec)
      puts "#{table}  [#{cls}]  \"#{label}\""
      if notices.nil? || notices.empty?
        puts '  OK'
      else
        notices.each do |notice|
          puts "  - #{format_validation_notice(rec, notice)}"
        end
      end
      puts
    end
    exit 0
  end

  puts "Found #{all_records.size} matching model(s)\n\n"

  # Print class coverage so missing model classes are immediately visible.
  class_counts = all_records.each_with_object(Hash.new(0)) do |record, counts|
    counts[record['_class_name'].to_s] += 1
  end

  puts 'Model class counts:'
  class_counts.sort.each do |class_name, count|
    puts "  - #{class_name}: #{count}"
  end
  puts

  # ---------------------------------------------------------------------------
  # Report each model
  # ---------------------------------------------------------------------------

  all_records.each do |rec|
    table   = rec['table_name'] || rec['name']
    cls     = rec['_class_name']
    label   = rec['name']

    raw_opts = record_options_text(rec)
    parsed   = parse_options(raw_opts, preamble)

    # When --only-changed is active, pre-check before printing anything
    if compare_app_type && options[:only_changed]
      old_rec_pre = compare_records.find { |r| (r['table_name'] || r['name']) == table }
      next unless config_changed?(rec, parsed || {}, old_rec_pre, compare_preamble, preamble)
    end

    puts '=' * 72
    puts "#{table}  [#{cls}]  \"#{label}\""
    puts '=' * 72

    if parsed.nil?
      puts '  (could not parse options)'
      puts
      next
    end

    # _db_columns
    db_cols = parsed['_db_columns']&.keys&.to_set(&:to_s) || Set.new

    if options[:db_cols] || options[:diff]
      if db_cols.any?
        puts "\n  _db_columns (#{db_cols.size}):"
        db_cols.sort.each { |c| puts "    - #{c}" }
      else
        puts "\n  _db_columns: (none declared in options)"
      end
    end

    # field_list (declared fields on the model record itself)
    field_list_str = rec['field_list'].to_s.strip
    field_list     = field_list_str.split(/\s+/).map(&:strip).reject(&:empty?).to_set

    if options[:diff]
      puts "\n  field_list (#{field_list.size} fields from record):"
      field_list.sort.each { |f| puts "    - #{f}" }
    end

    # Compute valid_fields = field_list ∪ db_cols
    valid_fields = field_list | db_cols

    # Sections to show
    def_h = default_section(parsed)

    show_sections = options[:sections] || OPTION_SECTIONS
    show_sections.each do |section|
      next unless def_h.is_a?(Hash) && def_h.key?(section)
      next unless options[:sections] || options[:diff] || options[:full]

      puts "\n  #{section}:"
      keys = top_level_field_keys(def_h[section])
      keys.sort.each do |k|
        flag = !valid_fields.include?(k) && k !~ /\Aall_fields\z|\Aplaceholder_|\A_/ ? '  ⚠  NOT in valid_fields' : ''
        puts "    #{k}#{flag}"
      end
    end

    # Diff report
    if options[:diff]
      refs = referenced_fields(def_h)
      missing = refs.reject do |f|
        valid_fields.include?(f) ||
          f.start_with?('_') ||
          f == 'all_fields' ||
          f.start_with?('placeholder_')
      end.sort

      puts "\n  Fields referenced in options but NOT in field_list or _db_columns:"
      if missing.empty?
        puts '    (none)'
      else
        missing.each { |f| puts "    *** #{f}" }
      end
    end

    # Full options dump
    if options[:full]
      puts "\n  Full parsed options:"
      puts YAML.dump(parsed)
    end

    # Compare against old config
    if compare_app_type
      old_rec = compare_records.find { |r| (r['table_name'] || r['name']) == table }
      print_config_diff(rec, parsed, old_rec, compare_preamble, preamble)
    end

    puts
  end
end
