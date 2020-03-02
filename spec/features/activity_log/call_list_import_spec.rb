# frozen_string_literal: true

# Feature: Rapidly enter call details from a list of Master IDs
#   As a rep
#   I want to be able to provide a Zeus user with a list of players I have called
#   In order that Zeus can be updated accurately, with minimal effort on my part
#   -
#   As a user
#   I want to take a list of players that were contacted by a rep
#   In order that I can rapidly enter the call details for the rep, meeting all the activity tracking requirements

require 'rails_helper'
SetupHelper.feature_setup

describe 'Import list of calls to log', driver: :app_firefox_driver do
  include ActivityLogMain

  before :all do
    setup_database
    user_logs_in
  end
end
