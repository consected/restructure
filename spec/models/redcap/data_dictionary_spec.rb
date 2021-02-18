# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::DataDictionary, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'stores the data dictionary metadata for future reference' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    expect(rc.redcap_data_dictionary.captured_metadata).to eq rc.api_client.metadata
  end

  it 'produces a list of all fields from all forms' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    count_fields = 0
    dd.forms.each do |_k, form|
      count_fields += form.fields.length
    end

    expect(dd.all_fields).to be_a Hash
    expect(dd.all_fields.length).to eq count_fields

    expect(dd.record_id_field).to eq :record_id
  end

end
