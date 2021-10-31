# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Dynamic model implementation description using both imported apps and direct configurations
RSpec.describe 'Dynamic Data Dictionary', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include DynamicModelSupport

  before :example do
    # Seeds.setup

    @user0, = create_user
    create_admin
    create_user

    import_bulk_msg_app
    dm = DynamicModel::ZeusBulkMessage.definition
    dm.current_admin = @admin
    dm.update_tracker_events

    @ddconf = dm.data_dictionary = {
      study: 'All Study',
      source_type: 'operational database'
    }

    @dmdef = dm
  end

  it 'gets a field config from a dynamic model' do
    name = :notes
    type = :string
    col = double(name: name, type: type)
    caption = 'Description'
    expected_caption = Formatter::Substitution.text_to_html(caption)
    dd = Dynamic::DataDictionary.new(@dmdef)
    ddv = Dynamic::DynamicModelField.new(dd, col.name, col.type)

    expect(ddv.label_plain).to eq expected_caption
    expect(ddv.field_type).to eq type
  end

  it 'defines all fields in the model' do
    dd = Dynamic::DataDictionary.new(@dmdef)
    expect(dd.fields).to be_a Hash
    expect(dd.fields['ready']).to be_a Dynamic::DynamicModelField
    expect(dd.fields['ready'].label_plain).to eq Formatter::Substitution.text_to_html('Ready to send?')
    expect(dd.fields['ready'].field_type).to eq :string
    expect(dd.fields['notes'].label_plain).to eq Formatter::Substitution.text_to_html('Description')
    expect(dd.fields['notes'].field_type).to eq :string
  end

  it 'adds fields as data dictionary variable records' do
    dmdd = @dmdef.data_dictionary
    expect(dmdd).to be_a Hash

    dd = Dynamic::DataDictionary.new(@dmdef)

    expect(dd.dynamic_model_data_dictionary_config).to be_a Hash
    expect(dd.default_config).to be_a Hash
    expect(dd.default_config[:source_name]).to eq @dmdef.name
    expect(dd.default_config[:source_type]).to eq 'operational database'
    expect(dd.default_config[:domain]).to be nil

    dd.refresh_variables_records

    ddv = Datadic::Variable.last
    expect(ddv).to be_a Datadic::Variable

    dd.column_variable_names.each do |fn|
      ddv = Dynamic::DatadicVariable.find_by_identifiers(source_name: @dmdef.name, source_type: @ddconf[:source_type], form_name: @ddconf[:form_name], variable_name: fn).first
      expect(ddv).to be_a Datadic::Variable
      expect(ddv.variable_name).to eq fn
      expect(ddv.source_name).to eq ddv[:source_name]
      expect(ddv.source_type).to eq ddv[:source_type]
      expect(ddv.form_name).to eq ddv[:form_name]
    end
  end
end
