# frozen_string_literal: true

# Prewarm::Runner unit tests (issue #1362 Stage 2, Phase 3).
#
# The runner is invoked either manually (`rake prewarm:templates`) or by Prewarm::Spawner
# on server boot. It must never block a real user request: a contended pass is a no-op,
# not a wait, and one failing candidate must not abort the rest of the pass.
#
# An optional server_cache_version: forces this process's Application.server_cache_version
# to match the value the spawning parent process already had (issue #1362 follow-up) -
# needed because a spawned child is a SEPARATE OS process, and Rails.cache is not
# guaranteed to be shared across processes (e.g. :memory_store is per-process), so without
# this the child could independently compute a DIFFERENT value than its parent, causing
# the Handlebars generation key to diverge and every warmed artifact to land in a
# generation the real web process never uses.

require 'rails_helper'

RSpec.describe Prewarm::Runner do
  let(:user_one) { instance_double(User, id: 1) }
  let(:user_two) { instance_double(User, id: 2) }
  let(:app_type) { instance_double(Admin::AppType, id: 10) }

  before do
    allow(Prewarm::Candidates).to receive(:representatives).and_return([[user_one, app_type], [user_two, app_type]])
    allow(HandlebarsPrecompiler).to receive(:setup_directories)
    allow(HandlebarsPrecompiler).to receive(:tmp_generation_dir)
      .and_return(Pathname.new(Dir.mktmpdir('prewarm_runner_spec')))
  end

  it 'is a no-op when the pass lock is contended' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire)
      .with('prewarm-pass', wait: 0, on_contention: :skip).and_return(nil)

    expect(Prewarm::MasterTemplates).not_to receive(:render_for)

    described_class.run
  end

  it 'forces Application.server_cache_version to the given value before warming' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    allow(Prewarm::MasterTemplates).to receive(:render_for).and_return('<html/>')
    original = Application.server_cache_version

    described_class.run(server_cache_version: 'parent-process-value')

    expect(Application.server_cache_version).to eq('parent-process-value')
  ensure
    Application.server_cache_version = original
  end

  it 'leaves Application.server_cache_version untouched when none is given' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    allow(Prewarm::MasterTemplates).to receive(:render_for).and_return('<html/>')
    existing = Application.server_cache_version

    described_class.run

    expect(Application.server_cache_version).to eq(existing)
  end

  it 'logs a start-of-pass line before warming anything, and the candidate count' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    allow(Prewarm::MasterTemplates).to receive(:render_for).and_return('<html/>')
    allow(Rails.logger).to receive(:info)

    expect(Rails.logger).to receive(:info).with('Prewarm::Runner: starting pass over 2 candidate(s)')

    described_class.run
  end

  it 'logs each successful warm with its elapsed time' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    allow(Prewarm::MasterTemplates).to receive(:render_for).and_return('<html/>')
    allow(Rails.logger).to receive(:info)

    expect(Rails.logger).to receive(:info)
      .with(/\APrewarm::Runner: warmed user=#{user_one.id} app_type=#{app_type.id} in \d+(\.\d+)?s\z/)
    expect(Rails.logger).to receive(:info)
      .with(/\APrewarm::Runner: warmed user=#{user_two.id} app_type=#{app_type.id} in \d+(\.\d+)?s\z/)

    described_class.run
  end

  it 'includes the total elapsed time of the pass in the returned summary' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    allow(Prewarm::MasterTemplates).to receive(:render_for).and_return('<html/>')

    result = described_class.run

    expect(result[:elapsed_seconds]).to be_a(Numeric)
    expect(result[:elapsed_seconds]).to be >= 0
  end

  it 'warms every representative and writes a marker per combination' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield

    expect(Prewarm::MasterTemplates).to receive(:render_for).with(user_one, app_type).and_return('<html/>')
    expect(Prewarm::MasterTemplates).to receive(:render_for).with(user_two, app_type).and_return('<html/>')

    result = described_class.run

    expect(result[:warmed]).to eq(2)
    expect(result[:failed]).to eq(0)
  end

  it 'skips a combination that already has a warm marker, without re-rendering' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield

    expect(Prewarm::MasterTemplates).to receive(:render_for).with(user_one, app_type).once.and_return('<html/>')
    expect(Prewarm::MasterTemplates).to receive(:render_for).with(user_two, app_type).once.and_return('<html/>')

    described_class.run
    result = described_class.run

    expect(result[:skipped]).to eq(2)
  end

  it 'continues the pass when one combination raises, without aborting the rest' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield

    expect(Prewarm::MasterTemplates).to receive(:render_for).with(user_one, app_type).and_raise('boom')
    expect(Prewarm::MasterTemplates).to receive(:render_for).with(user_two, app_type).and_return('<html/>')

    result = described_class.run

    expect(result[:failed]).to eq(1)
    expect(result[:warmed]).to eq(1)
  end
end
