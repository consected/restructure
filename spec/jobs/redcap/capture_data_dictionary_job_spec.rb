require 'rails_helper'

# Test the pulling of a data dictionary from a demo project in Redcap.
# This test calls both mocks and a live endpoint (if configured).
# The live endpoint configuration must be set up in the initializer
# recap_config.rb
RSpec.describe Redcap::CaptureDataDictionaryJob, type: :job do
  include Redcap::RedcapSupport

  before :example do
    @rc_project_configs = setup_redcap_project_admin_configs
  end
end
