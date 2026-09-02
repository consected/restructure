# frozen_string_literal: true

namespace :prewarm do
  desc 'Warm compiled Handlebars template artifacts for one representative user per access variant (issue #1362)'
  task templates: :environment do
    # PREWARM_SERVER_CACHE_VERSION lets the spawning parent process pass its own value
    # (issue #1362 follow-up) - a spawned rake task is a separate OS process, and
    # Rails.cache is not guaranteed to be shared across processes (e.g. :memory_store is
    # per-process), so without this the child could independently compute a DIFFERENT
    # value than its parent. Falls back to whatever's already cached when absent, so a
    # manual `rake prewarm:templates` invocation is unaffected.
    Prewarm::Runner.run(server_cache_version: ENV['PREWARM_SERVER_CACHE_VERSION'].presence)
  end
end
