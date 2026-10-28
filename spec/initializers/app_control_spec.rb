# frozen_string_literal: true

# AppControl Initializer Spec
#
# Dynamic definitions were generated twice on every boot and development reload: once when
# Master's class body (or the routes reload after a class unload) called AppControl.define_models,
# and again from the to_prepare block. AppControl.prepare_models must only run define_models if
# it has not already run since the last class unload (or since boot).
#
# Test Coverage:
# - Boot: loading Master runs define_models once and prepare_models does not run it again
# - Master already loaded and no run since the last unload: prepare_models runs it once
# - Dev reload: a run between class_unload callbacks and prepare_models (routes) is not repeated
# - Running the reloader's class_unload callbacks resets tracking, so prepare_models runs it again
# - A re-entrant call blocked by the currently-defining guard does not count as a run
# - The completed marker is set only after generation and forward-reference repair finish, so the
#   definition load issue report is not built from mid-run state
# - defining_models? is true only while a run is in progress, including when a run fails
# - The class unload callbacks reset the completed marker along with the attempted marker

require 'rails_helper'

RSpec.describe AppControl do
  def run_class_unload_callbacks
    Rails.application.reloader.new.run_callbacks(:class_unload)
  end

  before do
    described_class.reset_define_models_attempted
    allow(ActivityLog).to receive(:define_models)
    allow(Dynamic::DefGenerator).to receive(:resolve_cached_forward_references!)
  end

  after do
    described_class.reset_define_models_attempted
  end

  describe '.prepare_models' do
    it 'does not run define_models again when loading Master already ran it (boot)' do
      allow(described_class).to receive(:require_dependency).with('master') do
        described_class.define_models
      end

      described_class.prepare_models

      expect(ActivityLog).to have_received(:define_models).once
    end

    it 'runs define_models once when Master was already loaded and nothing has run since the last unload' do
      allow(described_class).to receive(:require_dependency).with('master')

      described_class.prepare_models

      expect(ActivityLog).to have_received(:define_models).once
    end

    it 'does not run define_models again when it ran after class_unload callbacks and before prepare (dev reload)' do
      allow(described_class).to receive(:require_dependency).with('master')

      described_class.define_models # initial boot
      run_class_unload_callbacks
      described_class.define_models # routes reload autoloads Master
      described_class.prepare_models

      expect(ActivityLog).to have_received(:define_models).twice
    end

    it 'runs define_models once after class_unload callbacks when nothing has run since' do
      allow(described_class).to receive(:require_dependency).with('master')

      described_class.define_models
      run_class_unload_callbacks
      described_class.prepare_models

      expect(ActivityLog).to have_received(:define_models).twice
    end

    it 'runs define_models only once across repeated prepare calls without an unload' do
      allow(described_class).to receive(:require_dependency).with('master')

      described_class.prepare_models
      described_class.prepare_models

      expect(ActivityLog).to have_received(:define_models).once
    end
  end

  describe '.define_models' do
    it 'marks that model definition was attempted' do
      expect { described_class.define_models }
        .to change(described_class, :define_models_attempted_since_unload?).from(false).to(true)
    end

    it 'does not mark a re-entrant call blocked by the guard as an attempt' do
      defined_after_reentrant_call = nil
      allow(ActivityLog).to receive(:define_models) do
        described_class.reset_define_models_attempted
        described_class.define_models
        defined_after_reentrant_call = described_class.define_models_attempted_since_unload?
      end

      described_class.define_models

      expect(defined_after_reentrant_call).to be false
    end

    it 'does not retry a failed generation from prepare_models without an unload' do
      allow(ActivityLog).to receive(:define_models).and_raise(StandardError, 'generation failed')
      allow(described_class).to receive(:require_dependency).with('master')

      expect { described_class.define_models }.not_to raise_error
      described_class.prepare_models

      expect(ActivityLog).to have_received(:define_models).once
    end

    it 'runs forward-reference resolution once after model generation' do
      expect(ActivityLog).to receive(:define_models).ordered
      expect(Dynamic::DefGenerator).to receive(:resolve_cached_forward_references!).once.ordered

      described_class.define_models
    end

    it 'marks the run completed only after forward-reference resolution' do
      completed_during_run = []
      allow(ActivityLog).to receive(:define_models) do
        completed_during_run << described_class.define_models_completed_since_unload?
      end
      allow(Dynamic::DefGenerator).to receive(:resolve_cached_forward_references!) do
        completed_during_run << described_class.define_models_completed_since_unload?
      end

      expect { described_class.define_models }
        .to change(described_class, :define_models_completed_since_unload?).from(false).to(true)
      expect(completed_during_run).to eq [false, false]
    end

    it 'does not mark a failed run as completed, and clears the in-progress state' do
      allow(ActivityLog).to receive(:define_models).and_raise(StandardError, 'generation failed')

      described_class.define_models

      expect(described_class.define_models_completed_since_unload?).to be false
      expect(described_class.defining_models?).to be false
    end

    it 'reports a run in progress through defining_models?' do
      during_run = nil
      allow(ActivityLog).to receive(:define_models) { during_run = described_class.defining_models? }

      expect(described_class.defining_models?).to be false
      described_class.define_models

      expect(during_run).to be true
      expect(described_class.defining_models?).to be false
    end
  end

  describe 'class unload callback' do
    it 'resets the attempted and completed markers when class_unload callbacks run' do
      described_class.define_models
      expect(described_class.define_models_completed_since_unload?).to be true

      run_class_unload_callbacks

      expect(described_class.define_models_attempted_since_unload?).to be false
      expect(described_class.define_models_completed_since_unload?).to be false
    end

    it 'resets the attempted marker when class_unload callbacks run' do
      described_class.define_models

      expect { run_class_unload_callbacks }
        .to change(described_class, :define_models_attempted_since_unload?).from(true).to(false)
    end
  end
end
