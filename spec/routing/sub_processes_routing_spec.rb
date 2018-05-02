require "rails_helper"

RSpec.describe Admin::SubProcessesController, type: :routing do
  let(:object_name) { 'sub_processes' }
  let(:object_path) { '/admin/protocols/3/sub_processes'}
  let(:parent_params) { {protocol_id: '3'}  }

  it_behaves_like 'a standard admin routing'
end
