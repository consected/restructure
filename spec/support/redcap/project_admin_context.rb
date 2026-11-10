# frozen_string_literal: true

# Shares REDCap project configuration once per group and creates a fresh admin,
# user, file-store setup, and WebMock stubs for each example. Reload shared records
# before cleanup, and do not mutate shared in-memory objects across examples.
RSpec.shared_context 'with redcap project admins' do
  include ModelSupport
  include Redcap::RedcapSupport

  before_all do
    create_admin
    setup_redcap_project_admin_configs_once
  end

  before do
    create_admin
    setup_file_store
    restub_redcap_mocks
  end
end
