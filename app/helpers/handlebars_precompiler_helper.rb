# frozen_string_literal: true

# Helper module for server-side Handlebars template precompilation.
# Provides cache key generation, template preprocessing, and batch CLI compilation.
#
# Workflow:
# 1. View helpers call #write_handlebars_template to write preprocessed templates to temp files
# 2. After all templates written, #compile_handlebars_templates runs single CLI call per type
# 3. CLI output is post-processed to split into individual compiled JS files
# 4. Compiled files are served from public/handlebars-{env}/ directory
#
# Thread Safety:
# Each request uses a unique request ID for its temp subdirectory to prevent
# race conditions when multiple concurrent requests are compiling templates.
module HandlebarsPrecompilerHelper
  extend ActiveSupport::Concern

  # JavaScript wrapper used by Handlebars CLI to register compiled templates
  COMPILED_HEAD = <<~ENDJS
    (function() {
      var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  ENDJS

  # Generate unique request ID for temp directory isolation.
  # Uses Thread.current to ensure each request thread gets its own ID.
  # @return [String] unique identifier for this request
  def handlebars_request_id
    @handlebars_request_id ||= SecureRandom.hex(8)
  end

  # Get request-specific temp directory for templates.
  # Each request gets isolated temp files to prevent race conditions.
  # @param is_partial [Boolean] whether this is for partials
  # @return [Pathname] path to request-specific temp directory
  def handlebars_temp_dir(is_partial:)
    base = is_partial ? HandlebarsPrecompiler::PARTIALS_TMP_DIR : HandlebarsPrecompiler::TEMPLATES_TMP_DIR
    base.join(handlebars_request_id)
  end

  # Get public directory for compiled templates or partials.
  # @param is_partial [Boolean] whether this is for partials
  # @return [Pathname] path to public directory for compiled files
  def handlebars_public_dir(is_partial:)
    is_partial ? HandlebarsPrecompiler::PARTIALS_PUBLIC_DIR : HandlebarsPrecompiler::TEMPLATES_PUBLIC_DIR
  end

  # Get URL relative path for templates or partials.
  # @param is_partial [Boolean] whether this is for partials
  # @return [String] URL relative path
  def handlebars_url_path(is_partial:)
    subdir = is_partial ? 'partials' : 'templates'
    "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}#{subdir}/"
  end

  # Generate a cache key scoped to the current user context.
  # Uses server_cache_version, item_updates from dynamic definitions,
  # the current user/admin type and id, and per-app_type access control
  # timestamps (UserRole, UserAccessControl).
  #
  # The user id is included because some cached partials (e.g. master_tabs) render
  # differently per user based on individual role/access-control grants, not just
  # app_type — so app_type alone is not sufficient to prevent cross-user cache
  # poisoning of the shared on-disk compiled file. The user/admin class name is
  # included alongside the id so a User and an Admin that happen to share the same
  # id can never collide. current_sign_in_at is deliberately NOT included, as that
  # would bust the cache on every login; role/access-control and config changes are
  # already captured via their respective updated_at timestamps.
  # @return [String] 13-character hex string (truncated SHA256)
  def handlebars_cache_key
    @handlebars_cache_key ||= begin
      ver = Application.server_cache_version
      items = handlebars_item_updates_key
      u = current_user_or_admin
      user_type = u&.class&.name
      user_id = u&.id
      app_type_id = u&.app_type_id if u.respond_to?(:app_type_id)
      userrole, uac = app_type_access_control_timestamps(app_type_id)

      # app_type_id is included directly (not just via the userrole/uac timestamps) so that
      # two different app_type contexts can never collide even if neither has any
      # UserRole/UserAccessControl rows yet (e.g. both would otherwise derive identical
      # nil-derived timestamps).
      Digest::SHA256.hexdigest("#{ver}-#{items}-#{app_type_id}-#{user_type}-#{user_id}-#{userrole}-#{uac}")[0..12]
    end
  end

  # Extract item_updates logic for cache key generation.
  # @return [String] concatenated timestamps of dynamic definitions
  def handlebars_item_updates_key
    @handlebars_item_updates_key ||= begin
      cs = [Admin::MessageTemplate, DynamicModel, ActivityLog, ExternalIdentifier,
            Admin::ConfigLibrary, Admin::PageLayout, Admin::AppConfiguration]
      cs.map { |c| c.reorder(updated_at: :desc).limit(1).pluck(:updated_at)&.first.to_i.to_s }.join('-')
    end
  end

  # Generate filename for compiled output.
  # @param template_id [String] the template identifier
  # @return [String] safe filename with cache key suffix
  def handlebars_compiled_filename(template_id)
    safe_id = template_id.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
    "#{safe_id}-#{handlebars_cache_key}.js"
  end

  # Preprocess handlebars source to convert shorthand syntax to CLI-compatible format.
  # Ports the logic from _fpa.setup_template_source in JavaScript.
  # @param source [String] the raw Handlebars template source
  # @return [String] preprocessed source ready for CLI compilation
  def preprocess_handlebars_source(source)
    return '' if source.nil?

    result = source.dup

    # Handle embedded_report and glyphicon patterns
    # {{embedded_report_name}} -> {{embedded_report 'name' true}}
    %w[embedded_report glyphicon].each do |pre|
      result.gsub!(/\{\{#{pre}_([a-zA-Z0-9_]+)\}\}/) do
        "{{#{pre} '#{::Regexp.last_match(1)}' true}}"
      end
    end

    # Handle tag_format patterns (double colon syntax)
    # {{tag::format::args}} -> {{tag_format tag 'format' 'args'}}
    result.gsub!(/\{\{([a-zA-Z0-9_]+)::([0-9a-z:_.]+)\}\}/) do
      tag = ::Regexp.last_match(1)
      parts = ::Regexp.last_match(2).split('::').map { |p| "'#{p}'" }.join(' ')
      "{{tag_format #{tag} #{parts}}}"
    end

    result
  end

  def read_handlebars_template(template_id, is_partial: false)
    public_dir = handlebars_public_dir(is_partial:)
    safe_id = template_id.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
    effective_id = is_partial ? safe_id.sub(/-partial\z/, '') : safe_id
    compiled_filename = handlebars_compiled_filename(effective_id)
    compiled_file = public_dir.join(compiled_filename)
    raise FphsException, "Compiled Handlebars template not found: #{compiled_file}" unless File.exist?(compiled_file)

    File.read(compiled_file)
  end

  # Write a template to temp file for batch compilation.
  # Template content is preprocessed before writing.
  # Uses request-specific temp directory to prevent race conditions.
  # @param template_id [String] the template identifier
  # @param content [String, nil] template content (if nil, captures from block)
  # @param is_partial [Boolean] whether this is a partial (default: false)
  # @yield Block that returns template content if content is nil
  # @return [String] relative URL path to the compiled file (for javascript_include_tag)
  def write_handlebars_template(template_id, content = nil, is_partial: false, &)
    dir = handlebars_temp_dir(is_partial:)
    public_dir = handlebars_public_dir(is_partial:)
    url_path = handlebars_url_path(is_partial:)
    safe_id = template_id.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')

    # For partials, strip the -partial suffix from both temp and compiled filenames
    # The Handlebars CLI uses the filename as the partial registration name
    # e.g., master_id_summary_result-partial -> master_id_summary_result
    # This ensures {{>master_id_summary_result}} finds the correct partial
    effective_id = is_partial ? safe_id.sub(/-partial\z/, '') : safe_id
    temp_file = dir.join("#{effective_id}.handlebars")

    # Use the effective_id (without -partial suffix for partials) for the compiled filename
    # Templates and partials are stored in separate subdirectories to avoid name collisions
    compiled_filename = handlebars_compiled_filename(effective_id)
    compiled_file = public_dir.join(compiled_filename)
    relative_path = "#{url_path}#{compiled_filename}"

    # Skip if compiled file already exists (avoid recompilation)
    return relative_path if File.exist?(compiled_file)

    # Skip if temp file already written (deduplication within same request)
    return relative_path if File.exist?(temp_file)

    # Get content from block if not provided
    content ||= capture(&) if block_given?

    # Use placeholder for empty/blank templates - they still need to be registered
    # in Handlebars.templates even if they render nothing
    content = ' ' if content.blank?

    # Ensure directory exists before writing
    FileUtils.mkdir_p(dir)

    # Preprocess and write to temp file
    processed = preprocess_handlebars_source(content)
    File.write(temp_file, processed)

    relative_path
  end

  # Compute an access-control version string for multi-file caching.
  # Combines user role timestamps, access control timestamps, and handlebars_cache_key
  # into a stable identifier that changes only when access controls or template
  # definitions change — NOT on every login.
  # @return [String] 13-character hex string (truncated SHA256)
  def access_control_version
    @access_control_version ||= begin
      userrole, uac = app_type_access_control_timestamps(current_user_or_admin_app_type_id)

      Digest::SHA256.hexdigest("#{userrole}-#{uac}-#{handlebars_cache_key}")[0..12]
    end
  end

  # Write a concatenated multi-file combining all requested compiled templates.
  # Uses a stable filename based on user_id, app_type_id, content digest, and
  # access_control_version — stable across login sessions for effective browser caching.
  # Skips all I/O if the output file already exists.
  # @param requested_handlebars_templates [Array<Hash>] template info hashes with :id, :is_partial keys
  # @return [Array(String, Array, Array)] URL path, template IDs, partial IDs
  def write_multiple_handlebars_templates(requested_handlebars_templates)
    handlebars_partial_ids = []
    handlebars_template_ids = []
    requested_handlebars_templates.each do |template_info|
      if template_info[:is_partial]
        handlebars_partial_ids << template_info[:id]
      else
        handlebars_template_ids << template_info[:id]
      end
    end

    u = current_user_or_admin
    app_type_id = u&.app_type_id if u.respond_to? :app_type_id
    req_digest = Digest::SHA256.hexdigest([handlebars_template_ids, handlebars_partial_ids].join(','))
    filename = "requested-templates-#{u&.id}-#{app_type_id}-#{req_digest}-#{access_control_version}.js"
    url_path = HandlebarsPrecompiler::URL_RELATIVE_PATH
    multi_file = HandlebarsPrecompiler::MULTI_PUBLIC_DIR.join(filename)

    if File.exist?(multi_file)
      Rails.logger.info { "Serving existing multi file: #{filename}" }
    else
      template_html = requested_handlebars_templates.map do |template_info|
        read_handlebars_template(template_info[:id], is_partial: template_info[:is_partial])
      end

      # Add initialization header to ensure Handlebars.partials exists before partials register themselves
      # The CLI-compiled partials assume Handlebars.partials already exists
      init_header = <<~JS
        (function() {
          Handlebars.partials = Handlebars.partials || {};
          Handlebars.templates = Handlebars.templates || {};
        })();
      JS
      File.write(multi_file, (init_header + template_html.join("\n")).html_safe)
      Rails.logger.info { "Generated multi file: #{filename}" }
    end

    ["#{url_path}multi/#{filename}", handlebars_template_ids, handlebars_partial_ids]
  end

  # Compile all templates from temp directories in a single CLI call per type.
  # The CLI output is post-processed to split into individual compiled JS files.
  # @raise [RuntimeError] if compilation fails
  def compile_handlebars_templates
    [false, true].each do |is_partial|
      compile_handlebars_templates_for_type(is_partial:)
    end
  end

  private

  # Resolve the current user or admin, if any.
  # Safe to call outside a request/session context (e.g. rake tasks, console,
  # or specs without a Warden session) — returns nil instead of raising.
  # @return [User, Admin, nil] the current_user/current_admin, or nil
  def current_user_or_admin
    current_user || current_admin
  rescue Devise::MissingWarden
    nil
  end

  # Resolve the app_type_id of the current user or admin, if any.
  # @return [Integer, nil] the app_type_id of the current_user/current_admin, or nil
  def current_user_or_admin_app_type_id
    u = current_user_or_admin
    u&.app_type_id if u.respond_to?(:app_type_id)
  end

  # Look up the latest updated_at timestamps for Admin::UserRole and
  # Admin::UserAccessControl scoped to a given app_type_id. Used to derive
  # cache keys that must change whenever access control for that app_type changes.
  # Includes app_type_id: nil rows too (global/shared roles and access controls that
  # apply across all app types via role_name matching), matching the scoping pattern
  # used elsewhere for this purpose (see UserAndRoles#where_user_and_role and
  # PageLayoutsHelper#page_layout_panels) — otherwise a change to a global role/access
  # control would not be reflected in any app_type-scoped cache key.
  # @param app_type_id [Integer, nil] the app_type to scope the queries to
  # @return [Array(String, String)] [userrole_timestamp, uac_timestamp] as epoch-integer strings
  def app_type_access_control_timestamps(app_type_id)
    userrole = Admin::UserRole.where(app_type_id: [app_type_id, nil])
                              .reorder(updated_at: :desc)
                              .limit(1)
                              .pluck(:updated_at)
                              &.first.to_i.to_s

    uac = Admin::UserAccessControl.where(app_type_id: [app_type_id, nil])
                                  .reorder(updated_at: :desc)
                                  .limit(1)
                                  .pluck(:updated_at)
                                  &.first.to_i.to_s

    [userrole, uac]
  end

  # Compile templates or partials from their respective temp directory.
  # Uses request-specific temp directory to prevent race conditions.
  # @param is_partial [Boolean] true for partials, false for templates
  def compile_handlebars_templates_for_type(is_partial:)
    dir = handlebars_temp_dir(is_partial:)

    # Skip if request-specific directory doesn't exist or is empty
    return unless Dir.exist?(dir)

    file_list = Dir.glob(dir.join('*.handlebars'))
    return if file_list.empty?

    type_name = is_partial ? 'partials' : 'templates'
    Rails.logger.info do
      "Compiling Handlebars #{type_name}: #{file_list.size} files (request: #{handlebars_request_id})"
    end

    # Compile to a request-specific temporary output file
    temp_output = HandlebarsPrecompiler::TMP_DIR.join("compiled_#{type_name}_#{handlebars_request_id}.js")

    # Build CLI command for batch compilation
    handlebars_cmd = HandlebarsPrecompiler::HANDLEBARS_CLI.split
    handlebars_cmd += file_list
    handlebars_cmd += ['-f', temp_output.to_s]
    handlebars_cmd << '--partial' if is_partial
    # NOTE: Minify and source maps not supported in directory mode

    begin
      Utilities::ProcessPipes.pipe_in_out(nil, handlebars_cmd)
    rescue FphsException, StandardError => e
      # Save a copy of the files for debugging before they might be cleaned up
      debug_dir = Rails.root.join('tmp', 'failed-templates')
      FileUtils.mkdir_p(debug_dir)
      file_list.each do |f|
        FileUtils.cp(f, debug_dir.join(File.basename(f)))
      rescue StandardError
        nil
      end
      Rails.logger.error "Saved failed templates to #{debug_dir}"
      Rails.logger.error "command line: \n#{handlebars_cmd.join(' ')}"

      # Log files for debugging
      Rails.logger.error "Files that failed: #{file_list.map { |f| File.basename(f) }.join(', ')}"
      file_list.each do |f|
        content = begin
          File.read(f)
        rescue StandardError
          Rails.logger.warn "UNREADABLE handlebars file: #{f}"
        end
        Rails.logger.error "#{File.basename(f)}: #{content.length} bytes, first 100 chars: #{content[0..99]}"
      end
      error_msg = "Handlebars batch compilation failed for #{type_name}: #{e.message}"
      Rails.logger.error error_msg
      raise error_msg
    end

    # Split combined output into individual files
    split_compiled_output(temp_output, is_partial:)

    # Clean up request-specific temp directory
    cleanup_temp_files(dir, temp_output)
  end

  # Split the combined CLI output into individual compiled JS files.
  # @param output_file [Pathname] path to the combined output file
  # @param is_partial [Boolean] whether these are partials
  def split_compiled_output(output_file, is_partial:)
    return unless File.exist?(output_file)

    full_content = File.read(output_file)
    public_dir = handlebars_public_dir(is_partial:)

    # Remove the outer IIFE wrapper that CLI adds
    # Header: (function() {\n  var template = Handlebars.template, templates = ...
    # Footer: })();
    full_content = full_content.sub(COMPILED_HEAD, '')
    full_content = full_content.sub(/\}\)\(\);\s*\z/, '')

    # Split on template boundaries using regex
    # Pattern: end of one template (});) followed by start of next (templates[... or Handlebars.partials[...)
    template_parts = full_content.split(/(?<=\}\);)\s*(?=(?:templates|Handlebars\.partials)\[)/)

    # Ensure public directory exists
    FileUtils.mkdir_p(public_dir)

    # Write each template to its own file in the appropriate subdirectory
    template_parts.each do |part|
      next if part.strip.empty?

      # Extract template name from the registration line
      name_match = part.match(/^(?:Handlebars\.partials|templates)\['(.+?)'\]/)
      next unless name_match

      template_name = name_match[1]

      # Wrap in IIFE and write to file
      content = "#{COMPILED_HEAD}#{part}\n})();"
      compiled_filename = handlebars_compiled_filename(template_name)
      output_path = public_dir.join(compiled_filename)
      File.write(output_path, content)
    end
  end

  # Clean up temp files after compilation.
  # Removes the request-specific temp directory and its contents.
  # @param dir [Pathname] request-specific temp directory to remove
  # @param temp_output [Pathname] temp combined output file to remove
  def cleanup_temp_files(dir, temp_output)
    FileUtils.rm_rf(dir)
    FileUtils.rm_f(temp_output)
  end
end
