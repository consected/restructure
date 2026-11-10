# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ActivityLogOptions config_class_registry integration.
# Verifies that nfs_store and e_sign are registered config classes
# and the old clean_ instance methods no longer exist.
RSpec.describe 'ActivityLogOptions config_class_registry', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  it 'extends parent registry with nfs_store' do
    registry = OptionConfigs::ActivityLogOptions.config_class_registry
    expect(registry).to have_key(:nfs_store),
                        'Expected ActivityLogOptions.config_class_registry to include :nfs_store'
  end

  it 'extends parent registry with e_sign_config' do
    registry = OptionConfigs::ActivityLogOptions.config_class_registry
    expect(registry).to have_key(:e_sign_config),
                        'Expected ActivityLogOptions.config_class_registry to include :e_sign_config'
  end

  it 'maps nfs_store to NfsStoreConfig class' do
    registry = OptionConfigs::ActivityLogOptions.config_class_registry
    expect(registry[:nfs_store]).to eq(OptionConfigs::ExtraOptionConfigs::NfsStoreConfig)
  end

  it 'maps e_sign_config to ESignConfig class' do
    registry = OptionConfigs::ActivityLogOptions.config_class_registry
    expect(registry[:e_sign_config]).to eq(OptionConfigs::ExtraOptionConfigs::ESignConfig)
  end

  it 'returns add_key_attributes containing :e_sign' do
    expect(OptionConfigs::ActivityLogOptions.add_key_attributes).to eq([:e_sign])
  end

  it 'does not define clean_nfs_store_def as instance method' do
    expect(OptionConfigs::ActivityLogOptions.method_defined?(:clean_nfs_store_def, false)).to be false
  end

  it 'does not define clean_e_sign_def as instance method' do
    expect(OptionConfigs::ActivityLogOptions.method_defined?(:clean_e_sign_def, false)).to be false
  end
end
