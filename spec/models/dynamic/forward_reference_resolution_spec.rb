# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for references between dynamic definitions generated in
# sequence. A referencing definition parsed before its target class exists must
# be refreshed after generation, without reparsing unaffected definitions.
#
# Coverage:
# - AppControl resolves a cached DynamicModel reference after its ActivityLog target is generated
# - Cached ActivityLog e-sign config is reprocessed after its DynamicModel target is generated
# - AppControl invokes the resolver after definition generation
# - Cached definitions without unresolved references are not reparsed
# - A genuinely missing target stays unresolved without raising
RSpec.describe 'Dynamic definition forward reference resolution', type: :model do
  include ModelSupport

  before(:all) do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    @rand_id = SecureRandom.hex(4)

    @target_activity_log = ActivityLog.create!(
      current_admin: @admin,
      name: "forward reference target #{@rand_id}",
      item_type: 'player_contact',
      process_name: "forwardref#{@rand_id}",
      schema_name: 'dynamic_test',
      category: :test,
      action_when_attribute: 'created_at',
      extra_log_types: <<~YAML
        step_#{@rand_id}:
          label: Forward reference target
          fields:
            - data
      YAML
    )

    target_reference_name = "activity_log__#{@target_activity_log.item_type_name}"
    @referencing_definition = DynamicModel.create!(
      current_admin: @admin,
      name: "forward reference source #{@rand_id}",
      table_name: "forwardrefsource#{@rand_id}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: <<~YAML
        default:
          label: Forward reference source
          references:
            #{target_reference_name}:
              from: this
              add: many
      YAML
    )

    esign_target_table = "forwardrefesign#{@rand_id}s"
    @esign_target_definition = DynamicModel.create!(
      current_admin: @admin,
      name: "e-sign forward reference target #{@rand_id}",
      table_name: esign_target_table,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )

    esign_target_reference = "dynamic_model__#{esign_target_table.singularize}"
    @esign_referencing_definition = ActivityLog.create!(
      current_admin: @admin,
      name: "e-sign forward reference source #{@rand_id}",
      item_type: 'player_contact',
      process_name: "forwardrefesign#{@rand_id}",
      schema_name: 'dynamic_test',
      category: :test,
      action_when_attribute: 'created_at',
      extra_log_types: <<~YAML
        sign_#{@rand_id}:
          label: E-sign forward reference source
          fields:
            - data
          e_sign:
            document_reference:
              #{esign_target_reference}:
                from: master
      YAML
    )

    @plain_definition = DynamicModel.create!(
      current_admin: @admin,
      name: "forward reference plain #{@rand_id}",
      table_name: "forwardrefplain#{@rand_id}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )

    missing_reference_name = "dynamic_model__missingforwardref#{@rand_id}"
    @missing_reference_definition = DynamicModel.create!(
      current_admin: @admin,
      name: "forward reference missing #{@rand_id}",
      table_name: "forwardrefmissing#{@rand_id}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: <<~YAML
        default:
          label: Missing reference source
          references:
            #{missing_reference_name}:
              from: this
              add: many
      YAML
    )
  end

  after(:all) do
    @missing_reference_definition&.disable!(@admin)
    @plain_definition&.disable!(@admin)
    @esign_referencing_definition&.disable!(@admin)
    @esign_target_definition&.disable!(@admin)
    @referencing_definition&.disable!(@admin)
    @target_activity_log&.disable!(@admin)
    change_setting('AllowDynamicMigrations', false)
  end

  after do
    AppControl.reset_define_models_attempted
  end

  it 'resolves a cached reference after the target class is generated later in the pass' do
    target_class_name = @target_activity_log.model_class_name
    target_class = ActivityLog.const_get(target_class_name, false)
    ActivityLog.send(:remove_const, target_class_name)

    cached_definition = DynamicModel.definition_cache.fetch(@referencing_definition.id)
    cached_definition.force_option_config_parse(raise_bad_configs: false)
    parsed_options = cached_definition.option_type_config_for(:default)
    target_reference_name = :"activity_log__#{@target_activity_log.item_type_name}"

    expect(parsed_options.unresolved_model_references?).to be true
    expect(parsed_options.references[target_reference_name]).not_to have_key(target_reference_name)

    allow(ActivityLog).to receive(:define_models) do
      @target_activity_log.generate_model
    end
    AppControl.define_models

    parsed_options = cached_definition.option_type_config_for(:default)
    resolved_reference = parsed_options.references.dig(
      target_reference_name, target_reference_name, :to_model_class_name
    )
    expect(resolved_reference).to eq(@target_activity_log.full_implementation_class_name)
  ensure
    ActivityLog.const_set(target_class_name, target_class) unless ActivityLog.const_defined?(target_class_name, false)
  end

  it 'resolves a cached e-sign reference after its DynamicModel class is generated' do
    target_class_name = @esign_target_definition.model_class_name
    target_class = DynamicModel.const_get(target_class_name, false)
    DynamicModel.send(:remove_const, target_class_name)

    cached_definition = ActivityLog.definition_cache.fetch(@esign_referencing_definition.id)
    cached_definition.force_option_config_parse(raise_bad_configs: false)
    option_type_name = "sign_#{@rand_id}"
    parsed_options = cached_definition.option_type_config_for(option_type_name)
    target_reference_name = :"dynamic_model__#{@esign_target_definition.table_name.singularize}"

    expect(cached_definition.option_configs_have_unresolved_references?).to be true
    expect(parsed_options.e_sign.dig(:document_reference, :item, target_reference_name, :to_model_name_us)).to be_nil

    DynamicModel.const_set(target_class_name, target_class)
    Dynamic::DefGenerator.resolve_cached_forward_references!

    parsed_options = cached_definition.option_type_config_for(option_type_name)
    resolved_reference = parsed_options.e_sign.dig(:document_reference, :item, target_reference_name)
    expect(resolved_reference[:to_model_name_us]).to eq(target_class.to_s.ns_underscore)
    expect(resolved_reference[:to_record_label]).to be_present
    expect(cached_definition.option_configs_have_unresolved_references?).to be false
  ensure
    DynamicModel.const_set(target_class_name, target_class) unless DynamicModel.const_defined?(target_class_name, false)
  end

  it 'invokes forward-reference resolution once after definition generation' do
    expect(ActivityLog).to receive(:define_models).ordered
    expect(Dynamic::DefGenerator).to receive(:resolve_cached_forward_references!).once.ordered

    AppControl.define_models
  end

  it 'does not reparse cached definitions without unresolved references' do
    cached_definition = DynamicModel.definition_cache.fetch(@plain_definition.id)
    parsed_options = cached_definition.option_configs

    Dynamic::DefGenerator.resolve_cached_forward_references!

    expect(cached_definition.option_configs).to be(parsed_options)
  end

  it 'leaves a genuinely missing target unresolved without raising' do
    cached_definition = DynamicModel.definition_cache.fetch(@missing_reference_definition.id)
    missing_reference_name = :"dynamic_model__missingforwardref#{@rand_id}"

    expect(cached_definition.option_configs_have_unresolved_references?).to be true
    expect { Dynamic::DefGenerator.resolve_cached_forward_references! }.not_to raise_error

    parsed_options = cached_definition.option_type_config_for(:default)
    expect(parsed_options.references[missing_reference_name]).not_to have_key(missing_reference_name)
    expect(cached_definition.option_configs_have_unresolved_references?).to be true
  end
end
