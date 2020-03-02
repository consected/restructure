# frozen_string_literal: true

# Feature: Set up activity logs for record types
# As an administrator
# I want to set up a new activity log for a record type belonging to a master record
# In order that users can log activity specific to that record type
#
# Background:
# Given the admin has logged in
#
# Scenario: add a phone log related to player contacts of type phone
# Given the DBA has created an appropriate al_phone_log table
# When the admin views the activity log configuration page
# Then the al_phone_log table can be selected as an activity log table
# And a title Phone Log can be added to the configuration
#
# Scenario: verify phone log
# Given the admin has added the phone log configuration
# When the admin views the activity log configuration page
# Then the al_phone_log table and title Phone Log can be seen
#
#
#

require 'rails_helper'
SetupHelper.feature_setup

describe 'Call log admin', driver: :app_firefox_driver do
  include ActivityLogMain

  before :all do
    setup_database
    user_logs_in
  end
end
