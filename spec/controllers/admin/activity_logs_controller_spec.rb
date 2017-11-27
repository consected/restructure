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
    @path_prefix = "/admin"
    seed_database

    ActivityLog.connection.execute "
      delete from activity_log_history;
      delete from activity_logs;
    "

    if ActivityLog.connection.table_exists? "activity_log_player_contact_emails"
      sql = TableGenerators.activity_logs_table('activity_log_player_contact_emails', 'player_contacts', :drop_do)
    end

    TableGenerators.activity_logs_table('activity_log_player_contact_emails', 'player_contacts', true, 'emailed_when')


    Rails.cache.clear

    raise "Bad Seed! #{PlayerContact.valid_rec_types}" unless PlayerContact.valid_rec_types.length > 0
  end

  before :each do
    seed_database
  end

  it_behaves_like 'a standard admin controller'

end
