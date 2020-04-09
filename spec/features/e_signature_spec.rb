# frozen_string_literal: true

require 'rails_helper'

describe 'Electronically sign a record', driver: :app_firefox_driver do
  include ActivityLogMain

  before :all do
    SetupHelper.feature_setup

    seed_database
    setup_database
    ::ActivityLog.define_models

    user_logs_in
  end

  describe 'show document to sign' do
    before :all do
      # user_views_contact_record
      # show_top_ranked_phone_log
      # expect_phone_log_to_be_visible
      # indicate_user_received_a_call
      # mark_call_status ActivityLogMain::CallConnected
      # mark_next_step_status ActivityLogMain::NextStepComplete
      # add_free_text_notes 'The player called us'
      # save_log
    end

    it 'shows an action on an activity log to sign a document'

    it 'shows the review document and all its fields'
  end
end
