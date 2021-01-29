# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::DataDictionary, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
  end
end
