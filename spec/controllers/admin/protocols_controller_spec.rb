# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ProtocolsController, type: :controller do
  include ProtocolSupport

  let(:object_param_symbol) do
    :classification_protocol
  end

  def object_class
    Classification::Protocol
  end

  def edit_form_admin
    @edit_form_admin = 'admin/common_templates/_form'
  end

  def saved_item_template
    'admin/common_templates/_item'
  end

  def item
    @protocol
  end
  before(:example) do
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
  end
  it_behaves_like 'a standard admin controller'
end
