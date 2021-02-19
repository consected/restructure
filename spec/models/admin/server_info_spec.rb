# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ServerInfo, type: :model do
  include MasterSupport

  before :example do
    create_admin
  end

  it 'requires an active admin user' do
    expect { Admin::ServerInfo.new(@admin) }.not_to raise_error

    expect do
      Admin::ServerInfo.new(nil)
    end.to raise_error(FphsException, 'Initialization with admin blank is not valid')
  end

  it 'gets a list of server settings' do
    si = Admin::ServerInfo.new(@admin)

    as = si.app_settings
    expect(as).to be_a Hash
    expect(as).not_to be_empty

    expect(as['DefaultMigrationSchema']).to eq 'ml_app'
  end

  it 'gets a list of database settings' do
    si = Admin::ServerInfo.new(@admin)

    as = si.db_settings
    expect(as).to be_a Hash
    expect(as).not_to be_empty

    expect(as[:connection][:adapter]).to eq 'postgresql'
  end
end
