# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for DbColumns class (top-level _db_columns options).
# Verifies Hash-like access ([], dig, keys, select, to_h), recognized key
# warnings via NamedConfiguration, value type validation (type as string,
# boolean flags for array/index/encrypted), and integration through
# ExtraOptions.parse_config.
RSpec.describe 'ExtraOptionConfigs::DbColumns', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::DbColumns }

  describe 'initialization' do
    it 'stores column configs accessible via []' do
      instance = klass.new(first_name: { type: 'string' }, age: { type: 'integer' })
      expect(instance[:first_name]).to be_present
      expect(instance[:age]).to be_present
    end

    it 'supports dig for nested access' do
      instance = klass.new(email: { type: 'string', encrypted: true })
      expect(instance.dig(:email, :type)).to eq 'string'
      expect(instance.dig(:email, :encrypted)).to be true
    end

    it 'supports keys returning field names' do
      instance = klass.new(first_name: { type: 'string' }, last_name: { type: 'string' })
      expect(instance.keys).to contain_exactly(:first_name, :last_name)
    end

    it 'supports select returning a Hash' do
      instance = klass.new(email: { type: 'string', encrypted: true }, name: { type: 'string' })
      result = instance.select { |_k, v| v[:encrypted] }
      expect(result).to be_a(Hash)
      expect(result.keys).to eq([:email])
    end

    it 'supports to_h returning a plain Hash' do
      instance = klass.new(score: { type: 'float' })
      result = instance.to_h
      expect(result).to be_a(Hash)
      expect(result[:score]).to be_a(Hash)
      expect(result[:score][:type]).to eq 'float'
    end

    it 'is blank when empty' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'warns about unrecognized sub-keys in a column config' do
      instance = klass.new(email: { type: 'string', bogus_flag: true })
      expect(instance.config_warnings).not_to be_empty
    end

    it 'does not warn about recognized sub-keys' do
      instance = klass.new(email: { type: 'string', array: false, index: true, encrypted: false })
      expect(instance.config_warnings).to be_empty
    end
  end

  describe 'validate_db_columns_shape' do
    describe 'type key' do
      it 'accepts string values for type' do
        instance = klass.new(name: { type: 'string' })
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'accepts symbol values for type' do
        instance = klass.new(name: { type: :integer })
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'rejects non-string values for type' do
        instance = klass.new(name: { type: 123 })
        instance.valid?
        expect(instance.errors.full_messages.join).to include('type must be a string')
      end
    end

    describe 'boolean keys' do
      it 'accepts true/false for array' do
        instance = klass.new(tags: { type: 'string', array: true })
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'accepts true/false for index' do
        instance = klass.new(email: { type: 'string', index: true })
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'accepts true/false for encrypted' do
        instance = klass.new(ssn: { type: 'string', encrypted: true })
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'rejects non-boolean for array' do
        instance = klass.new(tags: { type: 'string', array: 'yes' })
        instance.valid?
        expect(instance.errors.full_messages.join).to include('array must be true or false')
      end

      it 'rejects non-boolean for index' do
        instance = klass.new(email: { type: 'string', index: 1 })
        instance.valid?
        expect(instance.errors.full_messages.join).to include('index must be true or false')
      end

      it 'rejects non-boolean for encrypted' do
        instance = klass.new(ssn: { type: 'string', encrypted: 'on' })
        instance.valid?
        expect(instance.errors.full_messages.join).to include('encrypted must be true or false')
      end
    end

    describe 'combined valid configuration' do
      it 'passes validation with all keys set correctly' do
        instance = klass.new(
          email: { type: 'string', index: true, encrypted: true },
          tags: { type: 'string', array: true },
          score: { type: 'float' }
        )
        instance.valid?
        expect(instance.errors).to be_empty
        expect(instance.config_warnings).to be_empty
      end
    end
  end

  describe 'parse_config integration' do
    it 'wraps _db_columns in a DbColumns instance' do
      @dm.update!(options: <<~YAML)
        _db_columns:
          alt_email:
            type: string
            encrypted: true
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.db_columns).to be_a(klass)
      expect(@dm.db_columns.dig(:alt_email, :type)).to eq 'string'
      expect(@dm.db_columns.dig(:alt_email, :encrypted)).to be true
    end

    it 'returns blank DbColumns when no _db_columns defined' do
      @dm.update!(options: <<~YAML)
        default:
          label: No db columns
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.db_columns).to be_a(klass)
      expect(@dm.db_columns).to be_blank
    end
  end
end
