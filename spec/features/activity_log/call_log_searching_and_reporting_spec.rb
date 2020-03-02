# frozen_string_literal: true

# Feature: Report logged call details
#   As a user
#   I want to be able to report on logged call details, linking them with tracker and player information
#   In order that I can create call lists and reports for other forms of contact
#   -
#   As a data manager
#   I want to be able to report on logged call details, linking them with tracker and player information
#   In order that I can audit the type and number of touches made to a contact
#
# Feature: Search logged call details
#   As a user
#   I want to be able to search calls made, received based on their status and other key information
#   In order that I can rapidly follow up on required call backs, bad phone numbers, etc

require 'rails_helper'
SetupHelper.feature_setup

describe 'Call log searching and reporting', driver: :app_firefox_driver do
  include ActivityLogMain

  before :all do
    setup_database
    user_logs_in
  end
end
