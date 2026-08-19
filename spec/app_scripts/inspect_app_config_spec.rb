# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'inspect_app_config validation helper' do
  let(:script_path) { Rails.root.join('app-scripts/inspect_app_config.rb').to_s }

  before do
    load script_path
  end

  it 'validates a dynamic-model option record using the app option-config schema' do
    record = {
      '_class_name' => 'DynamicModel',
      'table_name' => 'test_config_validation',
      'name' => 'test_config_validation',
      'field_list' => 'name',
      'options' => <<~YAML
        default:
          label:
            is_wrong: true
      YAML
    }

    notices = validate_option_config_record(record)

    expect(notices).not_to be_empty
    expect(notices.first[:type]).to eq(:label)
  end

  it 'formats validation notices with a simple ERROR prefix' do
    notice = {
      type: :label,
      name: 'default',
      message: 'unexpected label structure'
    }

    output = format_validation_notice({ 'table_name' => 'test_config_validation' }, notice)

    expect(output).to eq('ERROR: label: unexpected label structure')
  end
end
