# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ActivityLogsController, type: :controller do
  include AdminActivityLogSupport

  def object_class
    ActivityLog
  end

  def item
    @activity_log
  end

  before(:all) do
    @path_prefix = '/admin'
    seed_database

    unless ActivityLog.connection.table_exists? 'activity_log_player_contact_emails'
      TableGenerators.activity_logs_table('activity_log_player_contact_emails', 'player_contacts', true, 'emailed_when')
    end

    Rails.cache.clear

    if PlayerContact.valid_rec_types.empty?
      raise "Bad Seed! #{PlayerContact.valid_rec_types}"
    end
  end

  before :each do
    seed_database
  end

  it_behaves_like 'a standard admin controller'
end
