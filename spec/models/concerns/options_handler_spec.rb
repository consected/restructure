# frozen_string_literal: true

require 'rails_helper'

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
      ---
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
      ---
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
      ---
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
      ---
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
