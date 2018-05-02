require "rails_helper"

RSpec.describe Admin::ProtocolEventsController, type: :routing do
  let(:object_name) { 'protocol_events' }
  let(:object_path) { '/admin/protocols/3/sub_processes/2/protocol_events'}
  let(:parent_params) { {protocol_id: '3', sub_process_id: '2'}  }

  it_behaves_like 'a standard admin routing'
end
