# frozen_string_literal: true

module Prewarm
  # Spawns `rake prewarm:templates` as a detached child process at server boot (issue
  # #1362 Stage 2), rather than running an in-process background thread/poll loop. Only
  # decides WHETHER to spawn automatically - Prewarm::Runner itself always runs when
  # actually invoked, so a manual `rake prewarm:templates` (e.g. from a deploy hook)
  # always works regardless of this class.
  #
  # Never runs in the delayed_job worker or a console/runner process: both can share disk
  # with the web server (e.g. on Elastic Beanstalk), and must never spawn their own
  # competing pass.
  class Spawner
    def self.spawn_async
      new.spawn_async
    end

    def spawn_async
      return unless should_spawn?

      # Zero-wait, skip-on-contention: harmless with Puma in single-process mode today,
      # but required if `workers` is ever enabled, so only one worker spawns per boot.
      HandlebarsPrecompiler::FileLock.acquire('prewarm-spawn', wait: 0, on_contention: :skip) do
        do_spawn
      end
    end

    private

    def should_spawn?
      Settings::PrewarmTemplatesEnabled &&
        !HandlebarsPrecompiler.delayed_job_worker? &&
        !HandlebarsPrecompiler.rails_console_or_runner?
    end

    def do_spawn
      io = IO.popen(%w[bundle exec rake prewarm:templates], chdir: Rails.root.to_s, err: %i[child out])
      Process.detach(io.pid)
      Thread.new { drain(io) }
      io.pid
    end

    def drain(io)
      io.each_line { |line| Rails.logger.info "prewarm:templates: #{line.chomp}" }
    rescue IOError, Errno::EBADF
      nil
    ensure
      io.close unless io.closed?
    end
  end
end
