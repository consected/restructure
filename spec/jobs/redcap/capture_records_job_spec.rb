# frozen_string_literal: true

require 'rails_helper'

# Tests for Redcap::CaptureRecordsJob focusing on delayed_job serialization
# compatibility in Ruby 3.
#
# Root cause (issue #1137): When a job is queued via delayed_job in production,
# Active Job serializes keyword arguments as a plain symbol-keyed Hash. Ruby 3
# does NOT automatically convert a splatted positional Hash to keyword arguments,
# so `perform(*arguments)` with a Hash as the last element raises
# `ArgumentError: wrong number of arguments` for any method using Ruby keyword args.
# The fix is for perform() to use a plain optional Hash arg (opts = {}) instead
# of keyword arguments, which correctly accepts the splatted deserialized Hash.
RSpec.describe Redcap::CaptureRecordsJob, type: :job do
  include ModelSupport
  include Redcap::RedcapSupport

  describe '#perform signature - delayed_job / Ruby 3 compatibility' do
    it 'has an optional third positional argument, not Ruby keyword arguments' do
      # Verify the signature accepts a plain hash as the 3rd positional arg.
      # `parameters` returns :opt for optional positional, :key/:keyreq for kwargs.
      params = described_class.instance_method(:perform).parameters
      first_two_types = params[0..1].map(&:first)
      third_param_type = params[2]&.first

      expect(first_two_types).to all(eq(:req))
      expect(third_param_type).to eq(:opt), \
        'perform() must use `opts = {}` not keyword args to survive delayed_job deserialization in Ruby 3'
      expect(params.none? { |type, _| %i[key keyreq].include?(type) }).to be true
    end

    it 'raises ArgumentError (regression proof) when a method uses keyword args and receives a splatted Hash' do
      # Demonstrate that the old keyword-arg signature would fail in exactly this way.
      # Note: procs are lenient with kwargs in Ruby 3; lambdas (and defs) are strict.
      # Use a lambda to simulate the strict method behavior.
      old_signature = lambda { |_pa, _cn, ignore_cache: false, retrieve_all: false, verify_file_fields: false| nil }
      args_from_delayed_job = ['pa', 'cn', { ignore_cache: true, retrieve_all: true, verify_file_fields: true }]

      expect { old_signature.call(*args_from_delayed_job) }.to raise_error(ArgumentError)
    end
  end

  describe 'Active Job serialization roundtrip for opts' do
    before :all do
      create_admin
      @rc_project_configs = setup_redcap_project_admin_configs
      @project_admin = Redcap::ProjectAdmin.active.first
      @project_admin.current_admin = @admin
    end

    it 'preserves all opts values through serialize/deserialize (as delayed_job does)' do
      # Simulate what delayed_job does: serialize then deserialize job arguments.
      opts = { ignore_cache: true, retrieve_all: true, verify_file_fields: true }
      serialized = ActiveJob::Arguments.serialize([@project_admin, 'SomeClass', opts])
      deserialized = ActiveJob::Arguments.deserialize(serialized)

      deserialized_opts = deserialized.last
      expect(deserialized_opts).to be_a(Hash)
      expect(deserialized_opts[:ignore_cache]).to be true
      expect(deserialized_opts[:retrieve_all]).to be true
      expect(deserialized_opts[:verify_file_fields]).to be true
    end

    it 'does NOT raise ArgumentError when called with a splatted symbol-keyed Hash (simulates delayed_job roundtrip)' do
      # Active Job serializes kwargs into a symbol-keyed Hash stored in the arguments array.
      # The delayed_job worker later calls `perform(*arguments)`. In Ruby 3 this passes the
      # Hash as a positional arg - NOT as keyword args. This must not raise ArgumentError.
      # Note: the job body will raise FphsException (no DM configured for this project),
      # proving that argument unpacking succeeded - we are only checking for ArgumentError here.
      # The `not_to raise_error(ArgumentError)` pattern is intentional: we want to distinguish
      # ArgumentError (broken argument parsing) from FphsException (expected job-logic error).
      deserialized_opts = { ignore_cache: true, retrieve_all: true, verify_file_fields: false }
      job = described_class.new

      RSpec::Expectations.configuration.on_potential_false_positives = :nothing
      expect do
        job.perform(@project_admin, 'SomeClass', deserialized_opts)
      end.not_to raise_error(ArgumentError)
      RSpec::Expectations.configuration.on_potential_false_positives = :warn
    end

    it 'does not raise ArgumentError when splatting deserialized arguments into perform (full roundtrip)' do
      # Full roundtrip: serialize opts → deserialize → splat into perform().
      # This is exactly what delayed_job does in production.
      # Note: the job body will raise FphsException (no DM configured for this project),
      # proving that argument unpacking succeeded - we are only checking for ArgumentError here.
      # The `not_to raise_error(ArgumentError)` pattern is intentional: we want to distinguish
      # ArgumentError (broken argument parsing) from FphsException (expected job-logic error).
      opts = { ignore_cache: false, retrieve_all: true, verify_file_fields: true }
      serialized = ActiveJob::Arguments.serialize([@project_admin, 'SomeClass', opts])
      deserialized = ActiveJob::Arguments.deserialize(serialized)

      job = described_class.new
      RSpec::Expectations.configuration.on_potential_false_positives = :nothing
      expect do
        job.perform(*deserialized)
      end.not_to raise_error(ArgumentError)
      RSpec::Expectations.configuration.on_potential_false_positives = :warn
    end
  end

  # Tests for the job status set after a run completes without raising: distinguishes
  # a fully clean run ("manual run successful") from one where Redcap::DataRecords#errors
  # was non-empty ("manual run completed with errors"), per the completed_status helper
  # on Redcap::ProjectAdmin.
  describe 'status set after a completed pull' do
    before :all do
      change_setting('AllowDynamicMigrations', true)
      create_admin
      change_setting('RedcapJobUserEmail', @admin.email)
    end

    after :all do
      change_setting('AllowDynamicMigrations', false)
    end

    def prepare_project_admin_for_job
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      dm = create_dynamic_model_for_sample_response
      setup_file_store

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.dynamic_model_table = dm.table_name
      rc.save!

      [rc, dm.implementation_class]
    end

    it 'marks the project "manual run successful" when the pull recorded no errors' do
      rc, model_class = prepare_project_admin_for_job

      allow_any_instance_of(Redcap::DataRecords).to receive(:retrieve_validate_store)
      allow_any_instance_of(Redcap::DataRecords).to receive(:errors).and_return([])

      described_class.new.perform(rc, model_class.name)

      expect(rc.reload.status).to eq(Redcap::ProjectAdmin::Statuses[:manual_run_successful])
    end

    it 'marks the project "manual run completed with errors" when the pull recorded errors' do
      rc, model_class = prepare_project_admin_for_job

      allow_any_instance_of(Redcap::DataRecords).to receive(:retrieve_validate_store)
      allow_any_instance_of(Redcap::DataRecords).to receive(:errors).and_return(
        [{ id: { record_id: '1' }, errors: { store: 'boom' }, action: :create_or_update }]
      )

      described_class.new.perform(rc, model_class.name)

      expect(rc.reload.status).to eq(Redcap::ProjectAdmin::Statuses[:manual_run_completed_with_errors])
    end
  end
end
