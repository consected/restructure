# frozen_string_literal: true

# AppControl generates the implementation classes for dynamic definitions (external identifiers,
# dynamic models and activity logs) and requests server, delayed_job and memcached restarts.
#
# Server startup: how dynamic definitions are set up
# 1. Initializers load. This file defines AppControl and registers the class unload hook and the
#    to_prepare block at the end of the file. Nothing is generated yet.
# 2. Rails runs the to_prepare block (in production, before eager loading). It calls
#    AppControl.prepare_models, which loads Master with require_dependency.
# 3. Master's class body (app/models/master.rb) calls AppControl.define_models. Generation has to
#    happen there, because the rest of Master's class body needs the generated classes.
# 4. define_models calls ActivityLog.define_models, which generates every active external
#    identifier, then every dynamic model (ActivityLog.preload), then every activity log.
#    Generating a definition builds its implementation and controller classes, registers it in
#    Resources::Models and its class's definition_cache, and, for dynamic models and activity
#    logs, parses and caches its option configs.
# 5. define_models then calls Dynamic::DefGenerator.resolve_cached_forward_references! to repair
#    definitions that referenced classes generated later in step 4 (see "Bad references" below).
# 6. Back in Master's class body, the ExternalIdentifier, DynamicModel, ItemFlag and ActivityLog
#    enable_active_configurations calls add associations from Master to the generated classes.
# 7. prepare_models resumes. A run was attempted in step 3, so it doesn't call define_models.
#    It only calls it itself if no run has been attempted since boot or the last class unload.
# 8. config/routes.rb draws the routes for the generated classes (the *.routes_load calls):
#    during boot in production, on the first request in development.
# 9. Later, the dynamic definitions' template_config requests and every background job call
#    Application.refresh_dynamic_defs. Its first call only records the latest definition
#    timestamps; later calls regenerate definitions changed by another server or process.
#
# Development code reload
# 1. The class unload hook clears the record of an attempted run, then Rails unloads autoloaded
#    classes, including Master and the dynamic definition classes.
# 2. Rails redraws the routes before running to_prepare. Drawing them loads Master, which runs
#    steps 3-6 above.
# 3. The to_prepare block calls prepare_models, which sees that run and doesn't repeat it.
#
# Other callers, such as Admin::AppTypeImport, call define_models directly, and it always runs.
#
# Bad references: references to definitions generated later in the same run
# - Option configs that name another definition's class, such as references: or e_sign
#   document_reference:, resolve that class while they are parsed in step 4. If the target is
#   generated later in the same run, its class doesn't exist yet: the reference is dropped
#   (references) or left without its class metadata (e_sign), and that incomplete result stays
#   cached on the definition and is used by its implementation class.
# - The option configs record each model name they could not resolve
#   (OptionConfigs::ExtraOptions#unresolved_model_references). In step 5, once every class
#   exists, resolve_cached_forward_references! re-parses only the cached definitions that
#   recorded unresolved names. Every other definition keeps the options parsed in step 4, so
#   recovery costs one re-parse per affected definition rather than re-parsing all definitions.
# - Names that still can't be resolved, for example because the target is disabled or not
#   generated on this server, stay recorded and are retried on the next run.
# - During an app type import, unresolved names are not recorded (references: entries are kept as
#   configured), since the import can't control the order in which definitions are created.
#
# Reporting definitions that could not be loaded
# - Once a run has completed (define_models_completed_since_unload?), no run is in progress and no
#   app type import is running, Dynamic::DefinitionLoadIssues reports the active definitions left
#   without a working implementation, grouped by cause. Admin::ServerInfo#configuration_failed_reason
#   adds one line per cause to the admin alerts. Mid-run state is incomplete by design, so nothing is
#   reported before the run completes.
class AppControl
  # Skips calls made while a run is already in progress
  @@currently_defining_models = false
  @define_models_attempted_since_unload = false
  @define_models_completed_since_unload = false

  # Request a restart: a full app server restart in production, a code reload in development
  def self.restart_server(not_delayed_job: nil, not_memcached: nil)
    Rails.logger.warn 'Restart Server requested'
    restart_memcached unless not_memcached
    if Rails.env.production?
      pid = spawn('app-scripts/restart_app_server.sh')
      Process.detach(pid)
    else
      STDERR.puts '*** Server restart requested ***'
      FileUtils.touch Rails.root.join('app', 'models', 'dev_server.rb')
      Rails.reload! if Rails.respond_to? :reload!
    end
    restart_delayed_job unless not_delayed_job
  rescue StandardError => e
    Rails.logger.warn "Failed to restart server: #{e.inspect}"
  end

  # Restart delayed_job workers in a detached process
  def self.restart_delayed_job
    Rails.logger.warn 'Restart delayed_job requested'
    pid = spawn('app-scripts/restart_delayed_job.sh')
    Process.detach(pid)
  rescue StandardError => e
    Rails.logger.warn "Failed to restart DelayedJob: #{e.inspect}"
  end

  # Restart memcached in a detached process
  def self.restart_memcached
    Rails.logger.warn 'Restart Memcached requested'
    pid = spawn('app-scripts/restart_memcached.sh')
    Process.detach(pid)
  rescue StandardError => e
    Rails.logger.warn "Failed to restart Memcached: #{e.inspect}"
  end

  # Generate all dynamic definition implementation classes, then re-parse only the cached
  # definitions whose references could not be resolved during the run (see the class comment).
  # The run is marked as attempted when it starts, not when it succeeds: the generators rescue and
  # log their own errors, so success can't be detected. A failed run is therefore not retried by
  # prepare_models until the next class unload.
  def self.define_models
    if @@currently_defining_models
      Rails.logger.warn 'Already defining models'
      return
    end

    Rails.logger.warn 'Define models requested'
    @@currently_defining_models = true
    @define_models_attempted_since_unload = true

    ::ActivityLog.define_models
    # Every class now exists, so references to definitions generated later in the run can resolve
    Dynamic::DefGenerator.resolve_cached_forward_references!

    @define_models_completed_since_unload = true
    @@currently_defining_models = false
  rescue StandardError => e
    Rails.logger.error "Failed to define_models: #{e}\n#{e.backtrace.join("\n")}"
    @@currently_defining_models = false
  end

  # True once a define_models run has started since boot or the last class unload
  def self.define_models_attempted_since_unload?
    @define_models_attempted_since_unload
  end

  # True once a define_models run has finished (including forward reference repair) since boot or the last class unload
  def self.define_models_completed_since_unload?
    @define_models_completed_since_unload
  end

  # True while a define_models run is in progress
  def self.defining_models?
    @@currently_defining_models
  end

  # Called before classes are unloaded on a development reload, so the next prepare generates again
  def self.reset_define_models_attempted
    @define_models_attempted_since_unload = false
    @define_models_completed_since_unload = false
  end

  # Called from to_prepare at boot and after each development code reload.
  # Master's class body, or the routes reload after a class unload, may already have attempted generation.
  def self.prepare_models
    require_dependency 'master'
    define_models unless define_models_attempted_since_unload?
  end
end

# A development code reload unloads the generated classes, so allow the next prepare to generate them
Rails.application.reloader.before_class_unload do
  AppControl.reset_define_models_attempted
end

# Runs at boot (before eager loading in production) and after each development code reload
Rails.application.config.to_prepare do
  AppControl.prepare_models
end
