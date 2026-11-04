# frozen_string_literal: true

# Purpose: Verify view-handler validation, Master-key requirements, and generated rec_type/rank behavior.
require 'rails_helper'

RSpec.describe 'Dynamic model view handlers', type: :model do
  include MasterSupport
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    @suffix = "x#{SecureRandom.hex(4)}"

    @rec_type_definition = create_dynamic_model_definition(
      name: "View Handler Rec Type #{@suffix}",
      table_name: "view_handler_#{@suffix}_contacts",
      field_list: 'rec_type data',
      handlers: %w[rec_type ui_only],
      rec_types: %w[alpha beta]
    )
    @rec_type_rank_definition = create_dynamic_model_definition(
      name: "View Handler Rec Type Rank #{@suffix}",
      table_name: "view_handler_#{@suffix}_ranked_contacts",
      field_list: 'rec_type data rank',
      handlers: %w[rec_type rank],
      rec_types: %w[alpha beta]
    )
    @rank_only_definition = create_dynamic_model_definition(
      name: "View Handler Rank Only #{@suffix}",
      table_name: "view_handler_#{@suffix}_ranked_records",
      field_list: 'data rank',
      handlers: %w[rank]
    )
    @rec_type_without_column_definition = create_dynamic_model_definition(
      name: "View Handler Rec Type Without Column #{@suffix}",
      table_name: "view_handler_#{@suffix}_without_rec_types",
      field_list: 'data',
      handlers: %w[rec_type]
    )
    @rank_without_column_definition = create_dynamic_model_definition(
      name: "View Handler Rank Without Column #{@suffix}",
      table_name: "view_handler_#{@suffix}_without_ranks",
      field_list: 'data',
      handlers: %w[rank]
    )
    @late_rec_type_definition = create_dynamic_model_definition(
      name: "View Handler Late Rec Type #{@suffix}",
      table_name: "view_handler_#{@suffix}_late_rec_types",
      field_list: 'rec_type data',
      handlers: %w[rec_type]
    )
    @crosswalk_definition = create_dynamic_model_definition(
      name: "View Handler Crosswalk #{@suffix}",
      table_name: "view_handler_#{@suffix}_crosswalks",
      field_list: 'pro_id data',
      handlers: %w[address]
    )
  end

  after :all do
    [@rec_type_definition, @rec_type_rank_definition, @rank_only_definition,
     @rec_type_without_column_definition, @rank_without_column_definition,
     @late_rec_type_definition, @crosswalk_definition].compact.each do |definition|
      definition.reload.disable!(@admin)
    end
    change_setting('AllowDynamicMigrations', false)
  end

  before :each do
    create_user
    create_master
    [@rec_type_definition, @rec_type_rank_definition, @rank_only_definition,
     @rec_type_without_column_definition, @rank_without_column_definition,
     @late_rec_type_definition, @crosswalk_definition].each do |definition|
      setup_access definition.resource_name.to_sym, user: @user
    end
  end

  def build_dynamic_model_definition(name:, table_name:, field_list:, handlers:, foreign_key_name: :master_id,
                                     options: nil)
    handler_yaml = handlers.map { |handler| "      - #{handler}" }.join("\n")
    options ||= <<~YAML
      default:
        view_options:
          view_handlers:
      #{handler_yaml}
    YAML

    DynamicModel.new(
      current_admin: @admin,
      name:,
      table_name:,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name:,
      category: :test,
      field_list:,
      options:
    )
  end

  def create_dynamic_model_definition(name:, table_name:, field_list:, handlers:, rec_types: [])
    definition = build_dynamic_model_definition(name:, table_name:, field_list:, handlers:)

    rec_types.each do |rec_type|
      Classification::GeneralSelection.create!(
        current_admin: @admin,
        item_type: "#{definition.model_association_name}_rec_type",
        name: rec_type.titleize,
        value: rec_type
      )
    end

    if field_list.split.include?('rank')
      [[10, 'Primary'], [5, 'Secondary']].each do |value, label|
        Classification::GeneralSelection.create!(
          current_admin: @admin,
          item_type: "#{definition.model_association_name}_rank",
          name: label,
          value:
        )
      end
    end

    definition.save!
    definition.update_tracker_events
    definition
  end

  def association_for(definition, rec_type)
    "#{definition.model_class.name.ns_underscore}_#{rec_type}".pluralize.to_sym
  end

  it 'requires rec_type, rejects unconfigured values, and scopes associations' do
    base_association = @rec_type_definition.model_association_name
    alpha = @master.public_send(base_association).create!(data: 'alpha record', rec_type: 'alpha')
    beta = @master.public_send(base_association).create!(data: 'beta record', rec_type: 'beta')

    expect(@master.public_send(association_for(@rec_type_definition, 'alpha'))).to contain_exactly(alpha)
    expect(@master.public_send(association_for(@rec_type_definition, 'beta'))).to contain_exactly(beta)
    expect(@rec_type_definition.model_class.alpha).to contain_exactly(alpha)

    missing_type = @master.public_send(base_association).build(data: 'missing type')
    expect(missing_type).not_to be_valid
    expect(missing_type.errors).to have_key(:rec_type)

    unsupported_type = @master.public_send(base_association).build(data: 'unsupported type', rec_type: 'gamma')
    expect(unsupported_type).not_to be_valid
    expect(unsupported_type.errors.of_kind?(:rec_type, :inclusion)).to be true

    missing_type.ignore_configurable_valid_if = true
    expect(missing_type).to be_valid
  end

  it 'requires selections added after the dynamic model class was generated' do
    model_class = @late_rec_type_definition.model_class
    Classification::GeneralSelection.create!(
      current_admin: @admin,
      item_type: "#{@late_rec_type_definition.model_association_name}_rec_type",
      name: 'Late Alpha',
      value: 'late_alpha'
    )
    Classification::GeneralSelection.item_types(refresh: true)

    expect(@late_rec_type_definition.model_class).to equal(model_class)

    association = @late_rec_type_definition.model_association_name
    missing_type = @master.public_send(association).build(data: 'missing type')
    expect(missing_type).not_to be_valid
    expect(missing_type.errors).to have_key(:rec_type)

    unsupported_type = @master.public_send(association).build(data: 'unsupported type', rec_type: 'late_beta')
    expect(unsupported_type).not_to be_valid
    expect(unsupported_type.errors.of_kind?(:rec_type, :inclusion)).to be true

    selected_type = @master.public_send(association).build(data: 'selected type', rec_type: 'late_alpha')
    expect(selected_type).to be_valid
  ensure
    Classification::GeneralSelection.item_types(refresh: true)
  end

  it 'requires master_id for handlers whose Master associations use the wrong key for crosswalks' do
    expect(@rec_type_definition).to be_valid

    definition = build_dynamic_model_definition(
      name: "Invalid Crosswalk Handler #{@suffix}",
      table_name: @crosswalk_definition.table_name,
      field_list: 'pro_id rec_type data',
      handlers: %w[rec_type contact subject],
      foreign_key_name: :pro_id
    )

    expect(definition).not_to be_valid
    expect(definition.errors[:foreign_key_name].join).to include('rec_type', 'contact', 'subject')
  end

  it 'requires master_id for rec_type handlers when foreign_key_name is blank' do
    definition = build_dynamic_model_definition(
      name: "Unattached Rec Type Handler #{@suffix}",
      table_name: @crosswalk_definition.table_name,
      field_list: 'pro_id rec_type data',
      handlers: %w[rec_type],
      foreign_key_name: nil
    )

    expect(definition).not_to be_valid
    expect(definition.errors[:foreign_key_name].join).to include('rec_type', 'master_id')
  end

  it 'allows a crosswalk foreign key for handlers that do not create plain Master associations' do
    definition = build_dynamic_model_definition(
      name: "Address Crosswalk Handler #{@suffix}",
      table_name: @crosswalk_definition.table_name,
      field_list: 'pro_id data rank',
      handlers: %w[address rank],
      foreign_key_name: :pro_id
    )

    expect(definition).to be_valid
  end

  it 'handles scalar and invalid view handler options without raising during validation' do
    scalar_definition = build_dynamic_model_definition(
      name: "Scalar View Handler #{@suffix}",
      table_name: @crosswalk_definition.table_name,
      field_list: 'pro_id rec_type data',
      handlers: [],
      foreign_key_name: :pro_id,
      options: <<~YAML
        default:
          view_options:
            view_handlers: rec_type
      YAML
    )
    invalid_options_definition = build_dynamic_model_definition(
      name: "Invalid View Handler Options #{@suffix}",
      table_name: @crosswalk_definition.table_name,
      field_list: 'pro_id data',
      handlers: [],
      options: 'default: ['
    )

    expect { scalar_definition.valid? }.not_to raise_error
    expect(scalar_definition.errors[:foreign_key_name].join).to include('rec_type')
    expect { invalid_options_definition.valid? }.not_to raise_error
  end

  it 'saves a rec_type handler model without a rec_type column' do
    association = @rec_type_without_column_definition.model_association_name
    record = @master.public_send(association).build(data: 'record without rec_type')

    expect { record.save! }.not_to raise_error
    expect(record).to be_persisted
  end

  it 'saves a rank handler model without a rank column' do
    association = @rank_without_column_definition.model_association_name
    record = @master.public_send(association).build(data: 'record without rank')

    expect { record.save! }.not_to raise_error
    expect(record).to be_persisted
  end

  it 'accepts a non-blank rec_type when there are no configured selections' do
    association = @rec_type_definition.model_association_name
    allow(@rec_type_definition.model_class).to receive(:valid_rec_types).and_return([])
    record = @master.public_send(association).build(data: 'record with an unconfigured type', rec_type: 'custom')

    expect(record).to be_valid
    expect(record.errors).to be_empty
  end

  it 'demotes only the primary record with the same rec_type when both handlers are enabled' do
    association = @rec_type_rank_definition.model_association_name
    previous_alpha = @master.public_send(association).create!(data: 'old alpha', rec_type: 'alpha', rank: 10)
    primary_beta = @master.public_send(association).create!(data: 'primary beta', rec_type: 'beta', rank: 10)

    @master.public_send(association).create!(data: 'new alpha', rec_type: 'alpha', rank: 10)

    expect(previous_alpha.reload.rank.to_i).to eq 5
    expect(primary_beta.reload.rank.to_i).to eq 10
  end

  it 'requires rank and demotes the prior primary per master without a rec_type column' do
    association = @rank_only_definition.model_association_name
    missing_rank = @master.public_send(association).build(data: 'missing rank')
    expect(missing_rank).not_to be_valid
    expect(missing_rank.errors).to have_key(:rank)

    previous_primary = @master.public_send(association).create!(data: 'old primary', rank: 10)
    @master.public_send(association).create!(data: 'new primary', rank: 10)

    expect(previous_primary.reload.rank.to_i).to eq 5
  end

  it 'continues to skip unknown UI-only handler names' do
    expect(@rec_type_definition.view_handler_def('ui_only')).to be_nil
    expect(@rec_type_definition.model_class).to be_a(Class)
  end

  it 'rebuilds one rec_type association against the regenerated dynamic model class' do
    previous_class = @rec_type_definition.model_class
    association = association_for(@rec_type_definition, 'alpha')

    @rec_type_definition.force_regenerate = true
    @rec_type_definition.generate_model
    regenerated_class = @rec_type_definition.model_class

    expect(regenerated_class).not_to equal(previous_class)
    expect(Master.reflect_on_association(association).klass).to equal(regenerated_class)
    expect(Master.reflect_on_all_associations(:has_many).count { |reflection| reflection.name == association }).to eq(1)
  end
end
