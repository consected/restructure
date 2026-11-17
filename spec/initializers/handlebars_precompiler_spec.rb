# frozen_string_literal: true

# HandlebarsPrecompiler Initializer Spec
#
# Tests the HandlebarsPrecompiler module that sets up directories, validates CLI availability,
# and cleans up compiled files on startup.
#
# Test Coverage:
# - CLI availability detection via `which handlebars` command
# - CLI path retrieval
# - Directory creation for tmp/handlebars and public/handlebars
# - Cleanup operations for temporary and compiled files
# - Environment-based flags for minification and source maps

require 'rails_helper'

RSpec.describe HandlebarsPrecompiler do
  describe '.cli_available?' do
    it 'returns true when handlebars CLI is installed' do
      # This test relies on npx handlebars being available in the dev environment
      expect(described_class.cli_available?).to be true
    end
  end

  describe '.cli_path' do
    it 'returns the path to the handlebars CLI' do
      path = described_class.cli_path

      expect(path).to be_a(String)
      expect(path).not_to be_empty
    end
  end

  describe '.setup_directories' do
    before do
      FileUtils.rm_rf(described_class::TMP_DIR)
      FileUtils.rm_rf(described_class::PUBLIC_DIR)
    end

    after do
      # Restore directories for other tests
      described_class.setup_directories
    end

    it 'creates the tmp/handlebars directory' do
      described_class.setup_directories

      expect(Dir.exist?(described_class::TMP_DIR)).to be true
    end

    it 'creates the public/handlebars directory' do
      described_class.setup_directories

      expect(Dir.exist?(described_class::PUBLIC_DIR)).to be true
    end
  end

  describe '.cleanup_tmp_dir' do
    before do
      described_class.setup_directories
      # Create test files in the subdirectories that cleanup_tmp_dir actually cleans
      FileUtils.touch(described_class::TEMPLATES_TMP_DIR.join('test1.tmp'))
      FileUtils.touch(described_class::PARTIALS_TMP_DIR.join('test2.tmp'))
    end

    it 'removes all files from templates and partials tmp directories' do
      described_class.cleanup_tmp_dir

      template_files = Dir.glob(described_class::TEMPLATES_TMP_DIR.join('*'))
      partial_files = Dir.glob(described_class::PARTIALS_TMP_DIR.join('*'))
      expect(template_files).to be_empty
      expect(partial_files).to be_empty
    end
  end

  # Issue #1362 (Stage 1) - the delayed_job worker process shares disk with the web process
  # on Elastic Beanstalk (see bin/delayed_job, which loads config/environment after
  # daemonizing). If it ran the same startup cleanup as a web process, ITS restart would
  # wipe the web server's compiled templates and rotate server_cache_version out from under
  # it mid-day. Only bin/delayed_job (via script/delayed_job) requires 'delayed/command'
  # before loading Rails - nothing else in the app does - making it a reliable signal.
  describe '.delayed_job_worker?' do
    it 'is false in a normal (web/test) process, where Delayed::Command is not required' do
      expect(described_class.delayed_job_worker?).to be false
    end

    it 'is true when Delayed::Command is defined (as it is inside bin/delayed_job)' do
      stub_const('Delayed::Command', Class.new)

      expect(described_class.delayed_job_worker?).to be true
    end
  end

  describe '.startup_cleanup!' do
    # Fix the generation key for the whole example (via `let` memoization) rather than
    # re-deriving it from `described_class.templates_compiled_dir` in each block - the real
    # key is DB-derived (see `item_updates_key`) and can drift mid-example under a
    # concurrently-running test suite sharing the same test database/memcached.
    let(:key) { described_class.generation_key }
    let(:compiled_dir) { described_class.templates_compiled_dir(key) }

    before do
      described_class.setup_directories
      FileUtils.mkdir_p(compiled_dir)
      FileUtils.touch(compiled_dir.join('leftover.js'))
      # Also simulate an in-flight web request's source tmp files (issue #1362 B2 fix):
      # these live under TEMPLATES_TMP_DIR/PARTIALS_TMP_DIR, shared with the delayed_job
      # process, and must be just as protected as the compiled output above.
      FileUtils.touch(described_class::TEMPLATES_TMP_DIR.join('in-flight.handlebars'))
    end

    it 'cleans up compiled and tmp output, and invalidates server_cache_version outside the delayed_job process' do
      allow(described_class).to receive(:delayed_job_worker?).and_return(false)
      expect(Rails.cache).to receive(:delete).with('server_cache_version')

      described_class.startup_cleanup!

      expect(Dir.glob(compiled_dir.join('*.js'))).to be_empty
      expect(Dir.glob(described_class::TEMPLATES_TMP_DIR.join('*'))).to be_empty
    end

    it 'does NOT clean up compiled/tmp output or invalidate server_cache_version inside the delayed_job process' do
      allow(described_class).to receive(:delayed_job_worker?).and_return(true)
      expect(Rails.cache).not_to receive(:delete).with('server_cache_version')

      described_class.startup_cleanup!

      expect(Dir.glob(compiled_dir.join('*.js'))).not_to be_empty
      expect(Dir.glob(described_class::TEMPLATES_TMP_DIR.join('*'))).not_to be_empty
    end

    it 'does NOT clean up compiled/tmp output or invalidate server_cache_version under rails console/runner' do
      allow(described_class).to receive(:delayed_job_worker?).and_return(false)
      allow(described_class).to receive(:rails_console_or_runner?).and_return(true)
      expect(Rails.cache).not_to receive(:delete).with('server_cache_version')

      described_class.startup_cleanup!

      expect(Dir.glob(compiled_dir.join('*.js'))).not_to be_empty
      expect(Dir.glob(described_class::TEMPLATES_TMP_DIR.join('*'))).not_to be_empty
    end
  end

  describe '.cleanup_compiled_output' do
    before do
      described_class.setup_directories
      # Generation-scoped compiled dirs are created on demand (issue #1362), not by
      # setup_directories - create them here to test cleanup_compiled_output in isolation.
      FileUtils.mkdir_p(described_class.templates_compiled_dir)
      FileUtils.mkdir_p(described_class.partials_compiled_dir)
      FileUtils.mkdir_p(described_class.multi_dir)
      # Create test files in the subdirectories that cleanup_compiled_output actually cleans
      FileUtils.touch(described_class.templates_compiled_dir.join('template-abc123.js'))
      FileUtils.touch(described_class.partials_compiled_dir.join('partial-def456.js'))
      FileUtils.touch(described_class.multi_dir.join('multi-abc123.js'))
    end

    it 'removes all .js files from templates public directory' do
      described_class.cleanup_compiled_output

      js_files = Dir.glob(described_class.templates_compiled_dir.join('*.js'))
      expect(js_files).to be_empty
    end

    it 'removes all .js files from partials public directory' do
      described_class.cleanup_compiled_output

      js_files = Dir.glob(described_class.partials_compiled_dir.join('*.js'))
      expect(js_files).to be_empty
    end

    it 'removes all .js files from multi public directory' do
      described_class.cleanup_compiled_output

      js_files = Dir.glob(described_class.multi_dir.join('*.js'))
      expect(js_files).to be_empty
    end

    # Issue #1362 S8 fix - servers upgraded from before generation-scoped directories
    # existed have compiled output left directly under PUBLIC_DIR (no "gen-" prefix),
    # which nothing else ever cleans up any more.
    it 'removes pre-issue-#1362 output left directly under PUBLIC_DIR (no gen- prefix)' do
      %w[templates partials multi].each do |dir|
        FileUtils.mkdir_p(described_class::PUBLIC_DIR.join(dir))
        FileUtils.touch(described_class::PUBLIC_DIR.join(dir, 'legacy.js'))
      end

      described_class.cleanup_compiled_output

      %w[templates partials multi].each do |dir|
        expect(Dir.exist?(described_class::PUBLIC_DIR.join(dir))).to be false
      end
    end
  end

  describe 'after_initialize callback' do
    it 'invalidates server_cache_version after cleaning up public dir' do
      # Write a known server_cache_version to cache
      Rails.cache.write('server_cache_version', 'old-version-123')
      expect(Rails.cache.read('server_cache_version')).to eq('old-version-123')

      # Simulate what the after_initialize block does
      described_class.cleanup_compiled_output
      Rails.cache.delete('server_cache_version')

      # The old value should no longer be in cache
      expect(Rails.cache.read('server_cache_version')).to be_nil

      # A new call to server_cache_version should generate a fresh value
      new_version = Application.server_cache_version
      expect(new_version).not_to eq('old-version-123')
    end
  end

  # Issue #1362 (Stage 1) - DISK GUARANTEE SPEC: bounds how many compiled-Handlebars
  # generations can accumulate on disk, regardless of how many times a dynamic
  # definition/config change rotates the generation key. Operates on fabricated generation
  # directories (with controlled mtimes) rather than real DB-driven rotations, so the sweep
  # LOGIC can be exercised precisely and quickly, independent of directory-creation timing.
  describe '.sweep_old_generations' do
    def make_generation(name, mtime:)
      FileUtils.mkdir_p(HandlebarsPrecompiler::TMP_DIR.join(name))
      FileUtils.mkdir_p(HandlebarsPrecompiler::PUBLIC_DIR.join(name))
      plain_mtime = mtime.to_time
      File.utime(plain_mtime, plain_mtime, HandlebarsPrecompiler::TMP_DIR.join(name))
      File.utime(plain_mtime, plain_mtime, HandlebarsPrecompiler::PUBLIC_DIR.join(name))
    end

    before do
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TMP_DIR.join('gen-*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('gen-*')))
    end

    it 'keeps only the current generation plus HandlebarsKeepGenerations previous ones' do
      now = Time.now
      # 5 generations, oldest to newest, well outside the mtime safety window
      old_far_back = 5.days.ago
      %w[gen-a gen-b gen-c gen-d].each_with_index do |name, i|
        make_generation(name, mtime: old_far_back + (i * 1.hour))
      end
      make_generation('gen-current', mtime: now)
      allow(described_class).to receive(:generation_key).and_return('current')

      described_class.sweep_old_generations

      remaining = described_class.existing_generation_dir_names
      expect(remaining.size).to eq(1 + Settings::HandlebarsKeepGenerations)
      expect(remaining).to include('gen-current')
    end

    it 'does not grow without bound as more generations are rotated through' do
      now = Time.now

      15.times do |i|
        make_generation("gen-rotation-#{i}", mtime: now - ((15 - i) * 1.hour))
        allow(described_class).to receive(:generation_key).and_return("rotation-#{i}")
        described_class.sweep_old_generations
      end

      expect(described_class.existing_generation_dir_names.size).to be <= (1 + Settings::HandlebarsKeepGenerations)
    end

    it 'never deletes the current generation, even if its mtime looks old' do
      make_generation('gen-current', mtime: 30.days.ago)
      %w[gen-a gen-b gen-c gen-d].each { |name| make_generation(name, mtime: Time.now) }
      allow(described_class).to receive(:generation_key).and_return('current')

      described_class.sweep_old_generations

      expect(described_class.existing_generation_dir_names).to include('gen-current')
    end

    it 'never deletes a generation created within the mtime safety window, even if the count is exceeded' do
      old_far_back = 5.days.ago
      %w[gen-a gen-b gen-c gen-d gen-e].each_with_index do |name, i|
        make_generation(name, mtime: old_far_back + (i * 1.hour))
      end
      make_generation('gen-just-created', mtime: Time.now)
      make_generation('gen-current', mtime: Time.now)
      allow(described_class).to receive(:generation_key).and_return('current')

      described_class.sweep_old_generations

      expect(described_class.existing_generation_dir_names).to include('gen-just-created')
    end

    it 'does nothing when only one generation exists' do
      make_generation('gen-only', mtime: Time.now)
      allow(described_class).to receive(:generation_key).and_return('only')

      expect { described_class.sweep_old_generations }.not_to raise_error
      expect(described_class.existing_generation_dir_names).to eq(['gen-only'])
    end

    # Issue #1362 S3 fix - the REAL opportunistic trigger only ever sweeps when the
    # current generation's directory does NOT exist yet (it's created moments later by
    # the same request - see HandlebarsPrecompilerHelper#maybe_sweep_old_handlebars_generations),
    # unlike the other examples above which fabricate 'gen-current' as already existing.
    it 'keeps exactly current + HandlebarsKeepGenerations when swept before the current dir exists' do
      old_far_back = 5.days.ago
      %w[gen-a gen-b gen-c gen-d].each_with_index do |name, i|
        make_generation(name, mtime: old_far_back + (i * 1.hour))
      end
      allow(described_class).to receive(:generation_key).and_return('current')
      # gen-current intentionally NOT created yet at sweep time

      described_class.sweep_old_generations
      make_generation('gen-current', mtime: Time.now) # created moments later, as in production

      remaining = described_class.existing_generation_dir_names
      expect(remaining.size).to eq(1 + Settings::HandlebarsKeepGenerations)
      expect(remaining).to include('gen-current')
    end
  end

  # Issue #1362 S2 fix - a generation's mtime must reflect the last time anything was
  # actually compiled/written into it, not just when its top-level directory was first
  # created (which never changes again, since writes always land in a subdirectory).
  describe '.generation_mtime' do
    it "reflects a write into a subdirectory, not just the generation directory's own creation time" do
      name = 'gen-mtime-check'
      FileUtils.mkdir_p(HandlebarsPrecompiler::TMP_DIR.join(name))
      old_mtime = 10.days.ago.to_time
      File.utime(old_mtime, old_mtime, HandlebarsPrecompiler::TMP_DIR.join(name))

      subdir = HandlebarsPrecompiler::TMP_DIR.join(name, 'compiled_templates')
      FileUtils.mkdir_p(subdir)
      FileUtils.touch(subdir.join('some-template.js'))

      expect(described_class.generation_mtime(name)).to be > 1.hour.ago.to_f
    end
  end

  # Issue #1362 S7 fix - HandlebarsPrecompiler::FileLock lock file names are per
  # user/app_type/template-set, so without a sweep they accumulate without bound on a
  # long-lived server.
  describe '.sweep_stale_lock_files' do
    before { FileUtils.mkdir_p(HandlebarsPrecompiler::FileLock::LOCK_DIR) }

    it 'removes lock files older than HandlebarsLockFileMaxAgeSeconds' do
      old_file = HandlebarsPrecompiler::FileLock::LOCK_DIR.join("old-lock-#{SecureRandom.hex(4)}")
      FileUtils.touch(old_file)
      old_mtime = (Settings::HandlebarsLockFileMaxAgeSeconds + 60).seconds.ago.to_time
      File.utime(old_mtime, old_mtime, old_file)

      described_class.sweep_stale_lock_files

      expect(File.exist?(old_file)).to be false
    end

    it 'keeps lock files younger than HandlebarsLockFileMaxAgeSeconds' do
      recent_file = HandlebarsPrecompiler::FileLock::LOCK_DIR.join("recent-lock-#{SecureRandom.hex(4)}")
      FileUtils.touch(recent_file)

      described_class.sweep_stale_lock_files

      expect(File.exist?(recent_file)).to be true
    end
  end

  # Issue #1362 S10 fix - `rails console`/`rails runner` are not dispatched via Rake, so
  # the existing rake_tasks guard never sees them, yet both commonly run against a live
  # box (see the app-wide `bundle exec rails runner` inspection pattern) and would
  # otherwise wipe the actual web server's compiled output.
  describe '.rails_console_or_runner?' do
    it 'is false for a normal (web/test) process' do
      expect(described_class.rails_console_or_runner?).to be false
    end

    it 'is true when ARGV starts with a console/runner subcommand' do
      %w[console c runner r].each do |cmd|
        stub_const('ARGV', [cmd, 'extra', 'args'])
        expect(described_class.rails_console_or_runner?).to be true
      end
    end

    it 'is false for the actual web server subcommands' do
      %w[server s].each do |cmd|
        stub_const('ARGV', [cmd])
        expect(described_class.rails_console_or_runner?).to be false
      end
    end
  end
end
