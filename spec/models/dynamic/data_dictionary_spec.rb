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

    @dmdef = dm
  end

  it 'gets a field config from a dynamic model' do
    dd = Dynamic::DataDictionary.new @dmdef
    name = :notes
    type = :string
    col = double(name: name, type: type)
    caption = 'Description'
    expected_caption = Formatter::Substitution.text_to_html(caption)
    res = dd.field_config_for(col)

    expect(res[:caption]).to eq expected_caption
    expect(res[:type]).to eq type
    expect(res[:label]).to be nil
    expect(res[:comment]).to be nil
  end

  it 'represents all fields in the model' do
    dd = Dynamic::DataDictionary.new(@dmdef)
    expect(dd.fields).to be_a Hash
    expect(dd.fields['ready']).to be_a Dynamic::DataDictionary::Fields::Fields
    expect(dd.fields['ready'].caption).to eq Formatter::Substitution.text_to_html('Ready to send?')
    expect(dd.fields['ready'].type).to eq :string
    expect(dd.fields['notes'].caption).to eq Formatter::Substitution.text_to_html('Description')
    expect(dd.fields['notes'].type).to eq :string
  end
end
