# frozen_string_literal: true

require 'rails_helper'

# Purpose: Regression coverage for issue #1459, including lenient loading of
# persisted nested configuration while preserving strict explicit construction.
RSpec.describe 'OptionsHandler', type: :model do
  before :example do
    Object.send :remove_const, 'TestOptionsHandler' if defined? TestOptionsHandler
    Object.const_set(
      'TestOptionsHandler',
      Class.new do
        attr_accessor :options

        def config_text
          options
        end

        def config_text=(value)
          self.options = value
        end

        def persisted?
          true
        end
      end
    )

    TestOptionsHandler.include OptionsHandler
  end

  it 'does not raise when loading persisted nested configuration with an unknown key for issue #1459' do
    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1]
    record = TestOptionsHandler.new
    record.options = <<~YAML
      test2_var1:
        test2_var1_a1: persisted-value
        unknown_key: preserve-me
    YAML

    expect { record.send(:setup_options) }.not_to raise_error
  end

  it 'preserves unknown nested configuration keys in memory and serialization for issue #1459' do
    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1]
    record = TestOptionsHandler.new
    record.options = <<~YAML
      test2_var1:
        test2_var1_a1: persisted-value
        unknown_key: preserve-me
        unknown_nil:
    YAML

    record.send(:setup_options)

    expect(record.test2_var1.to_h).to include(
      test2_var1_a1: 'persisted-value',
      unknown_key: 'preserve-me',
      unknown_nil: nil
    )
    expect(record.send(:config_hash_to_yaml)).to include('unknown_key: preserve-me')
    expect(record.send(:config_hash_to_yaml)).to include('unknown_nil')
  end

  it 'records the nested configuration class, message, and offending key for issue #1459' do
    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1]
    record = TestOptionsHandler.new
    record.options = <<~YAML
      test2_var1:
        test2_var1_a1: persisted-value
        unknown_key: preserve-me
        unknown_nil:
    YAML

    expect { record.send(:setup_options) }.not_to raise_error

    expect(record.config_errors).to contain_exactly(
      a_hash_including(
        config_class: TestOptionsHandler::Test2Var1.name,
        message: a_string_including('unknown_key'),
        offending_keys: contain_exactly(:unknown_key, :unknown_nil)
      )
    )
  end

  it 'preserves unknown keys in persisted hash configurations for issue #1459' do
    TestOptionsHandler.configure_hash :test3_var1, with: %i[test3_var1_a1]
    record = TestOptionsHandler.new
    record.options = <<~YAML
      test3_var1:
        entry:
          test3_var1_a1: persisted-value
          unknown_key: preserve-me
    YAML

    expect { record.send(:setup_options) }.not_to raise_error

    configuration = record.test3_var1['entry']
    expect(configuration.to_h).to include(
      test3_var1_a1: 'persisted-value',
      unknown_key: 'preserve-me'
    )
    expect(record.send(:config_hash_to_yaml)).to include('unknown_key: preserve-me')
    expect(record.config_errors).to contain_exactly(
      a_hash_including(
        config_class: TestOptionsHandler::Test3Var1::Test3Var1.name,
        message: a_string_including('unknown_key'),
        offending_keys: contain_exactly(:unknown_key)
      )
    )

    expect do
      TestOptionsHandler.new use_hash_config: {
        test3_var1: { entry: { unknown_key: 'reject-me' } }
      }
    end.to raise_error(
      FphsException,
      'Unrecognized configuration params in TestOptionsHandler::Test3Var1::Test3Var1: unknown_key'
    )
  end

  it 'clears configuration errors after a non-hash persisted reload for issue #1459' do
    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1]
    record = TestOptionsHandler.new
    record.options = <<~YAML
      test2_var1:
        test2_var1_a1: persisted-value
        unknown_key: preserve-me
    YAML

    record.send(:setup_options)
    expect(record.config_errors).to be_present

    record.options = "---\nnot-a-configuration-hash\n"
    record.send(:setup_options)

    expect(record.config_errors).to be_empty
  end

  it 'keeps direct Configuration.new strict for issue #1459' do
    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1]

    expect do
      TestOptionsHandler::Test2Var1.new(unknown_key: 'reject-me')
    end.to raise_error(
      FphsException,
      'Unrecognized configuration params in TestOptionsHandler::Test2Var1: unknown_key'
    )
  end

  it 'keeps explicit hash configuration strict for issue #1459' do
    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1]

    expect do
      TestOptionsHandler.new use_hash_config: {
        test2_var1: { unknown_key: 'reject-me' }
      }
    end.to raise_error(
      FphsException,
      'Unrecognized configuration params in TestOptionsHandler::Test2Var1: unknown_key'
    )
  end

  it 'adds basic attributes' do
    t = TestOptionsHandler.new

    expect(t).not_to respond_to :var1

    t.class.configure_attributes %i[var1 var2]
    t.class.configure_attributes :var3, :var4
    t.class.configure_attributes :var5

    expect(t).to respond_to :var1
    expect(t).to respond_to :var2
    expect(t).to respond_to :var3
    expect(t).to respond_to :var4
    expect(t).to respond_to :var5
    expect { t.var1 = 'test' }.not_to raise_error
    expect(t.var1).to eq 'test'
    expect(t.var2).to be nil

    t.var2 = 'test2'

    expect(t.send(:config_hash_to_yaml)).to eq <<~END_TEXT
      var1: test
      var2: test2
      var3:#{' '}
      var4:#{' '}
      var5:#{' '}
    END_TEXT
  end

  it 'adds structured attributes' do
    t = TestOptionsHandler.new

    expect(t).not_to respond_to :test2_var1

    TestOptionsHandler.configure :test2_var1, with: %i[test2_var1_a1 test2_var1_a2]

    expect(t).to respond_to :test2_var1
    expect { t.send(:class_for, :test2_var1) }.not_to raise_error
    expect(t.send(:class_for, :test2_var1)).to eq TestOptionsHandler::Test2Var1
    expect(TestOptionsHandler::Test2Var1.new({})).to respond_to :test2_var1_a1
    expect(TestOptionsHandler::Test2Var1.new({})).to respond_to :test2_var1_a2
    expect(TestOptionsHandler::Test2Var1.new({})).not_to respond_to :test2_var2_a1
    expect(TestOptionsHandler::Test2Var1.new({})).not_to respond_to :test2_var2_a2

    TestOptionsHandler.configure :test2_var2, with: %i[test2_var2_a1 test2_var2_a2]
    expect(TestOptionsHandler::Test2Var2.new({})).to respond_to :test2_var2_a1
    expect(TestOptionsHandler::Test2Var2.new({})).to respond_to :test2_var2_a2
    expect(TestOptionsHandler::Test2Var2.new({})).not_to respond_to :test2_var1_a1
    expect(TestOptionsHandler::Test2Var2.new({})).not_to respond_to :test2_var1_a2

    expect(TestOptionsHandler::Test2Var1.new({})).not_to respond_to :test2_var2_a1
    expect(TestOptionsHandler::Test2Var1.new({})).not_to respond_to :test2_var2_a2

    expect { TestOptionsHandler::Test2Var1.new(unknown: true) }.to raise_error(FphsException, 'Unrecognized configuration params in TestOptionsHandler::Test2Var1: unknown')

    t = TestOptionsHandler.new use_hash_config: {
      test2_var1: {
        test2_var1_a1: 'test-a1',
        test2_var1_a2: 'test-a2'
      }, test2_var2: {
        test2_var2_a1: 'test-b1'
      }
    }
    expect(t).to respond_to :test2_var1
    expect(t).to respond_to :test2_var2

    expect(t.test2_var1.test2_var1_a1).to eq 'test-a1'
    expect(t.test2_var1.test2_var1_a2).to eq 'test-a2'

    expect(t.send(:config_hash_to_yaml)).to eq <<~END_TEXT
      test2_var1:
        test2_var1_a1: test-a1
        test2_var1_a2: test-a2
      test2_var2:
        test2_var2_a1: test-b1
        test2_var2_a2:#{' '}
    END_TEXT

    t.test2_var2.test2_var2_a1 = 'newval1'
    t.test2_var2.test2_var2_a2 = 'newval2'
    expect(t.send(:config_hash_to_yaml)).to eq <<~END_TEXT
      test2_var1:
        test2_var1_a1: test-a1
        test2_var1_a2: test-a2
      test2_var2:
        test2_var2_a1: newval1
        test2_var2_a2: newval2
    END_TEXT
  end

  it 'adds attribute supporting hash with arbitrary keys' do
    t = TestOptionsHandler.new

    expect(t).not_to respond_to :test3_var1
    TestOptionsHandler.configure_hash :test3_var1, with: %i[test3_var1_a1 test3_var1_a2]

    t = TestOptionsHandler.new

    expect(t).to respond_to :test3_var1
    expect(t.test3_var1).to be_a TestOptionsHandler::ConfigurationHash

    expect { t.send(:class_for, :test3_var1__test3_var1) }.not_to raise_error
    expect(t.send(:class_for, :test3_var1, type: :hash_item)).to eq TestOptionsHandler::Test3Var1::Test3Var1
    expect(TestOptionsHandler::Test3Var1::Test3Var1).to respond_to :configure_with_items
    expect(TestOptionsHandler::Test3Var1::Test3Var1.configure_with_items).to eq %i[test3_var1_a1 test3_var1_a2]
    expect(TestOptionsHandler::Test3Var1::Test3Var1.new({})).to respond_to :test3_var1_a1
    expect(TestOptionsHandler::Test3Var1::Test3Var1.new({})).to respond_to :test3_var1_a2
    expect(TestOptionsHandler::Test3Var1.new({})).not_to respond_to :test3_var1_a1
    expect(TestOptionsHandler::Test3Var1.new({})).not_to respond_to :test3_var1_a2

    t = TestOptionsHandler.new use_hash_config: {
      test3_var1: {
        entry1: {
          test3_var1_a1: 'test-a1',
          test3_var1_a2: 'test-a2'
        },
        entry2: {
          test3_var1_a1: 'test-b1'
        }
      }
    }
    expect(t).to respond_to :test3_var1
    expect(t.test3_var1[:entry1]).to respond_to :test3_var1_a1
    expect(t.test3_var1[:entry1]).to respond_to :test3_var1_a2
    expect(t.test3_var1[:entry2]).to respond_to :test3_var1_a1

    expect(t.test3_var1[:entry1].test3_var1_a1).to eq 'test-a1'
    expect(t.test3_var1[:entry1].test3_var1_a2).to eq 'test-a2'
    expect(t.test3_var1[:entry2].test3_var1_a1).to eq 'test-b1'

    expect(t.send(:config_hash_to_yaml)).to eq <<~END_TEXT
      test3_var1:
        entry1:
          test3_var1_a1: test-a1
          test3_var1_a2: test-a2
        entry2:
          test3_var1_a1: test-b1
          test3_var1_a2:#{' '}
    END_TEXT
  end
end
