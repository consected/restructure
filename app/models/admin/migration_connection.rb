#
# Runs the generated app migrations (for dynamic models, activity logs, external identifiers, etc)
# found under the app migrations root for the current environment.
#
# Normally the migrations run on a separate thread with their own pooled connection, so the DDL
# commits independently of any transaction the caller has open (for example, saving a definition).
# In tests the connection may be "pinned" (shared by all threads inside the test transaction), in which
# case the migrations run inline on that connection and are rolled back with the test.
#
# If a migration fails, the generated migration file is moved to the failed directory and an
# FphsException is raised.
class Admin::MigrationConnection < ActiveRecord::Base
  # No table - subclassing ActiveRecord::Base allows a separate connection to be established if needed
  self.abstract_class = true
  #
  # Relative path to the failed migrations directory
  def self.db_migration_failed_dirname
    "#{Admin::MigrationGenerator.app_migrations_root}/failed"
  end

  #
  # Database configuration name for the current Rails environment (used in log output)
  def self.dbname
    Rails.env.to_s.to_sym
  end

  #
  # ActiveRecord::MigrationContext for all migrations in the directory
  # @param [String] name - relative path of the migration directory
  def self.migration_context(name)
    Admin::MigrationGenerator.migration_context(name)
  end

  #
  # Run all pending migrations in a directory
  # @param [String] db_migration_dirname - relative path of the migration directory
  # @param [String|nil] do_migration - path of the migration file just generated, moved to the
  #   failed directory if the migration fails
  # @return [true]
  # @raise [FphsException] if any migration fails or times out
  def self.migrate(db_migration_dirname, do_migration: nil)
    # Rails 8.1 sets #pinned on the connection shared by transactional fixtures and test-prof before_all
    pinned_connection = ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.respond_to?(:pinned) && connection.pinned
    end

    if pinned_connection
      # The pinned connection is shared and locked by this thread, so a migration thread would deadlock.
      pending_migrations = migration_context(db_migration_dirname).open.pending_migrations
      self.inline_migration_ran = true
      puts "Calling migrate for #{db_migration_dirname}" unless Rails.env.production?
      begin
        call_migration_context(db_migration_dirname)
      ensure
        begin
          applied_versions = migration_context(db_migration_dirname).get_all_versions
          completed_migrations = pending_migrations.select do |migration|
            applied_versions.include?(migration.version.to_i)
          end
          inline_migration_files.concat(
            completed_migrations.map { |migration| File.expand_path(migration.filename) }
          )
        rescue ActiveRecord::StatementInvalid
          # Keep a migration failure from being replaced by a failed status lookup.
          nil
        end
      end
    else
      # A new thread checks out its own connection, so the migration runs outside the caller's transaction
      thread = Thread.new do
        puts "Calling migrate for #{db_migration_dirname}" unless Rails.env.production?
        call_migration_context(db_migration_dirname)
      end
      # Errors are re-raised in this thread by #join, so don't also print them from the migration thread
      thread.report_on_exception = false

      # Kill rather than abandon a stuck thread, so it can't keep using a connection after we report failure
      unless thread.join(Settings::MigrationTimeoutSec)
        thread.kill
        thread.join(5)
        raise Timeout::Error, "Migration did not complete within #{Settings::MigrationTimeoutSec} seconds"
      end
    end

    true
  # ScriptError covers syntax or load errors in a generated migration file.
  # Interrupts, signals and exit are deliberately not caught.
  rescue StandardError, ScriptError => e
    migration_file_status = move_failed_migration_file(do_migration)
    msg = "Failed migration for path '#{db_migration_dirname}' - #{migration_file_status} - database #{Admin::MigrationGenerator.current_database}"
    Rails.logger.warn msg
    bt = e.backtrace
          .reject { |m| m.include?('/vendor/bundle/ruby/') }
          .join("\n")
    unless Rails.env.production?
      warn msg
      warn e
      puts bt unless Rails.env.production?
    end
    raise FphsException, "#{msg}:\n#{e}\n#{bt}"
  end

  #
  # Absolute paths of migrations whose schema changes will be rolled back with the pinned test connection.
  def self.inline_migration_files
    @inline_migration_files ||= []
  end

  #
  # Return and clear the migrations recorded for cleanup.
  def self.take_inline_migration_files!
    files = inline_migration_files
    @inline_migration_files = []
    files
  end

  #
  # Record that a migration ran inline on a pinned (test) connection, so its tables will be rolled back
  class << self
    attr_writer :inline_migration_ran
  end

  #
  # Clear the inline migration flag. Specs call this after each example and group to decide whether
  # cached table, view and schema information must be reset (see spec/rails_helper.rb).
  # @return [true|false|nil] the value of the flag before it was cleared
  def self.reset_inline_migration_flag!
    previous_value = @inline_migration_ran
    @inline_migration_ran = false
    previous_value
  end

  #
  # Move a failed migration file to the failed directory, so it is not retried by the next migrate
  # of its directory. Filesystem errors are reported in the result rather than raised.
  # @param [String|nil] do_migration - path of the migration file
  # @return [String] status message for logging
  def self.move_failed_migration_file(do_migration)
    if do_migration.present? && File.exist?(do_migration)
      FileUtils.mkdir_p db_migration_failed_dirname
      FileUtils.mv do_migration, db_migration_failed_dirname
      "moved '#{do_migration}' to '#{db_migration_failed_dirname}'"
    else
      "migration file '#{do_migration}' was not present to move"
    end
  rescue SystemCallError => e
    "failed to move '#{do_migration}' to '#{db_migration_failed_dirname}': #{e.message}"
  end

  #
  # Run the pending migrations in the directory using a connection from the pool.
  # When the pool is pinned this is the pinned connection, so the migrations join the caller's transaction.
  def self.call_migration_context(db_migration_dirname)
    # # Establish a connection - use this approach to avoid Rails fixtures
    # establish_connection(dbname)
    ExceptionExtensions.puts_or_tmp_log 'Entering connection pool'
    ActiveRecord::Base.connection_pool.with_connection do
      puts "Running migrations on #{db_migration_dirname} in #{dbname} database"
      ctx = migration_context(db_migration_dirname)
      ExceptionExtensions.puts_or_tmp_log "Migration context: #{ctx}"
      ctx.migrate
    end
  end
end
