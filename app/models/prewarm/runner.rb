# frozen_string_literal: true

module Prewarm
  # Drives one prewarm pass over Prewarm::Candidates.representatives (issue #1362 Stage
  # 2). Invoked either manually (`rake prewarm:templates`) or by Prewarm::Spawner on
  # server boot - the decision of WHETHER to invoke it automatically belongs to the
  # spawner (Settings::PrewarmTemplatesEnabled), not here: a manually-triggered pass
  # (e.g. from a deploy hook) must always be able to run.
  #
  # The whole pass is wrapped in a zero-wait, skip-on-contention lock, so a concurrent
  # invocation is a no-op rather than a wait - this must never be able to block a real
  # user request. A warm marker per (user, app_type) combination makes a re-run of an
  # already-warmed generation cheap, and one failing combination never aborts the rest.
  class Runner
    def self.run
      new.run
    end

    def run
      HandlebarsPrecompiler.setup_directories

      HandlebarsPrecompiler::FileLock.acquire('prewarm-pass', wait: 0, on_contention: :skip) do
        warm_all
      end || { warmed: 0, skipped: 0, failed: 0, contended: true }
    end

    private

    def warm_all
      summary = { warmed: 0, skipped: 0, failed: 0 }

      Prewarm::Candidates.representatives.each do |user, app_type|
        marker = warm_marker_path(user, app_type)
        if File.exist?(marker)
          summary[:skipped] += 1
          next
        end

        warm_one(user, app_type, marker, summary)
        sleep Settings::PrewarmThrottleSeconds if Settings::PrewarmThrottleSeconds.positive?
      end

      Rails.logger.info "Prewarm::Runner pass complete: #{summary}"
      summary
    end

    def warm_one(user, app_type, marker, summary)
      if Prewarm::MasterTemplates.render_for(user, app_type)
        FileUtils.mkdir_p(marker.dirname)
        FileUtils.touch(marker)
        summary[:warmed] += 1
      else
        summary[:failed] += 1
      end
    rescue StandardError => e
      Rails.logger.warn(
        "Prewarm::Runner: unexpected error warming user=#{user.id} " \
        "app_type=#{app_type.id}: #{e.class}: #{e.message}"
      )
      summary[:failed] += 1
    end

    def warm_marker_path(user, app_type)
      HandlebarsPrecompiler.tmp_generation_dir.join('warm', "#{user.id}-#{app_type.id}")
    end
  end
end
