# frozen_string_literal: true

# Purpose: Verify that Settings::AppSettingsVars entries all resolve to valid values.
# Tests the fix for issue #1248 where NfsStoreJobDefaultAppTypeId was listed in AppSettingsVars
# but had no corresponding constant, causing NameError on the Admin → Server Info screen.
# The fix updates AppSettingsVars to use nfs_store_default_app_type_id and adds a NameError rescue
# in Admin::ServerInfo#app_settings that falls back to the underscored method name on Settings.

require 'rails_helper'

RSpec.describe 'Settings::AppSettingsVars', type: :model do
  include MasterSupport

  before :example do
    create_admin
  end

  describe 'NfsStoreDefaultAppTypeId' do
    it 'is included in AppSettingsVars as a method name' do
      expect(Settings::AppSettingsVars).to include('nfs_store_default_app_type_id')
    end

    it 'has a corresponding Settings method that returns an Integer' do
      expect(Settings.nfs_store_default_app_type_id).to be_a(Integer)
    end
  end

  describe 'NfsStoreJobDefaultAppTypeId (removed)' do
    it 'is NOT included in AppSettingsVars' do
      expect(Settings::AppSettingsVars).not_to include('NfsStoreJobDefaultAppTypeId')
    end
  end

  describe 'Admin::ServerInfo#app_settings' do
    it 'resolves every AppSettingsVars entry to a value without error' do
      result = Admin::ServerInfo.new(@admin).app_settings
      expect(result).to be_a(Hash)
      expect(result['nfs_store_default_app_type_id']).to be_a(Integer)
      Settings::AppSettingsVars.each do |entry|
        expect(result[entry]).not_to match(/\ANameError:/),
                                     "app_settings returned a NameError for entry '#{entry}'"
      end
    end
  end
end
