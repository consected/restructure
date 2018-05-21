require "rails_helper"

RSpec.describe Admin::SubProcessesController, type: :routing do
  let(:object_name) { 'sub_processes' }
  let(:object_path) { '/admin/sub_processes'}
  let(:parent_params) { {}  }

  it_behaves_like 'a standard admin routing'
end
