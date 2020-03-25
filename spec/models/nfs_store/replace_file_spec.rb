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
    setup_nfs_store

    @activity_log = @container.parent_item
    @activity_log.extra_log_type = :step_1
    @activity_log.save!
  end

  before :each do
    @activity_log = @container.parent_item
    @activity_log.extra_log_type = :step_1
  end
end
