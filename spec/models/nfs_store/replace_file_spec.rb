# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe 'Replace stored files', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :all do
    seed_database && ::ActivityLog.define_models
    # setup_nfs_store
  end

  before :each do
    setup_nfs_store
    setup_container_and_al
    setup_default_filters
  end
end
