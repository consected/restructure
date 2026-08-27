# frozen_string_literal: true

# HandlebarsPrecompiler Module
#
# Provides server-side Handlebars template precompilation using the handlebars CLI.
# Sets up directories, validates CLI availability, and cleans up compiled files on startup.
#
# Generation-scoped compiled output (issue #1362):
# Compiled templates/partials/multi-bundles live under a "gen-<key>" directory, where
# +generation_key+ is derived ONLY from non-user-specific inputs (server_cache_version and
# dynamic-definition/config updated_at timestamps) - identical for every user, and it
# rotates exactly when a dynamic definition changes or the server restarts. Bucketing by
# generation lets old rotations be deleted wholesale (a single directory rm_rf) rather than
# by pattern-matching filenames, and bounds disk usage to a small, count-based number of
# generations (see #sweep_old_generations) instead of accumulating indefinitely.
module HandlebarsPrecompiler
  HANDLEBARS_CLI = ENV.fetch('HANDLEBARS_CLI', Rails.root.join('node_modules', 'handlebars', 'bin', 'handlebars').to_s)

  # Environment-specific directory naming for test isolation
  # In test mode with parallel execution, TEST_ENV_NUMBER provides isolation
  HANDLEBARS_DIR_NAME = begin
    base_name = "handlebars-#{Rails.env}"
    test_suffix = "#{ENV['TEST_ENV_SET']}#{ENV['TEST_ENV_NUMBER'].to_s.strip}"
    test_suffix.empty? ? base_name : "#{base_name}-#{test_suffix}"
  end

  TMP_DIR = Rails.root.join('tmp', HANDLEBARS_DIR_NAME)
  TEMPLATES_TMP_DIR = TMP_DIR.join('templates')
  PARTIALS_TMP_DIR = TMP_DIR.join('partials')
  PUBLIC_DIR = Rails.root.join('public', HANDLEBARS_DIR_NAME)

  URL_RELATIVE_PATH = "/#{HANDLEBARS_DIR_NAME}/"

  class << self
    def cli_available?
      @cli_available ||= system("#{HANDLEBARS_CLI} --version > /dev/null 2>&1")
    end

    def cli_path
      # For a fully specified path or just `npx`, just return the command itself
      @cli_path ||= if HANDLEBARS_CLI.include?('/') || HANDLEBARS_CLI.start_with?('npx')
                      HANDLEBARS_CLI.to_s
                    else
                      `which #{HANDLEBARS_CLI}`.strip
                    end
    end

    # Dynamic-definition/config classes whose most recent updated_at contributes to the
    # generation key - identical list to (and the single source of truth for) what used to
    # be duplicated inline in HandlebarsPrecompilerHelper#handlebars_item_updates_key.
    # A method (not a top-level constant) so these autoloaded AR classes are only resolved
    # when actually called, well after boot - referencing them eagerly at file-load time
    # breaks Zeitwerk/Rails initialization order.
    def item_update_classes
      [Admin::MessageTemplate, DynamicModel, ActivityLog, ExternalIdentifier,
       Admin::ConfigLibrary, Admin::PageLayout, Admin::AppConfiguration]
    end

    # Concatenated latest updated_at timestamps of the dynamic-definition/config classes
    # that affect compiled Handlebars content. Not memoized here (callers needing
    # per-request stability, e.g. HandlebarsPrecompilerHelper, memoize their own copy).
    # @return [String]
    def item_updates_key
      item_update_classes.map { |c| c.reorder(updated_at: :desc).limit(1).pluck(:updated_at)&.first.to_i.to_s }.join('-')
    end

    # Non-user-specific generation key: identical for every user, rotates exactly when
    # server_cache_version changes (deploy/restart) or a dynamic definition/config class is
    # touched.
    # @return [String] 13-character hex string (truncated SHA256)
    def generation_key
      Digest::SHA256.hexdigest("#{Application.server_cache_version}-#{item_updates_key}")[0..12]
    end

    # @param key [String] generation key, defaults to the CURRENT one
    # @return [Pathname] tmp/-rooted directory for this generation's compiled output
    def tmp_generation_dir(key = generation_key)
      TMP_DIR.join("gen-#{key}")
    end

    # @param key [String] generation key, defaults to the CURRENT one
    # @return [Pathname] public/-rooted directory for this generation's web-servable output
    def public_generation_dir(key = generation_key)
      PUBLIC_DIR.join("gen-#{key}")
    end

    # Individual compiled templates - NOT web-servable (issue #1362), a purely server-side
    # compile cache read via HandlebarsPrecompilerHelper#read_compiled_handlebars_file.
    def templates_compiled_dir(key = generation_key)
      tmp_generation_dir(key).join('compiled_templates')
    end

    # Individual compiled partials - see #templates_compiled_dir.
    def partials_compiled_dir(key = generation_key)
      tmp_generation_dir(key).join('compiled_partials')
    end

    # The only compiled Handlebars output actually fetched by the browser.
    def multi_dir(key = generation_key)
      public_generation_dir(key).join('multi')
    end

    def setup_directories
      FileUtils.mkdir_p(TMP_DIR)
      FileUtils.mkdir_p(TEMPLATES_TMP_DIR)
      FileUtils.mkdir_p(PARTIALS_TMP_DIR)
      FileUtils.mkdir_p(PUBLIC_DIR)
      # Generation-scoped compiled directories are created on demand as they're written to
      # (see HandlebarsPrecompilerHelper) - nothing to pre-create here, since the current
      # generation key is unknown before the DB is available at boot.
    end

    def cleanup_tmp_dir
      FileUtils.rm_rf(Dir.glob(TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(PARTIALS_TMP_DIR.join('*')))
    end

    # Delete ALL precompiled generations on startup (every "gen-*" directory, tmp and
    # public), regardless of retention settings - a full restart always starts fully cold.
    # Also removes the pre-issue-#1362 flat layout (compiled output directly under
    # PUBLIC_DIR/templates,partials,multi, no "gen-" prefix) left behind on a server
    # upgraded from before generation-scoped directories existed (issue #1362 S8 fix) -
    # nothing else ever recreates or reads these names any more.
    def cleanup_compiled_output
      FileUtils.rm_rf(Dir.glob(TMP_DIR.join('gen-*')))
      FileUtils.rm_rf(Dir.glob(PUBLIC_DIR.join('gen-*')))
      FileUtils.rm_rf(PUBLIC_DIR.join('templates'))
      FileUtils.rm_rf(PUBLIC_DIR.join('partials'))
      FileUtils.rm_rf(PUBLIC_DIR.join('multi'))
    end

    # True when this process is the delayed_job worker (issue #1362). It shares disk with
    # the web process on Elastic Beanstalk, so it must never wipe the web server's compiled
    # templates or rotate server_cache_version out from under it on its own restart. Only
    # bin/delayed_job (via script/delayed_job) requires 'delayed/command' before loading
    # Rails - nothing else in the app does - making this a reliable, semantic signal rather
    # than parsing the process name/argv.
    def delayed_job_worker?
      defined?(Delayed::Command) ? true : false
    end

    # True for a `rails console`/`rails runner` invocation (issue #1362 S10 fix) - neither
    # is dispatched via Rake (so the rake_tasks guard below never sees them), yet both
    # commonly run against a live/production box (see e.g. the `bundle exec rails runner`
    # pattern documented for inspecting app state) and would otherwise wipe the actual web
    # server's compiled templates and server_cache_version out from under it. ARGV still
    # holds the original `bin/rails <command>` invocation at this point in boot.
    def rails_console_or_runner?
      %w[console c runner r].include?(ARGV.first.to_s)
    end

    # Runs the startup compiled-output cleanup, UNLESS this process is the delayed_job
    # worker or a `rails console`/`rails runner` invocation (issue #1362) - extracted from
    # the after_initialize block below so the guard is independently testable.
    def startup_cleanup!
      if delayed_job_worker? || rails_console_or_runner?
        Rails.logger.info 'HandlebarsPrecompiler: skipping compiled-template cleanup in a ' \
                          'non-web process (delayed_job/console/runner) - it shares disk ' \
                          'with the web process and must not wipe its compiled templates ' \
                          '(issue #1362).'
        return
      end

      cleanup_tmp_dir
      cleanup_compiled_output

      # Invalidate server_cache_version since compiled files were cleaned up.
      # This forces browsers and fragment caches to use fresh template URLs,
      # preventing 404s when multi files are deleted but stale URLs remain cached.
      Rails.cache.delete('server_cache_version')
    end

    # Basenames (e.g. "gen-abc123def4567") of every generation directory that currently
    # exists under either TMP_DIR or PUBLIC_DIR.
    # @return [Array<String>]
    def existing_generation_dir_names
      (Dir.glob(TMP_DIR.join('gen-*')) + Dir.glob(PUBLIC_DIR.join('gen-*')))
        .select { |d| File.directory?(d) }
        .map { |d| File.basename(d) }
        .uniq
    end

    # Most recent mtime (epoch float) seen for a generation, across BOTH roots (tmp and
    # public) AND their immediate subdirectories (compiled_templates/compiled_partials/
    # multi) - the generation's own top-level directory is only touched once, at creation,
    # since new files are always written into one of those subdirectories rather than
    # directly into the generation directory itself. Checking one level down means this
    # reflects the last time anything was actually compiled/written into the generation,
    # not just when it was first created.
    # @param name [String] generation directory basename, e.g. "gen-abc123def4567"
    # @return [Float]
    def generation_mtime(name)
      roots = [TMP_DIR.join(name), PUBLIC_DIR.join(name)]
      (roots + roots.flat_map { |d| Dir.glob(d.join('*')) })
        .select { |d| File.directory?(d) }
        .map { |d| File.mtime(d).to_f }
        .max || 0.0
    end

    # Delete generation directories outside the retention set (issue #1362): keeps the
    # CURRENT generation plus up to Settings::HandlebarsKeepGenerations of the most
    # recently-touched OTHER (non-current) generations, so a process/request that has not
    # yet observed a rotation can still find its generation's compiled files. A generation
    # younger than Settings::HandlebarsGenerationSafetyWindowSeconds is never swept,
    # regardless of the count, so one created moments ago can't be deleted out from under a
    # concurrent writer.
    #
    # "current" is computed independently of whether its directory exists yet: the real
    # (opportunistic) trigger only ever runs when the current generation's directory is
    # STILL MISSING (see HandlebarsPrecompilerHelper#maybe_sweep_old_handlebars_generations),
    # so `names` never actually contains it - counting it separately from `others` (issue
    # #1362 S3 fix) keeps retention at exactly "current + HandlebarsKeepGenerations" instead
    # of drifting to "current + HandlebarsKeepGenerations + 1" once it's created moments later.
    def sweep_old_generations
      current = "gen-#{generation_key}"
      names = existing_generation_dir_names
      return if names.size <= 1

      others = names - [current]
      ranked_others = others.sort_by { |name| -generation_mtime(name) }
      keep = ranked_others.first(Settings::HandlebarsKeepGenerations).to_set
      keep << current

      safety_cutoff = Time.now.to_f - Settings::HandlebarsGenerationSafetyWindowSeconds

      names.each do |name|
        next if keep.include?(name)
        next if generation_mtime(name) >= safety_cutoff

        FileUtils.rm_rf(TMP_DIR.join(name))
        FileUtils.rm_rf(PUBLIC_DIR.join(name))
      end
    end

    # Delete HandlebarsPrecompiler::FileLock lock files older than
    # Settings::HandlebarsLockFileMaxAgeSeconds (issue #1362 S7 fix). Lock names are per
    # user/app_type/template-set, so without this they accumulate forever on a long-lived
    # server. Safe to delete a lock file out from under a holder: FileLock is a
    # work-duplication optimisation, not a correctness mechanism (see FileLock's own
    # documentation), so at worst this narrows/defeats mutual exclusion for one
    # in-flight compile rather than corrupting anything - atomic writes and deterministic
    # filenames make the underlying artifact writes safe regardless.
    def sweep_stale_lock_files
      cutoff = Time.now.to_f - Settings::HandlebarsLockFileMaxAgeSeconds
      Dir.glob(FileLock::LOCK_DIR.join('*')).each do |path|
        next unless File.file?(path)
        next if File.mtime(path).to_f >= cutoff

        FileUtils.rm_f(path)
      end
    end
  end
end

# Initialize on Rails startup (but not during asset precompilation or rake tasks)
Rails.application.config.after_initialize do
  rake_tasks = defined?(Rake) ? Array(Rake.application&.top_level_tasks) : []
  next if rake_tasks.any? && rake_tasks.none? { |task| %w[server s].include?(task.to_s) }

  HandlebarsPrecompiler.setup_directories
  HandlebarsPrecompiler.startup_cleanup!

  unless HandlebarsPrecompiler.cli_available?
    msg = 'Handlebars CLI not found. Install with: npm install --global handlebars'
    Rails.logger.error msg
    # Don't raise in test environment to allow tests to run
    raise msg unless Rails.env.test?
  end

  Rails.logger.info "HandlebarsPrecompiler initialized. CLI: #{HandlebarsPrecompiler.cli_path}"

  # Must run AFTER startup_cleanup! above (issue #1362 Stage 2): server_cache_version is
  # shared (memcached) and startup_cleanup! deletes it on web boot. If the prewarm child
  # process ran first, it would resolve/set a value that the web process then deletes,
  # picking a different one - every artifact the child warms would land in an orphaned
  # generation directory.
  Prewarm::Spawner.spawn_async
end
