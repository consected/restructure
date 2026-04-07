# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for IfCondition configuration class and the three split classes
# (CreatableIf, EditableIf, ShowableIf) that replaced AccessIf.
# Verifies configure_direct with type :hash, store_processed_value?,
# and integration through ExtraOptions initialization (clean_access_if_def behavior).
RSpec.describe 'ExtraOptionConfigs::IfCondition and access_if classes', type: :model do
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

  describe 'IfCondition' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::IfCondition }

    it 'exists under ExtraOptionConfigs namespace' do
      expect(klass).to be_a Class
    end

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:conditions)
      expect(klass.direct_types[:conditions]).to eq(:hash)
    end

    it 'stores entire hash as single conditions attribute' do
      instance = klass.new(always: true, user_is_creator: true)
      expect(instance.conditions).to eq(always: true, user_is_creator: true)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'returns not blank when initialized with data' do
      instance = klass.new(always: true)
      expect(instance).not_to be_blank
    end

    it 'symbolizes keys on initialization' do
      instance = klass.new('always' => true)
      expect(instance.conditions).to have_key(:always)
    end

    it 'handles nil initialization' do
      instance = klass.new(nil)
      expect(instance.conditions).to eq({})
      expect(instance).to be_blank
    end

    it 'supports symbolize_keys for backward compatibility' do
      instance = klass.new(always: true, never: false)
      expect(instance.symbolize_keys).to eq(always: true, never: false)
    end

    it 'reports an error when initialized with a scalar instead of a hash' do
      instance = klass.new('bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:conditions]).not_to be_empty
      expect(instance.conditions).to eq({})
    end
  end

  describe 'if_condition classes (split from AccessIf)' do
    %i[CreatableIf EditableIf ShowableIf].each do |class_name|
      context "#{class_name}" do
        let(:klass) { "OptionConfigs::ExtraOptionConfigs::#{class_name}".constantize }

        it 'exists under ExtraOptionConfigs namespace' do
          expect(klass).to be_a Class
        end

        it 'uses configure_direct with type :hash' do
          expect(klass.option_types[:direct]).to be_present
        end
      end
    end
  end

  describe 'if_condition classes (converted to BaseConfiguration)' do
    %i[CreatableIf EditableIf ShowableIf].each do |class_name|
      context "#{class_name}" do
        let(:klass) { "OptionConfigs::ExtraOptionConfigs::#{class_name}".constantize }
        let(:attr_name) { class_name.to_s.underscore.to_sym }

        it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
          expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
        end

        it 'does not inherit from ConfigBase' do
          expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
        end

        it 'declares configure_direct with type :hash' do
          expect(klass.option_types[:direct]).to include(attr_name)
        end

        it 'stores the hash as the attribute' do
          instance = klass.new(always: true)
          expect(instance.send(attr_name)).to eq(always: true)
        end

        it 'supports hash-like bracket access' do
          instance = klass.new(always: true)
          expect(instance[:always]).to eq true
        end

        it 'defaults to empty hash when initialized with nil' do
          instance = klass.new(nil)
          expect(instance.send(attr_name)).to eq({})
          expect(instance).to be_blank
        end

        it 'reports an error when initialized with a scalar instead of a hash' do
          instance = klass.new('bad')
          expect(instance.config_errors).not_to be_empty
          expect(instance.errors[attr_name]).not_to be_empty
          expect(instance.send(attr_name)).to eq({})
        end
      end
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults all access_if attributes to empty hashes' do
      eo = config_for(<<~YAML)
        default:
          label: No access
      YAML

      expect(eo.creatable_if).to eq({})
      expect(eo.editable_if).to eq({})
      expect(eo.showable_if).to eq({})
    end

    it 'preserves and symbolizes creatable_if, editable_if, showable_if' do
      eo = config_for(<<~YAML)
        default:
          creatable_if:
            always: true
          editable_if:
            never: true
          showable_if:
            user_is_creator: true
      YAML

      expect(eo.creatable_if).to eq(always: true)
      expect(eo.editable_if).to eq(never: true)
      expect(eo.showable_if).to eq(user_is_creator: true)
    end

    it 'access_if classes store processed hash values (via store_processed_value?)' do
      eo = config_for(<<~YAML)
        default:
          creatable_if:
            always: true
          editable_if:
            never: true
          showable_if:
            user_is_creator: true
      YAML

      expect(eo.creatable_if).to be_a Hash
      expect(eo.creatable_if[:always]).to eq true
      expect(eo.editable_if).to be_a Hash
      expect(eo.editable_if[:never]).to eq true
      expect(eo.showable_if).to be_a Hash
      expect(eo.showable_if[:user_is_creator]).to eq true
    end
  end
end
