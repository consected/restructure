require 'rails_helper'


RSpec.describe Admin::ProtocolsController, type: :controller do

  include ProtocolSupport

  def object_class
    Classification::Protocol
  end
  def item
    @protocol
  end
  before(:all){
    TrackerHistory.destroy_all
    Tracker.destroy_all
    Classification::Protocol.connection.execute "
      delete from protocol_event_history;
      delete from protocol_events;
      delete from sub_process_history;
      delete from sub_processes;
      delete from protocol_history;
      delete from protocols;
    "
  }
  it_behaves_like 'a standard admin controller'

end
