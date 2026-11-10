# frozen_string_literal: true

# HandlebarsPrecompiler::FileLock Spec (issue #1362, Stage 1)
#
# Tests the flock-based, single-server lock used to avoid duplicate node-CLI
# compilation work when several processes/threads try to produce the same
# Handlebars artifact at once.
#
# The lock is a WORK-DUPLICATION OPTIMISATION, not a correctness mechanism (writes
# are atomic and filenames are deterministic - see handlebars_precompiler_helper_spec.rb).
# Coverage:
# - mutual exclusion across threads for the same lock name (real flock, separate
#   File objects, since each File.open creates its own open file description)
# - on_contention: :proceed runs the block unlocked after a short bounded wait,
#   rather than waiting indefinitely for the holder to finish
# - on_contention: :skip returns nil without running the block when contended
# - re-entrant calls for the same lock name from the same thread do not deadlock
# - lock files live under tmp/, never under public/
# - a failure to open/lock the lock file itself (e.g. disk full, permissions) degrades
#   to running the block unlocked rather than raising - the lock must never be able to
#   take compilation down (issue #1362, Stage 1 fail-open fix)

require 'rails_helper'

RSpec.describe HandlebarsPrecompiler::FileLock do
  describe '.acquire' do
    it 'returns the block value when the lock is acquired immediately' do
      result = described_class.acquire("simple-#{SecureRandom.hex(4)}") { 42 }

      expect(result).to eq(42)
    end

    it 'creates lock files under tmp/, never under public/' do
      name = "loc-check-#{SecureRandom.hex(4)}"

      described_class.acquire(name) { true }

      expect(described_class::LOCK_DIR.to_s).to start_with(Rails.root.join('tmp').to_s)
      public_lock_files = Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('**', '*lock*'))
      expect(public_lock_files).to be_empty
    end

    it 'only allows one thread at a time to run the block while holding the lock' do
      name = "excl-#{SecureRandom.hex(4)}"
      active = 0
      max_active = 0
      mutex = Mutex.new

      threads = Array.new(4) do
        Thread.new do
          described_class.acquire(name, wait: 2, on_contention: :skip) do
            mutex.synchronize do
              active += 1
              max_active = [max_active, active].max
            end
            sleep 0.05
            mutex.synchronize { active -= 1 }
          end
        end
      end
      threads.each(&:join)

      expect(max_active).to eq(1)
    end

    it 'runs the block unlocked after the wait timeout when on_contention: :proceed' do
      name = "proceed-#{SecureRandom.hex(4)}"
      holder_ready = Queue.new
      release = Queue.new

      holder = Thread.new do
        described_class.acquire(name, wait: 5) do
          holder_ready << true
          release.pop
        end
      end
      holder_ready.pop

      ran = false
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      described_class.acquire(name, wait: 0.2, on_contention: :proceed) { ran = true }
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      release << true
      holder.join

      expect(ran).to be true
      expect(elapsed).to be < 1
    end

    it 'does not run the block when on_contention: :skip and the lock is contended' do
      name = "skip-#{SecureRandom.hex(4)}"
      holder_ready = Queue.new
      release = Queue.new

      holder = Thread.new do
        described_class.acquire(name, wait: 5) do
          holder_ready << true
          release.pop
        end
      end
      holder_ready.pop

      ran = false
      result = described_class.acquire(name, wait: 0.2, on_contention: :skip) { ran = true }

      release << true
      holder.join

      expect(ran).to be false
      expect(result).to be_nil
    end

    it 'does not deadlock when the same thread re-enters the same lock name' do
      name = "reentrant-#{SecureRandom.hex(4)}"
      inner_ran = false

      result = described_class.acquire(name, wait: 1) do
        described_class.acquire(name, wait: 1) do
          inner_ran = true
          :inner_result
        end
      end

      expect(inner_ran).to be true
      expect(result).to eq(:inner_result)
    end

    it 'releases the lock after the block completes so a subsequent acquire is immediate' do
      name = "release-#{SecureRandom.hex(4)}"

      described_class.acquire(name) { true }

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      described_class.acquire(name, wait: 5) { true }
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      expect(elapsed).to be < 1
    end

    it 'releases the lock even if the block raises' do
      name = "raise-#{SecureRandom.hex(4)}"

      expect do
        described_class.acquire(name) { raise 'boom' }
      end.to raise_error('boom')

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      described_class.acquire(name, wait: 5) { true }
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      expect(elapsed).to be < 1
    end

    context 'when the lock mechanics themselves fail (issue #1362 fail-open fix)' do
      it 'runs the block unlocked and logs a warning if the lock file cannot be opened' do
        allow(File).to receive(:open).and_raise(Errno::ENOSPC, 'no space left on device')
        expect(Rails.logger).to receive(:warn).with(/lock/i)

        result = described_class.acquire('io-error-open') { :ran_anyway }

        expect(result).to eq(:ran_anyway)
      end

      it 'runs the block unlocked and logs a warning if the lock directory cannot be created' do
        allow(FileUtils).to receive(:mkdir_p).and_call_original
        allow(FileUtils).to receive(:mkdir_p).with(described_class::LOCK_DIR).and_raise(Errno::EACCES, 'permission denied')
        expect(Rails.logger).to receive(:warn).with(/lock/i)

        result = described_class.acquire('io-error-mkdir') { :ran_anyway }

        expect(result).to eq(:ran_anyway)
      end

      it 'runs the block unlocked and logs a warning if flock itself raises' do
        allow_any_instance_of(File).to receive(:flock).and_raise(Errno::EIO, 'input/output error')
        expect(Rails.logger).to receive(:warn).with(/lock/i)

        result = described_class.acquire('io-error-flock') { :ran_anyway }

        expect(result).to eq(:ran_anyway)
      end

      it 'proceeds even when on_contention: :skip, since infra failure is not the same as real contention' do
        allow(File).to receive(:open).and_raise(Errno::ENOSPC, 'no space left on device')
        allow(Rails.logger).to receive(:warn)

        ran = false
        described_class.acquire('io-error-skip-semantics', on_contention: :skip) { ran = true }

        expect(ran).to be true
      end
    end

    context 'when the protected block itself raises a SystemCallError/IOError (issue #1362 B1 fix)' do
      it 'runs the block exactly once and propagates the error, rather than retrying it unlocked' do
        name = "block-raises-#{SecureRandom.hex(4)}"
        call_count = 0

        expect do
          described_class.acquire(name) do
            call_count += 1
            raise Errno::ENOSPC, 'disk full during compile'
          end
        end.to raise_error(Errno::ENOSPC)

        expect(call_count).to eq(1)
      end

      it 'does not log a misleading "could not lock" warning for an error raised by the block itself' do
        name = "block-raises-warn-#{SecureRandom.hex(4)}"
        expect(Rails.logger).not_to receive(:warn)

        expect do
          described_class.acquire(name) { raise Errno::EIO, 'input/output error' }
        end.to raise_error(Errno::EIO)
      end

      it 'still releases the lock so a subsequent acquire is immediate' do
        name = "block-raises-release-#{SecureRandom.hex(4)}"

        expect do
          described_class.acquire(name) { raise Errno::ENOSPC, 'boom' }
        end.to raise_error(Errno::ENOSPC)

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        described_class.acquire(name, wait: 5) { true }
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

        expect(elapsed).to be < 1
      end
    end
  end
end
