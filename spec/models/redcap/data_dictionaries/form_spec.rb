# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::DataDictionaries::Form, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'generates forms definition instances' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    expect(dd.forms.length).to eq 2
    expect(dd.forms.keys).to eq %i[q2_survey test]
  end
  it 'generates forms configuration' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    res = Redcap::DataDictionaries::Form.all_from(dd)
    expect(res).to be_a Hash
    expect(res.first.first).to be_a Symbol
    expect(res.first.last).to be_a Redcap::DataDictionaries::Form

    res = Redcap::DataDictionaries::Form.form_names(dd.captured_metadata)
    expect(res).to be_a Array
    expect(res.first).to eq :q2_survey
  end

  it 'gets a full list of fields to be persisted to' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary
    fs = Redcap::DataDictionaries::Form.all_retrievable_fields(dd)

    expect(fs.keys).to eq %i[record_id dob current_weight smoketime___pnfl smoketime___dnfl smoketime___anfl smoke_start smoke_stop
                             smoke_curr demog_date ncmedrec_add ladder_wealth ladder_comm born_address twelveyrs_address
                             othealth___complete othealth_date q2_survey_complete
                             sdfsdaf___0 sdfsdaf___1 sdfsdaf___2
                             rtyrtyrt___0 rtyrtyrt___1 rtyrtyrt___2
                             test_field test_phone i57 f57 dd yes_or_no test_complete]
  end
end
