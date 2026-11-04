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
#
# Issue #1481 (Stage C): warm markers follow the masters skeleton's structural signature,
# so definition config edits skip while set, chrome, and access changes re-warm. They also
# follow the cache epoch, which changes on any whole-cache clear and leaves fragment caches cold.
# A re-run skips unchanged state and re-warms after a genuine content change.

require 'rails_helper'

RSpec.describe Prewarm::Runner do
  let(:user_one) { instance_double(User, id: 1) }
  let(:user_two) { instance_double(User, id: 2) }
  let(:app_type) { instance_double(Admin::AppType, id: 10) }
  let(:cache_helper) { double }

  before do
    allow(Prewarm::Candidates).to receive(:representatives).and_return([[user_one, app_type], [user_two, app_type]])
    allow(HandlebarsPrecompiler).to receive(:setup_directories)
    allow(HandlebarsPrecompiler).to receive(:tmp_generation_dir)
      .and_return(Pathname.new(Dir.mktmpdir('prewarm_runner_spec')))
    allow(ApplicationController).to receive(:helpers).and_return(cache_helper)
    allow(cache_helper).to receive(:master_templates_skeleton_cache_signature)
      .with(app_type_id: app_type.id).and_return('skeleton-v1')
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

  it 'forces Application.handlebars_generation_version to the given value before warming' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    allow(Prewarm::MasterTemplates).to receive(:render_for).and_return('<html/>')
    original = Application.handlebars_generation_version

    described_class.run(handlebars_generation_version: 'parent-generation-value')

    expect(Application.handlebars_generation_version).to eq('parent-generation-value')
  ensure
    Application.handlebars_generation_version = original
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

  describe '#warm_marker_path' do
    before do
      allow(HandlebarsPrecompiler).to receive(:item_updates_key).and_return('definitions-v1')
      allow(HandlebarsPrecompiler).to receive(:app_type_access_control_timestamps)
        .with(app_type.id).and_return(['role-v1', 'uac-v1'])
    end

    it 'is stable for an unchanged definition and access-control state' do
      first_path = described_class.new.send(:warm_marker_path, user_one, app_type)
      second_path = described_class.new.send(:warm_marker_path, user_one, app_type)

      expect(second_path).to eq(first_path)
    end

    it 'changes when the masters skeleton signature changes' do
      signature = 'skeleton-v1'
      allow(cache_helper).to receive(:master_templates_skeleton_cache_signature) do
        signature
      end
      first_path = described_class.new.send(:warm_marker_path, user_one, app_type)

      signature = 'skeleton-v2'
      second_path = described_class.new.send(:warm_marker_path, user_one, app_type)

      expect(second_path).not_to eq(first_path)
    end

    it 'changes when the whole Rails cache is cleared, since fragment caches are then cold' do
      first_path = described_class.new.send(:warm_marker_path, user_one, app_type)

      Application.clear_cache_preserving_generation
      second_path = described_class.new.send(:warm_marker_path, user_one, app_type)

      expect(second_path).not_to eq(first_path)
    end

    it 'uses the real masters skeleton signature and cache epoch in the marker path' do
      allow(ApplicationController).to receive(:helpers).and_call_original
      allow(HandlebarsPrecompiler).to receive(:app_type_access_control_timestamps).and_call_original
      actual_app_type = Admin::AppType.active.first!
      signature = ApplicationController.helpers.master_templates_skeleton_cache_signature(
        app_type_id: actual_app_type.id
      )
      expected_version = Digest::SHA256.hexdigest([signature, Application.cache_epoch].join('-'))[0..31]

      marker = described_class.new.send(:warm_marker_path, user_one, actual_app_type)

      expect(marker.basename.to_s).to eq("#{user_one.id}-#{actual_app_type.id}-#{expected_version}")
    end
  end

  it 'skips unchanged warm state and re-warms after the skeleton signature changes' do
    allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_yield
    signature = 'skeleton-v1'
    allow(cache_helper).to receive(:master_templates_skeleton_cache_signature) { signature }
    expect(Prewarm::MasterTemplates).to receive(:render_for).exactly(4).times.and_return('<html/>')

    first_pass = described_class.run
    unchanged_pass = described_class.run
    signature = 'skeleton-v2'
    changed_pass = described_class.run

    expect(first_pass[:warmed]).to eq(2)
    expect(unchanged_pass[:skipped]).to eq(2)
    expect(changed_pass[:warmed]).to eq(2)
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
