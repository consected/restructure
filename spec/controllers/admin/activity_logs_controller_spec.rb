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

    Rails.cache.clear

    raise "Bad Seed! #{PlayerContact.valid_rec_types}" unless PlayerContact.valid_rec_types.length > 0
  end

  before :each do
    seed_database
  end

  it_behaves_like 'a standard admin controller'

end
