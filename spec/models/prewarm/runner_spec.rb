# frozen_string_literal: true

# Prewarm::Runner unit tests (issue #1362 Stage 2, Phase 3).
#
# The runner is invoked either manually (`rake prewarm:templates`) or by Prewarm::Spawner
# on server boot. It must never block a real user request: a contended pass is a no-op,
# not a wait, and one failing candidate must not abort the rest of the pass.

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
