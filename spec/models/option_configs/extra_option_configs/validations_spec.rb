# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ActiveModel::Validations integration with BaseConfiguration.
# Verifies the run_validations bridge, TypedAttributeValidator,
# validates declarations, and error bridging into config_errors.
RSpec.describe 'ExtraOptionConfigs ActiveModel::Validations integration', type: :model do
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

  describe 'ActiveModel::Validations integration' do
    it 'errors is ActiveModel::Errors, not a plain Array' do
      instance = OptionConfigs::ExtraOptionConfigs::BaseConfiguration.new({})
      expect(instance.errors).to be_a(ActiveModel::Errors)
    end

    it 'validates declarations produce config_errors when value is blank' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_direct :test_attr, type: :string
        validates :test_attr, presence: true
      end

      instance = test_class.new({})
      expect(instance.config_errors).not_to be_empty
      messages = instance.config_errors.map { |e| e[:message] }
      expect(messages.join(' ')).to match(/test_attr.*blank|can't be blank/i)
    end

    it 'valid config produces no config_errors from validates' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_direct :test_attr, type: :string
        validates :test_attr, presence: true

        def setup_named_configurations
          self.test_attr = 'a valid value'
        end
      end

      instance = test_class.new({})
      expect(instance.config_errors).to be_empty
    end

    it 'TypedAttributeValidator catches wrong type' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_typed_attribute :my_typed, type: OptionConfigs::ExtraOptionConfigs::TriggerTasks
        validates :my_typed, 'validates/typed_attribute': true

        def setup_named_configurations
          setup_all_options_typed(hash_configuration)
        end
      end

      instance = test_class.new({})
      # Manually assign wrong type after initialization
      instance.my_typed = 'wrong'
      instance.valid?
      expect(instance.errors[:my_typed]).not_to be_empty
      expect(instance.errors[:my_typed].join(' ')).to match(/must be a.*TriggerTasks.*got String/)
    end

    it 'TypedAttributeValidator passes correct type' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_typed_attribute :my_typed, type: OptionConfigs::ExtraOptionConfigs::TriggerTasks
        validates :my_typed, 'validates/typed_attribute': true

        def setup_named_configurations
          setup_all_options_typed(hash_configuration)
        end
      end

      instance = test_class.new(my_typed: { notify: { type: 'email' } })
      expect(instance.my_typed).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.valid?).to be true
      expect(instance.errors[:my_typed]).to be_empty
    end

    it 'TypedAttributeValidator allows nil' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_typed_attribute :my_typed, type: OptionConfigs::ExtraOptionConfigs::TriggerTasks
        validates :my_typed, 'validates/typed_attribute': true

        def setup_named_configurations
          # Don't set my_typed — leave it nil
        end
      end

      instance = test_class.new({})
      expect(instance.my_typed).to be_nil
      expect(instance.valid?).to be true
      expect(instance.errors[:my_typed]).to be_empty
    end

    it 'full integration: BatchTrigger subclass with validates produces config_errors on empty config' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BatchTrigger) do
        validates :on_record, presence: true
      end

      instance = test_class.new({})
      expect(instance.config_errors).not_to be_empty
      messages = instance.config_errors.map { |e| e[:message] }
      expect(messages.join(' ')).to match(/on_record.*blank|can't be blank/i)
    end
  end
end
