require "rails_helper"

RSpec.describe Admin::ProtocolEventsController, type: :routing do
  let(:object_name) { 'protocol_events' }
  let(:object_path) { '/admin/protocol_events'}
  let(:parent_params) { {}  }

  it_behaves_like 'a standard admin routing'
end
