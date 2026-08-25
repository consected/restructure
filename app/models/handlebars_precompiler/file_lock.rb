# frozen_string_literal: true

module HandlebarsPrecompiler
  # Simple flock-based, single-server mutual exclusion for compiled Handlebars artifact
  # creation (issue #1362, Stage 1).
  #
  # This lock is a WORK-DUPLICATION OPTIMISATION, not a correctness mechanism: artifact
  # writes are atomic (see HandlebarsPrecompilerHelper#atomic_write) and filenames are
  # deterministic, so two processes producing the same artifact write identical bytes
  # safely regardless of who wins. Because of this, an ordinary user request must never
  # be blocked for long waiting on it - see #acquire's +on_contention+ behaviour.
  #
  # Scoped to a single server instance (a plain file lock on local disk), not shared
  # across instances - which is correct, since the artifacts it protects are themselves
  # local-disk-only per server instance.
  class FileLock
    LOCK_DIR = HandlebarsPrecompiler::TMP_DIR.join('locks')

    class << self
      # Attempt to acquire an exclusive lock named +name+ and run the block while
      # holding it. If the lock cannot be acquired within +wait+ seconds:
      #   - on_contention: :proceed (default) - runs the block anyway, WITHOUT the lock
      #   - on_contention: :skip - returns nil without running the block at all
      # A thread that already holds +name+ (re-entrant call) runs the block directly
      # without attempting to re-acquire, avoiding a self-deadlock.
      #
      # If the lock MECHANICS themselves fail (e.g. disk full, permissions, I/O error
      # opening/locking the lock file), this is NOT treated as contention - even with
      # on_contention: :skip, the block still runs unlocked. A broken lock file must
      # never be able to prevent an artifact from being built at all; it can only ever
      # fail to prevent duplicate work.
      # @param name [String] lock name, used as the lock file's basename
      # @param wait [Numeric] seconds to keep retrying a non-blocking acquire attempt
      # @param on_contention [:proceed, :skip] behaviour when the lock is not acquired
      # @yield the protected work
      # @return the block's return value, or nil if skipped on contention
      def acquire(name, wait: 3, on_contention: :proceed, &block)
        return block.call if held_locks[name]

        begin
          file = open_lock_file(name)
        rescue SystemCallError, IOError => e
          Rails.logger.warn "HandlebarsPrecompiler::FileLock could not open lock file for '#{name}': #{e.message}"
          return block.call
        end

        case attempt_lock(file, name, wait)
        when :locked
          run_locked(name, file, &block)
        when :failed_open
          block.call
        else # :contended
          on_contention == :skip ? nil : block.call
        end
      ensure
        file&.close
      end

      private

      # Attempts to acquire the lock (mechanics only - never runs the caller's block), so a
      # SystemCallError/IOError raised by the CALLER's block (real disk-full/permissions
      # failures during the protected work) is never mistaken for a lock-acquisition failure
      # and re-run unlocked (issue #1362 B1 fix).
      # @return [:locked, :contended, :failed_open]
      def attempt_lock(file, name, wait)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + wait
        loop do
          return :locked if file.flock(File::LOCK_EX | File::LOCK_NB)
          return :contended if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          sleep 0.05
        end
      rescue SystemCallError, IOError => e
        Rails.logger.warn "HandlebarsPrecompiler::FileLock could not lock '#{name}': #{e.message}"
        :failed_open
      end

      # @return [Hash] lock names held by the current thread, keyed by name
      def held_locks
        Thread.current[:handlebars_file_lock_held] ||= {}
      end

      def open_lock_file(name)
        FileUtils.mkdir_p(LOCK_DIR)
        File.open(LOCK_DIR.join(safe_name(name)), File::CREAT | File::RDWR)
      end

      def run_locked(name, file)
        held_locks[name] = true
        yield
      ensure
        held_locks.delete(name)
        file.flock(File::LOCK_UN)
      end

      def safe_name(name)
        name.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
      end
    end
  end
end
