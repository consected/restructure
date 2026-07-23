# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for NfsStoreConfig configuration class.
# Verifies key validation for nfs_store top-level and can sub-keys,
# pipeline delegation, and integration with ActivityLogOptions registry.
RSpec.describe 'ExtraOptionConfigs::NfsStoreConfig', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:each) do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    @dm = generate_test_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::NfsStoreConfig }

  describe 'class structure' do
    it 'exists and inherits from BaseConfiguration' do
      expect(klass).to be < OptionConfigs::ExtraOptionConfigs::BaseConfiguration
    end

    it 'stores processed value' do
      expect(klass.store_processed_value?).to be true
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:nfs_store)
    end
  end

  describe 'validate callbacks' do
    it 'produces ActiveModel errors for invalid top-level nfs_store keys' do
      raw = { always_use_this_for_access_control: true, invalid_key_xyz: 'bad' }
      instance = klass.new(raw)
      expect(instance.errors.any? { |e| e.attribute == :nfs_store }).to be(true),
                                                                        'Expected ActiveModel error on :nfs_store for invalid top-level keys'
    end

    it 'produces ActiveModel errors for invalid can sub-keys' do
      raw = { can: { download_if: true, bogus_permission: 'bad' } }
      instance = klass.new(raw)
      expect(instance.errors.any? { |e| e.attribute == :nfs_store }).to be(true),
                                                                        'Expected ActiveModel error on :nfs_store for invalid can sub-keys'
    end

    it 'has no ActiveModel errors when all keys are valid' do
      raw = { always_use_this_for_access_control: true, can: { download_if: true } }
      instance = klass.new(raw)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for valid nfs_store keys, got: #{instance.errors.full_messages}"
    end

    it 'has no ActiveModel errors when nfs_store is nil' do
      instance = klass.new(nil)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for nil nfs_store, got: #{instance.errors.full_messages}"
    end
  end

  describe 'prepare_config' do
    it 'delegates pipeline cleaning via prepare_config' do
      raw = { pipeline: [], user_file_actions: [] }
      expect(NfsStore::Config::ExtraOptions).to receive(:clean_def).with(raw)
      klass.prepare_config(raw, nil)
    end
  end
end
