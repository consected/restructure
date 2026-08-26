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
  # @return [Pathname] path to the current generation's compiled-output directory
  def handlebars_public_dir(is_partial:)
    key = handlebars_generation_key
    is_partial ? HandlebarsPrecompiler.partials_compiled_dir(key) : HandlebarsPrecompiler.templates_compiled_dir(key)
  end

  # Get URL relative path for templates or partials.
  # @param is_partial [Boolean] whether this is for partials
  # @return [String] URL relative path, embedding the current generation key
  def handlebars_url_path(is_partial:)
    subdir = is_partial ? 'partials' : 'templates'
    "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{handlebars_generation_key}/#{subdir}/"
  end

  # Non-user-specific generation key (issue #1362), memoized per request/helper instance so
  # it stays stable even if a dynamic definition is touched mid-request. Identical for every
  # user; rotates only on server_cache_version change or a dynamic-definition/config update.
  # @return [String] 13-character hex string (truncated SHA256)
  def handlebars_generation_key
    @handlebars_generation_key ||= HandlebarsPrecompiler.generation_key
  end

  # Whether the option-type-agnostic result-template ids (the bare and "dynamic_model__"-
  # stripped ids in common_templates/_search_results_template.html.erb) should be emitted
  # for this option_type_config. Those two ids do not vary per option_type_config, so a
  # def_record with more than one option_type_config must only emit them once (issue #1379)
  # - otherwise the same id gets queued in the same request with differing content on each
  # iteration, which write_handlebars_template can only ever compile one version of.
  # @param option_type_config_name [String, Symbol, nil] the current iteration's option type
  # @param default_option_type_name [String, Symbol, nil] the def_record's default option type
  # @return [Boolean]
  def emit_option_type_agnostic_handlebars_ids?(option_type_config_name, default_option_type_name)
    option_type_config_name.blank? || option_type_config_name.to_s == default_option_type_name.to_s
  end

  # Opportunistically sweep old compiled-Handlebars generations (and stale FileLock lock
  # files - issue #1362 S7 fix) the first time THIS request notices the current
  # generation's directory doesn't exist yet (issue #1362) - i.e. a rotation happened
  # since the last request that checked. Checked at most once per request (memoized).
  # Locked with on_contention: :skip and a zero wait: this is a pure disk-space
  # optimisation, so if another process is already sweeping (or holds the lock for any other
  # reason), this request simply moves on rather than doing redundant work or waiting.
  def maybe_sweep_old_handlebars_generations
    return if @handlebars_generation_sweep_checked

    @handlebars_generation_sweep_checked = true
    return if Dir.exist?(HandlebarsPrecompiler.tmp_generation_dir(handlebars_generation_key))

    HandlebarsPrecompiler::FileLock.acquire('generation-sweep', wait: 0, on_contention: :skip) do
      HandlebarsPrecompiler.sweep_old_generations
      HandlebarsPrecompiler.sweep_stale_lock_files
    end
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
    @handlebars_item_updates_key ||= HandlebarsPrecompiler.item_updates_key
  end

  # Generate filename for compiled output.
  #
  # When +source+ is given, the filename is content-addressed: a digest of the actual
  # preprocessed template source (32 hex chars - issue #1362 S5, widened from a truncated
  # 13-char/52-bit digest, since a collision there would mean one user's compiled output
  # is served to another), so identical content (from any user/app_type) shares one
  # compiled file, and differing content never collides. Compiled output is a pure function
  # of the source, so this is strictly more precise than keying on assumed inputs
  # (app_type/user/role) - it splits exactly when content differs and shares whenever it
  # does not. Every template id is content-addressed when a source is given (issue #1362
  # S4) - see content_addressing_safety_spec.rb / the option-3 fix in
  # _search_results_resources_panel.html.erb for why this is safe even for
  # master_main_inner.
  # Without +source+, falls back to the per-user/app_type handlebars_cache_key, as before.
  # @param template_id [String] the template identifier
  # @param source [String, nil] preprocessed template source, for content addressing
  # @return [String] safe filename with cache key or content digest suffix
  def handlebars_compiled_filename(template_id, source = nil)
    safe_id = template_id.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
    key = source ? Digest::SHA256.hexdigest(source)[0..31] : handlebars_cache_key
    "#{safe_id}-#{key}.js"
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

  # Read an already-compiled Handlebars file from its recorded URL-relative path (as
  # returned by #write_handlebars_template / recorded by handlebars_template_tag), rather
  # than recomputing the filename from a template id - the only way to correctly locate a
  # content-addressed compiled file, since its name depends on source we may not have here.
  #
  # The path is treated as an opaque (generation, type, filename) identifier rather than a
  # literal servable URL (issue #1362): individual compiled templates/partials no longer
  # live under HandlebarsPrecompiler::PUBLIC_DIR, and are scoped by generation, so the
  # "gen-<key>" and "partials/"/"templates/" segments are used to pick the correct actual
  # (tmp-based) directory - which may be an OLDER, still-retained generation, not
  # necessarily the current one.
  # @param compiled_file_path [String] URL-relative path, e.g.
  #   "/handlebars-test/gen-abc123def4567/templates/x.js"
  # @return [String, nil] compiled file content, or nil if the file is unexpectedly missing
  def read_compiled_handlebars_file(compiled_file_path)
    relative = compiled_file_path.to_s.delete_prefix(HandlebarsPrecompiler::URL_RELATIVE_PATH)
    gen_segment, subdir, filename = relative.split('/', 3)
    key = gen_segment.to_s.delete_prefix('gen-')
    base_dir = if subdir == 'partials'
                 HandlebarsPrecompiler.partials_compiled_dir(key)
               else
                 HandlebarsPrecompiler.templates_compiled_dir(key)
               end
    file = base_dir.join(File.basename(filename.to_s))

    unless File.exist?(file)
      # A generation can be swept, or a non-web process's boot-time cleanup can wipe the
      # tmp dirs, in the narrow window between write_handlebars_template confirming this
      # file exists and this read (issue #1362 S6 fix). Degrade rather than raise and fail
      # the whole page/bundle over one template: the front-end already tolerates an
      # individual missing template (see _fpa.js's "Template not found" console.log guard),
      # and a subsequent page load recompiles it fresh. Returns nil (not '') so the caller
      # can tell a genuine miss apart from a legitimately empty compiled file and avoid
      # persisting a degraded multi bundle (see #write_multiple_handlebars_templates).
      Rails.logger.warn "HandlebarsPrecompiler: compiled file missing at read time, omitting from bundle: #{file}"
      return nil
    end

    File.read(file)
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
    maybe_sweep_old_handlebars_generations

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

    # A given id can only ever be queued/compiled ONCE per request: #compile_handlebars_templates
    # reads whichever content currently sits at +temp_file+, and the Handlebars runtime can
    # only register one function per id anyway (Handlebars.templates[id] is a single slot).
    # If this id was already written earlier in this same request - even with DIFFERENT
    # content (e.g. two dynamic models/embeds sharing the same derived template id) - reuse
    # the ALREADY-WRITTEN content's filename rather than recomputing one from this call's
    # (different) content: returning a filename addressed to content that is never actually
    # written/compiled left it permanently missing, which made
    # #write_multiple_handlebars_templates discard the whole page's multi-bundle rather than
    # just this one template. NOTE: this early return never captures +content+ from a block,
    # so handlebars_template_tag blocks must stay free of side effects other callers rely on.
    if File.exist?(temp_file)
      existing_processed = File.read(temp_file)
      compiled_filename = handlebars_compiled_filename(effective_id, existing_processed)
      return "#{url_path}#{compiled_filename}"
    end

    # Content must be resolved BEFORE the filename can be computed, since the filename is
    # a digest of the source for content-addressed (non-excluded) template ids.
    content ||= capture(&) if block_given?
    # Use placeholder for empty/blank templates - they still need to be registered
    # in Handlebars.templates even if they render nothing
    content = ' ' if content.blank?
    processed = preprocess_handlebars_source(content)

    # Use the effective_id (without -partial suffix for partials) for the compiled filename
    # Templates and partials are stored in separate subdirectories to avoid name collisions
    compiled_filename = handlebars_compiled_filename(effective_id, processed)
    compiled_file = public_dir.join(compiled_filename)
    relative_path = "#{url_path}#{compiled_filename}"

    # Skip if compiled file already exists (avoid recompilation)
    return relative_path if File.exist?(compiled_file)

    # Ensure directory exists before writing
    FileUtils.mkdir_p(dir)

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
    url_path = "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{handlebars_generation_key}/"
    multi_file = HandlebarsPrecompiler.multi_dir(handlebars_generation_key).join(filename)

    if File.exist?(multi_file)
      Rails.logger.info { "Serving existing multi file: #{filename}" }
    else
      # Locked to avoid duplicate assembly if another request wants the exact same bundle
      # concurrently (issue #1362) - re-checks existence once acquired/attempted, since the
      # other request may have just finished while this one waited.
      HandlebarsPrecompiler::FileLock.acquire(filename, wait: Settings::HandlebarsLockWaitSeconds) do
        unless File.exist?(multi_file)
          # Read via the compiled_file_path already recorded by handlebars_template_tag at
          # write time, rather than recomputing the filename from id - recomputation is not
          # possible for content-addressed templates, since their filename depends on
          # source we don't have here.
          template_html = requested_handlebars_templates.map do |template_info|
            read_compiled_handlebars_file(template_info[:compiled_file_path])
          end

          if template_html.any?(&:nil?)
            # Do not persist a degraded bundle (issue #1362 should-fix): filename depends
            # only on the requested template set/access version, not on whether every read
            # succeeded, so writing a partial bundle here would serve the SAME broken
            # content to every future request for this exact set until the generation
            # rotates. Skipping the write lets a later request retry from scratch once the
            # missing compiled file reappears.
            Rails.logger.warn "HandlebarsPrecompiler: skipping multi-file assembly for #{filename}, " \
                              'one or more compiled templates were missing'
          else
            # Add initialization header to ensure Handlebars.partials exists before partials
            # register themselves. The CLI-compiled partials assume Handlebars.partials
            # already exists
            init_header = <<~JS
              (function() {
                Handlebars.partials = Handlebars.partials || {};
                Handlebars.templates = Handlebars.templates || {};
              })();
            JS
            FileUtils.mkdir_p(HandlebarsPrecompiler.multi_dir(handlebars_generation_key))
            atomic_write(multi_file, (init_header + template_html.join("\n")).html_safe)
            Rails.logger.info { "Generated multi file: #{filename}" }
          end
        end
      end
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

  # Write +content+ to +path+ atomically: writes to a temp file in the same directory
  # then renames into place, so a concurrent reader can never observe partial content,
  # and a failed write can never corrupt a pre-existing good file at +path+.
  # @param path [Pathname, String] destination file path
  # @param content [String] content to write
  def atomic_write(path, content)
    tmp_path = "#{path}.#{Process.pid}-#{SecureRandom.hex(4)}.tmp"
    File.write(tmp_path, content)
    File.rename(tmp_path, path)
  ensure
    FileUtils.rm_f(tmp_path) if tmp_path && File.exist?(tmp_path)
  end

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
  #
  # Duplicate-compile avoidance (issue #1362) happens in two layers:
  #   1. A cheap, lock-free existence re-check (#reject_already_compiled) - the temp files
  #      here may have been written seconds ago, and another process could have compiled
  #      the same content-addressed output since. This alone closes most of the window.
  #   2. A FileLock around the remaining, still-missing set, keyed by exactly which
  #      templates are pending - so two requests needing the SAME missing set (the common
  #      case: many users sharing identical access, all logging in after a deploy)
  #      serialize against each other. The lock is re-checked (step 1 again) once acquired,
  #      since the holder we waited behind may have just finished. This is an optimisation
  #      only - see HandlebarsPrecompiler::FileLock - so contention still runs the CLI
  #      unlocked rather than blocking or skipping the work.
  # @param is_partial [Boolean] true for partials, false for templates
  def compile_handlebars_templates_for_type(is_partial:)
    dir = handlebars_temp_dir(is_partial:)

    # Skip if request-specific directory doesn't exist or is empty
    return unless Dir.exist?(dir)

    file_list = Dir.glob(dir.join('*.handlebars'))
    return if file_list.empty?

    type_name = is_partial ? 'partials' : 'templates'
    temp_output = HandlebarsPrecompiler::TMP_DIR.join("compiled_#{type_name}_#{handlebars_request_id}.js")

    file_list = reject_already_compiled(file_list, is_partial:)

    if file_list.any?
      lock_name = compile_lock_name(file_list, is_partial:)
      HandlebarsPrecompiler::FileLock.acquire(lock_name, wait: Settings::HandlebarsLockWaitSeconds) do
        file_list = reject_already_compiled(file_list, is_partial:)

        compile_and_split_pending(file_list, is_partial:, type_name:, temp_output:) if file_list.any?
      end
    end

    # Clean up request-specific temp directory, regardless of whether this call
    # performed the compile, skipped via the pre-filter, or lost the lock race.
    cleanup_temp_files(dir, temp_output)
  end

  # Drop any file whose content-addressed compiled output already exists - a cheap,
  # lock-free defense against redundant compiles (issue #1362).
  # @param file_list [Array<String>] paths to pending .handlebars temp files
  # @param is_partial [Boolean] whether these are partials
  # @return [Array<String>] file_list with already-compiled entries removed
  def reject_already_compiled(file_list, is_partial:)
    public_dir = handlebars_public_dir(is_partial:)
    file_list.reject do |file|
      template_name = File.basename(file, '.handlebars')
      source = File.read(file)
      File.exist?(public_dir.join(handlebars_compiled_filename(template_name, source)))
    end
  end

  # Deterministic lock name for a batch compile: a digest of the sorted set of pending
  # template names, so two requests needing the exact same missing templates serialize
  # against each other without needing per-file locks.
  # @param file_list [Array<String>] paths to pending .handlebars temp files
  # @param is_partial [Boolean] whether these are partials
  # @return [String] lock name
  def compile_lock_name(file_list, is_partial:)
    names = file_list.map { |f| File.basename(f, '.handlebars') }.sort
    digest = Digest::SHA256.hexdigest(names.join(','))[0..12]
    "compile-#{is_partial ? 'partials' : 'templates'}-#{digest}"
  end

  # Run the CLI batch compile and split its output, for a confirmed-still-pending set of
  # templates. Split out of #compile_handlebars_templates_for_type only so the FileLock
  # block above stays readable; error handling/messages are unchanged from before locking
  # was introduced.
  def compile_and_split_pending(file_list, is_partial:, type_name:, temp_output:)
    Rails.logger.info do
      "Compiling Handlebars #{type_name}: #{file_list.size} files (request: #{handlebars_request_id})"
    end

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
      # Re-read the preprocessed source this template was compiled from (still on disk -
      # cleanup runs after this method) so the compiled filename matches EXACTLY what
      # #write_handlebars_template already decided/returned for the same source.
      # Sanitized the same way every other path built from a template id in this file is
      # (issue #1362 S11 fix) - template_name here comes from parsing the CLI's own output
      # rather than a value we generated, so it must not be trusted verbatim in a path.
      safe_template_name = template_name.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
      source_path = handlebars_temp_dir(is_partial:).join("#{safe_template_name}.handlebars")
      # The source can vanish (cleanup racing ahead, or a non-web process wiping tmp dirs)
      # between the CLI batch-compiling it and this re-read (issue #1362 should-fix). Skip
      # just this one entry rather than raising and losing the WHOLE batch, including
      # other, unrelated templates compiled in the same CLI call.
      unless File.exist?(source_path)
        Rails.logger.warn "HandlebarsPrecompiler: #{template_name} source file missing, skipping: #{source_path}"
        next
      end
      source = File.read(source_path)
      compiled_filename = handlebars_compiled_filename(template_name, source)
      output_path = public_dir.join(compiled_filename)
      atomic_write(output_path, content)
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
