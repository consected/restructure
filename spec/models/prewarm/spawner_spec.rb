# frozen_string_literal: true

# Prewarm::Spawner unit tests (issue #1362 Stage 2, Phase 4).
#
# The spawner decides WHETHER an automatic prewarm pass runs at all (a manually-invoked
# `rake prewarm:templates` always runs regardless - see Prewarm::Runner). It must never
# run inside the delayed_job worker or a console/runner process (both share disk with the
# web server on Elastic Beanstalk, and must not spawn their own competing pass), and a
# real subprocess is never spawned in these specs - IO.popen is always stubbed.

require 'rails_helper'

RSpec.describe Prewarm::Spawner do
  let(:fake_io) { instance_double(IO, pid: 4242, each_line: nil, close: nil, closed?: true) }

  before do
    allow(IO).to receive(:popen).and_return(fake_io)
    allow(::Process).to receive(:detach)
    allow(HandlebarsPrecompiler).to receive(:delayed_job_worker?).and_return(false)
    allow(HandlebarsPrecompiler).to receive(:rails_console_or_runner?).and_return(false)
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
  end

  it 'spawns a detached rake prewarm:templates process when enabled' do
    change_setting('PrewarmTemplatesEnabled', true)

    described_class.spawn_async

    expect(IO).to have_received(:popen)
      .with(anything, %w[bundle exec rake prewarm:templates], hash_including(chdir: Rails.root.to_s))
    expect(::Process).to have_received(:detach).with(4242)
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end

  it "passes the parent process's current Application.server_cache_version to the child via env" do
    change_setting('PrewarmTemplatesEnabled', true)
    current_version = Application.server_cache_version

    described_class.spawn_async

    expect(IO).to have_received(:popen)
      .with({ 'PREWARM_SERVER_CACHE_VERSION' => current_version }, anything, anything)
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end

  it 'logs the child pid when it spawns' do
    change_setting('PrewarmTemplatesEnabled', true)

    expect(Rails.logger).to receive(:info).with(/Prewarm::Spawner: spawned rake prewarm:templates.*pid=4242/)

    described_class.spawn_async
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end

  it 'does not raise, and logs a warning, when IO.popen itself fails' do
    change_setting('PrewarmTemplatesEnabled', true)
    allow(IO).to receive(:popen).and_raise(Errno::ENOENT, 'bundle')

    expect(Rails.logger).to receive(:warn).with(/Prewarm::Spawner: failed to spawn/)

    expect { described_class.spawn_async }.not_to raise_error
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end

  it 'does nothing when disabled' do
    change_setting('PrewarmTemplatesEnabled', false)

    described_class.spawn_async

    expect(IO).not_to have_received(:popen)
  end

  it 'does nothing in the delayed_job worker' do
    change_setting('PrewarmTemplatesEnabled', true)
    allow(HandlebarsPrecompiler).to receive(:delayed_job_worker?).and_return(true)

    described_class.spawn_async

    expect(IO).not_to have_received(:popen)
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end

  it 'does nothing in a console/runner process' do
    change_setting('PrewarmTemplatesEnabled', true)
    allow(HandlebarsPrecompiler).to receive(:rails_console_or_runner?).and_return(true)

    described_class.spawn_async

    expect(IO).not_to have_received(:popen)
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end

  it 'does not spawn a second time while the spawn lock is contended' do
    change_setting('PrewarmTemplatesEnabled', true)
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_return(nil)

    described_class.spawn_async

    expect(IO).not_to have_received(:popen)
  ensure
    change_setting('PrewarmTemplatesEnabled', false)
  end
end
