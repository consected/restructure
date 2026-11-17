# frozen_string_literal: true

# Covers nested import state and system-wide actions deferred until the outermost import finishes.
require 'rails_helper'

RSpec.describe Admin::AppTypeImport, type: :model do
  let(:importer) { double('app type importer') }

  def save_regenerated_definition
    definition = DynamicModel.new(
      name: "route_load_test_#{SecureRandom.hex(4)}",
      table_name: "route_load_test_#{SecureRandom.hex(4)}s",
      schema_name: 'dynamic_test'
    )
    definition.instance_variable_set(:@regenerate, true)
    allow(definition).to receive(:ready_to_generate?).and_return(false)
    %i[check_implementation_class add_master_association add_user_access_controls
       reset_active_model_configurations! handle_config_triggers update_tracker_events
       clean_schema other_regenerate_actions reload_routes_after_definition_change].each do |callback|
      allow(definition).to receive(callback)
    end
    definition.save!(validate: false)
  end

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
        else
          expect(described_class.import_in_progress?).to be(true)
          expect(described_class.prevent_migrations?).to be(false)
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

    it 'keeps import state and deferred actions scoped to the current thread' do
      a_started = Queue.new
      release_a = Queue.new
      action_thread = nil
      allow(importer).to receive(:do_import_config) do
        a_started << true
        release_a.pop
        [:imported_a]
      end

      a_thread = Thread.new { described_class.import_config('A', nil) }
      begin
        a_started.pop
        expect(described_class.import_in_progress?).to be(false)
        described_class.run_now_or_after_import(:thread_b_action) { action_thread = Thread.current }
      ensure
        release_a << true
        a_thread.value
      end

      expect(action_thread).to equal(Thread.current)
      expect(described_class.import_in_progress?).to be(false)
    end

    it 'drains concurrent imports only on their own threads' do
      importers = { 'A' => double('import A'), 'B' => double('import B') }
      allow(described_class).to receive(:new) do |config_text, _admin, **_options|
        importers.fetch(config_text)
      end
      started = Queue.new
      release = Queue.new
      calls = { 'A' => [], 'B' => [] }
      completed_state = {}

      importers.each do |name, importer|
        allow(importer).to receive(:do_import_config) do
          described_class.run_now_or_after_import(:shared) { calls[name] << :drained }
          started << true
          release.pop
          [:imported]
        end
      end

      threads = importers.keys.index_with do |name|
        Thread.new do
          described_class.import_config(name, nil)
          completed_state[name] = described_class.import_in_progress?
        end
      end

      begin
        2.times { started.pop }
      ensure
        2.times { release << true }
        threads.each_value(&:value)
      end

      expect(calls).to eq('A' => [:drained], 'B' => [:drained])
      expect(completed_state).to eq('A' => false, 'B' => false)
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

    it 'removes the thread scope after a deferred action raises' do
      allow(importer).to receive(:do_import_config) do
        described_class.run_now_or_after_import(:failure) { raise 'deferred failure' }
        [:imported]
      end

      described_class.import_config('config', nil)
      expect(described_class.import_in_progress?).to be(false)

      calls = []
      described_class.run_now_or_after_import(:after_failure) { calls << :ran }
      expect(calls).to eq([:ran])
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

    it 'loads routes once per definition class after an import regenerates definitions' do
      allow(DynamicModel).to receive(:routes_load)
      allow(importer).to receive(:do_import_config) do
        3.times { save_regenerated_definition }
        expect(DynamicModel).not_to have_received(:routes_load)
        [:imported]
      end

      described_class.import_config('config', nil)

      expect(DynamicModel).to have_received(:routes_load).once
    end

    it 'loads routes immediately outside an import' do
      allow(DynamicModel).to receive(:routes_load)

      save_regenerated_definition

      expect(DynamicModel).to have_received(:routes_load).once
    end
  end
end
