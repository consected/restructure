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

    expect(rc.redcap_data_dictionary.captured_metadata).to eq rc.project_client.metadata
  end
end
