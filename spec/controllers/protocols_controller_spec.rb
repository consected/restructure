require 'rails_helper'


RSpec.describe ProtocolsController, type: :controller do

  include ProtocolSupport
  
  def object_class
    Protocol
  end
  def item
    @protocol
  end
  before(:all){
    TrackerHistory.destroy_all
    Tracker.destroy_all
    Protocol.all.each do |p|
      p.sub_processes.each do |s|
        s.protocol_events.destroy_all
        s.destroy
      end
    end
    Protocol.destroy_all
  }
  it_behaves_like 'a standard admin controller'
  
end
