# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Imports::ModelGenerator, type: :model do
  include ::UserSupport

  before :example do
    create_admin
  end

  it 'analyzes a CSV to guess at the field types' do
    csv = File.read('spec/fixtures/import/test-types.csv')

    import = Import.new
    mg = Imports::ModelGenerator.new(name: 'Test CSV',
                                     import: import,
                                     dynamic_model_table: 'test_csv_imports',
                                     description: 'A test')
    res = mg.analyze_csv(csv)

    expect(res).to be_a Hash
    expect(res.keys).to eq %i[a_string a_int a_float a_date a_time a_mixed_string a_boolean a_unknown a_string2]
    expect(res.values).to eq %i[string integer float date date_time string boolean string string]

    expect(mg.generator_config.fields).to be_a Hash

    new_config = mg.generator_config.send(:options_to_config_hash)
    expect(new_config).to be_a Hash
    expect(new_config).to eq(
      fields: {
        a_string: { name: 'a_string', type: :string },
        a_int: { name: 'a_int', type: :integer },
        a_float: { name: 'a_float', type: :float },
        a_date: { name: 'a_date', type: :date },
        a_time: { name: 'a_time', type: :date_time },
        a_mixed_string: { name: 'a_mixed_string', type: :string },
        a_boolean: { name: 'a_boolean', type: :boolean },
        a_unknown: { name: 'a_unknown', type: :string },
        a_string2: { name: 'a_string2', type: :string }
      }
    )

    new_yaml = mg.generator_config.send(:config_hash_to_yaml)
    expect(new_yaml).to eq <<~END_TEXT
      ---
      fields:
        a_string:
          name: a_string
          type: string
        a_int:
          name: a_int
          type: integer
        a_float:
          name: a_float
          type: float
        a_date:
          name: a_date
          type: date
        a_time:
          name: a_time
          type: date_time
        a_mixed_string:
          name: a_mixed_string
          type: string
        a_boolean:
          name: a_boolean
          type: boolean
        a_unknown:
          name: a_unknown
          type: string
        a_string2:
          name: a_string2
          type: string
    END_TEXT

    mg.generator_config.fields[:a_time][:comment] = 'A time field'
    new_config = mg.generator_config.send(:options_to_config_hash)
    expect(new_config).to eq(
      fields: {
        a_string: { name: 'a_string', type: :string },
        a_int: { name: 'a_int', type: :integer },
        a_float: { name: 'a_float', type: :float },
        a_date: { name: 'a_date', type: :date },
        a_time: { name: 'a_time', type: :date_time, comment: 'A time field' },
        a_mixed_string: { name: 'a_mixed_string', type: :string },
        a_boolean: { name: 'a_boolean', type: :boolean },
        a_unknown: { name: 'a_unknown', type: :string },
        a_string2: { name: 'a_string2', type: :string }
      }
    )

    expect(@admin).to be_a Admin
    mg.current_admin = @admin
    mg.save!

    updated_yaml = <<~END_TEXT
      ---
      fields:
        a_string:
          name: a_string
          type: string
        a_int:
          name: a_int
          type: integer
        a_float:
          name: a_float
          type: float
        a_date:
          name: a_date
          type: date
        a_time:
          name: a_time
          type: date_time
          comment: A time field
        a_mixed_string:
          name: a_mixed_string
          type: string
        a_boolean:
          name: a_boolean
          type: boolean
        a_unknown:
          name: a_unknown
          type: string
        a_string2:
          name: a_string2
          type: string
    END_TEXT

    expect(mg.options).to eq updated_yaml

    mg.reload

    expect(mg.options).not_to be_blank

    expect(mg.options).to eq updated_yaml
  end
end
