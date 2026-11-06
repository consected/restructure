# frozen_string_literal: true

# Covers nested import state and system-wide actions deferred until the outermost import finishes.
require 'rails_helper'

RSpec.describe Admin::AppTypeImport, type: :model do
  let(:importer) { double('app type importer') }

  before do
    allow(described_class).to receive(:new).and_return(importer)
  end

  describe '.import_config' do
    it 'keeps import state active through nested imports and restores prevent_migrations' do
      allow(Rails.cache).to receive(:clear)
      import_depth = 0
      allow(importer).to receive(:do_import_config) do
        import_depth += 1
        if import_depth == 1
          described_class.import_config('nested', nil, prevent_migrations: false)
          expect(described_class.import_in_progress?).to be(true)
          expect(described_class.prevent_migrations?).to be(true)
        end
        import_depth -= 1
        [:imported]
      end

      expect(described_class.import_config('outer', nil, prevent_migrations: true)).to eq([:imported])
      expect(described_class.import_in_progress?).to be(false)
      expect(described_class.prevent_migrations?).to be(false)
      expect(Rails.cache).to have_received(:clear).once
    end

    it 'drains each deferred action once and runs actions registered while draining in a later pass' do
      calls = []
      allow(importer).to receive(:do_import_config) do
        described_class.run_now_or_after_import(:shared) do
          expect(described_class.import_in_progress?).to be(true)
          calls << :first
          described_class.run_now_or_after_import(:during_drain) { calls << :during_drain }
        end
        described_class.run_now_or_after_import(:shared) { calls << :duplicate }
        expect(calls).to be_empty
        [:imported]
      end

      described_class.import_config('config', nil)

      expect(calls).to eq(%i[first during_drain])
    end

    it 'preserves depth and deferred actions when imports overlap during draining' do
      importers = { 'A' => double('import A'), 'B' => double('import B') }
      allow(described_class).to receive(:new) do |config_text, _admin, **_options|
        importers.fetch(config_text)
      end
      b_started = Queue.new
      release_b = Queue.new
      b_calls = []
      b_thread = nil
      b_active_after_a = nil
      b_depth_after_a = nil

      allow(importers['A']).to receive(:do_import_config) do
        described_class.run_now_or_after_import(:start_import_b) do
          b_thread = Thread.new { described_class.import_config('B', nil) }
          b_started.pop
        end
        [:imported_a]
      end
      allow(importers['B']).to receive(:do_import_config) do
        described_class.run_now_or_after_import(:b_first_action) { b_calls << :first }
        b_started << true
        release_b.pop
        b_active_after_a = described_class.import_in_progress?
        b_depth_after_a = described_class.instance_variable_get(:@import_depth)
        described_class.run_now_or_after_import(:b_late_action) { b_calls << :late }
        [:imported_b]
      end

      begin
        described_class.import_config('A', nil)
      ensure
        release_b << true
        b_thread&.value
      end

      expect(b_active_after_a).to be(true)
      expect(b_depth_after_a).to eq(1)
      expect(b_calls).to eq(%i[first late])
      expect(described_class.import_in_progress?).to be(false)
      expect(described_class.instance_variable_get(:@import_depth)).to eq(0)
    end

    it 'runs actions immediately when no import is active' do
      calls = []

      described_class.run_now_or_after_import(:immediate) { calls << :ran }

      expect(calls).to eq([:ran])
    end

    it 'logs deferred action errors and continues draining without changing the import result' do
      calls = []
      allow(Rails.logger).to receive(:error)
      allow(importer).to receive(:do_import_config) do
        described_class.run_now_or_after_import(:failure) { raise 'deferred failure' }
        described_class.run_now_or_after_import(:success) { calls << :success }
        [:imported]
      end

      result = described_class.import_config('config', nil)

      expect(result).to eq([:imported])
      expect(calls).to eq([:success])
      expect(Rails.logger).to have_received(:error).with(/deferred failure/)
    end

    it 'reloads routes once when multiple definition classes request a reload' do
      allow(Rails.application.routes_reloader).to receive(:reload!)
      allow(importer).to receive(:do_import_config) do
        DynamicModel.new.send(:reload_routes_after_definition_change)
        ActivityLog.new.send(:reload_routes_after_definition_change)
        expect(Rails.application.routes_reloader).not_to have_received(:reload!)
        [:imported]
      end

      described_class.import_config('config', nil)

      expect(Rails.application.routes_reloader).to have_received(:reload!).once
    end
  end
end
