# frozen_string_literal: true

require 'rails_helper'

# Startup timing benchmark for the dynamic-definition option-config parse.
#
# PURPOSE
# -------
# This benchmark records the wall-clock time to parse the option configs of every
# active dynamic definition (external identifiers, dynamic models and activity logs).
# That parse is the section of startup work impacted by the fixes tracked in
# consected/restructure issue #1246:
#   - Issue 1: OptionConfigs::ExtraOptions#clean_references_def runs during this parse.
#   - Issue 2: Dynamic::DefHandler.active_model_configurations controls how many
#              definitions are parsed (and therefore how much work is done).
#
# It is used to capture a "before" average (Red phase) and an "after" average (Green
# phase) so any improvement or regression can be recorded on the GitHub issue.
#
# COLD-MEASUREMENT NOTES
# ----------------------
# * Each run is a SEPARATE example so it gets its own ActiveRecord query-cache scope
#   (rspec-rails wraps each example in a query cache). This prevents identical SQL
#   (e.g. active_model_configurations / config library lookups) being served from the
#   query cache on later runs, which otherwise makes each successive run faster.
# * The timed parse is additionally wrapped in ActiveRecord::Base.uncached and the
#   query cache is cleared in the reset, so query caching is eliminated as a variable
#   and every run - before and after - is measured under the same cold conditions.
# * All class-level memoization (active_app_types, active_model_configurations,
#   associated-items memo) and Rails.cache are reset before each run.
# * Class regeneration (generate_model) is intentionally NOT measured: it self-skips
#   via prevent_regenerate_model once classes already exist (which they do after the
#   suite boots), so it cannot be timed cold here. Forcing the option-config parse
#   (option_configs force: true) re-runs clean_references_def cold on every iteration.
#
# IMPORTANT
# ---------
# * These examples deliberately carry NO expectation. They must never fail the suite
#   based on timing, now or in the future.
# * The examples are gated behind the TIME_STARTUP=true environment variable so they
#   do not run as part of, and slow down, the normal test suite. Export the variable
#   to run them:
#     export TIME_STARTUP=true
#     bundle exec rspec spec/models/startup/define_models_timing_spec.rb
#
# NOTE: keep these examples gated (effectively skipped) except when explicitly
# capturing before/after timings.
#
# STATUS: both the "before" and "after" baselines for issue #1246 have now been
# captured and recorded as comments on the issue, so this describe block is marked
# `skip` to avoid running (even manually with TIME_STARTUP=true) by accident. Remove
# the `skip:` below if a future change needs a fresh before/after comparison.

if ENV['TIME_STARTUP'] == 'true'
  RSpec.describe 'Dynamic definition option-config parse timing', type: :model,
                                                                  skip: 'before/after timings already captured on issue #1246 - remove to re-run' do
    before(:all) { @timings = [] }

    after(:all) do
      next if @timings.blank?

      average = @timings.sum / @timings.size
      puts format('[startup-timing] average over %<runs>d runs: %<avg>.3fs',
                  runs: @timings.size, avg: average)
    end

    # Reset every cache/memo that could let a subsequent parse reuse work from a
    # previous run, so each iteration performs a full cold parse.
    def reset_all_dynamic_def_memos!
      Rails.cache.clear
      ActiveRecord::Base.connection.clear_query_cache
      ActiveRecord::Base.connection.schema_cache.clear!
      Admin::AppType.reset_active_app_types!
      Admin::AppType.reset_memo_associated_items!
      [ExternalIdentifier, DynamicModel, ActivityLog].each(&:reset_active_model_configurations!)
      # Run a full GC before each timed run so heap growth from a previous run does
      # not make a later run appear faster (the remaining variance is VM/GC warmup,
      # not application caching).
      GC.start(full_mark: true, immediate_sweep: true)
    end

    # Force a fresh parse of the option configs for every active definition, with the
    # query cache disabled so repeated identical SQL always hits the database.
    # Returns the number of definitions parsed, for reporting.
    def parse_all_active_option_configs
      count = 0
      ActiveRecord::Base.uncached do
        defs = [ExternalIdentifier, DynamicModel, ActivityLog].flat_map do |klass|
          klass.active_model_configurations.to_a
        end

        defs.each do |d|
          next if d.disabled?

          d.force_option_config_parse(raise_bad_configs: false)
        end

        count = defs.length
      end
      count
    end

    # Reset caches, time a single cold parse, and record the result.
    def record_timed_run(label)
      reset_all_dynamic_def_memos!

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      definition_count = parse_all_active_option_configs
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

      @timings << elapsed
      puts format('  [startup-timing] %<label>s: %<elapsed>.3fs (%<count>d definitions)',
                  label: label, elapsed: elapsed, count: definition_count)
    end

    # Each run is a separate example to isolate the ActiveRecord query-cache scope.
    it('run 1: records the cold parse time for all active option configs (no expectation)') do
      record_timed_run('run 1')
    end

    it('run 2: records the cold parse time for all active option configs (no expectation)') do
      record_timed_run('run 2')
    end

    it('run 3: records the cold parse time for all active option configs (no expectation)') do
      record_timed_run('run 3')
    end
  end
end
