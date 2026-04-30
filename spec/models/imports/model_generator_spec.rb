# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Imports::ModelGenerator, type: :model do
  include ::UserSupport

  before :all do
    create_admin

    csv = File.read('spec/fixtures/import/test-types.csv')
    ds = Imports::ModelGenerator.new dynamic_model_table: "dynamic_test.test_imports#{rand 100_000_000_000_000}_recs",
                                     category: 'dynamic-test-env',
                                     current_admin: @admin

    ds.analyze_csv(csv)
    @dm = ds.create_dynamic_model

    expect(ds.dynamic_model_ready?).to be_truthy
    expect(@dm.field_list_array).to eq %w[a_string a_int a_float a_date a_time a_mixed_string a_boolean a_unknown a_string2]
    expect(ds.dynamic_model.id).to eq @dm.id
    expect(ds.dynamic_model_def_current?).to be true
  end

  before :example do
    create_admin
  end

  it 'analyzes a CSV to guess at the field types' do
    csv = File.read('spec/fixtures/import/test-master.csv')

    mg = Imports::ModelGenerator.new(name: 'Test CSV',
                                     dynamic_model_table: 'test_csv_imports',
                                     description: 'A test')
    res = mg.analyze_csv(csv)

    expect(res).to be_a Hash
    expect(res.keys).to eq %i[a_string a_int a_float a_date a_time a_mixed_string a_boolean a_unknown a_string2 master_id]
    expect(res.values).to eq %i[string integer float date datetime string boolean string string references]

    expect(mg.generator_config.fields).to be_a mg.generator_config.class.class_for(:fields)

    new_config = mg.generator_config.send(:options_to_config_hash)
    expect(new_config).to be_a Hash
    expect(new_config).to eq(
      data_dictionary: { domain: nil, form_name: nil, source_name: nil, source_type: nil, study: nil },
      options: { table_comment: 'Test CSV' },
      fields: {
        a_string: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :string },
        a_int: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :integer },
        a_float: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :float },
        a_date: { caption: nil, comment: nil, label: nil, no_downcase: nil,  type: :date },
        a_time: { caption: nil, comment: nil, label: nil, no_downcase: nil,  type: :datetime },
        a_mixed_string: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :string },
        a_boolean: { caption: nil, comment: nil, label: nil, no_downcase: nil,  type: :boolean },
        a_unknown: { caption: nil, comment: nil, label: nil, no_downcase: nil,  type: :string },
        a_string2: { caption: nil, comment: nil, label: nil, no_downcase: nil,  type: :string },
        master_id: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :references }
      }
    )

    new_yaml = mg.generator_config.send(:config_hash_to_yaml)
    expect(new_yaml).to eq <<~END_TEXT
      data_dictionary:
        study:#{' '}
        source_name:#{' '}
        source_type:#{' '}
        domain:#{' '}
        form_name:#{' '}
      options:
        table_comment: Test CSV
      fields:
        a_string:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_int:
          type: integer
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_float:
          type: float
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_date:
          type: date
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_time:
          type: datetime
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_mixed_string:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_boolean:
          type: boolean
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_unknown:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_string2:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        master_id:
          type: references
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
    END_TEXT

    mg.generator_config.fields[:a_time].caption = 'A time field'
    new_config = mg.generator_config.send(:options_to_config_hash).deep_symbolize_keys
    expect(new_config).to eq(
      data_dictionary: { domain: nil, form_name: nil, source_name: nil, source_type: nil, study: nil },
      fields: {
        a_string: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :string },
        a_int: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :integer },
        a_float: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :float },
        a_date: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :date },
        a_time: { comment: nil, label: nil, no_downcase: nil, type: :datetime, caption: 'A time field' },
        a_mixed_string: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :string },
        a_boolean: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :boolean },
        a_unknown: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :string },
        a_string2: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :string },
        master_id: { caption: nil, comment: nil, label: nil, no_downcase: nil, type: :references }
      },
      options: { table_comment: 'Test CSV' }
    )

    expect(@admin).to be_a Admin
    mg.current_admin = @admin
    mg.save!

    updated_yaml = <<~END_TEXT
      data_dictionary:
        study:#{' '}
        source_name:#{' '}
        source_type:#{' '}
        domain:#{' '}
        form_name:#{' '}
      options:
        table_comment: Test CSV
      fields:
        a_string:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_int:
          type: integer
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_float:
          type: float
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_date:
          type: date
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_time:
          type: datetime
          label:#{' '}
          caption: A time field
          comment:#{' '}
          no_downcase:#{' '}
        a_mixed_string:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_boolean:
          type: boolean
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_unknown:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        a_string2:
          type: string
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
        master_id:
          type: references
          label:#{' '}
          caption:#{' '}
          comment:#{' '}
          no_downcase:#{' '}
    END_TEXT

    expect(mg.options).to eq updated_yaml

    mg.reload

    expect(mg.options).not_to be_blank
    expect(mg.options).to eq updated_yaml
  end

  describe 'CSV header labels' do
    it 'sets a field label from the original CSV header when normalization changes the name' do
      csv = <<~CSV
        Blood Pressure (Systolic),already_clean
        120,ok
      CSV

      mg = Imports::ModelGenerator.new(
        name: 'Label test',
        dynamic_model_table: 'test_csv_imports_labels',
        description: 'Header label test'
      )

      mg.analyze_csv(csv)

      expect(mg.generator_config.fields[:blood_pressure_systolic].label).to eq('Blood Pressure (Systolic)')
      expect(mg.generator_config.fields[:already_clean].label).to be_nil
    end
  end

  describe 'dynamic_model_def_current? stability after label assignment' do
    before :all do
      csv = <<~CSV
        A String!,A Int!
        hello,1
      CSV
      table = "dynamic_test.test_importslabel#{rand 100_000_000_000_000}_recs"
      @label_mg = Imports::ModelGenerator.new(
        name: 'Label current test',
        dynamic_model_table: table,
        category: 'dynamic-test-env',
        current_admin: @admin
      )
      @label_mg.analyze_csv(csv)
      @label_mg.create_dynamic_model
    end

    it 'returns true after re-analyzing a CSV whose headers were normalized to set labels' do
      # Confirms labels generated from CSV headers (issue #1099) are persisted to the
      # dynamic model and remain consistent on re-analysis. Without label persistence
      # via dynamic model default_options.labels, dynamic_model_def_current? would
      # return false on the second analyze pass.
      expect(@label_mg.generator_config.fields[:a_string].label).to eq('A String!')
      expect(@label_mg.generator_config.fields[:a_int].label).to eq('A Int!')

      csv = <<~CSV
        A String!,A Int!
        hello,1
      CSV
      @label_mg.analyze_csv(csv)

      expect(@label_mg.generator_config.fields[:a_string].label).to eq('A String!')
      expect(@label_mg.dynamic_model_def_current?).to be true
    end
  end
end
