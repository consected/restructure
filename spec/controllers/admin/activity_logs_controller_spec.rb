# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ActivityLogsController, type: :controller do
  include AdminActivityLogSupport

  def object_class
    ActivityLog
  end

  def item
    @activity_log
  end

  before(:context) do
    @path_prefix = '/admin'
  end

  before :example do
    raise "Bad Seed! #{PlayerContact.valid_rec_types}" if PlayerContact.valid_rec_types.empty?
  end

  it_behaves_like 'a standard admin controller'
end
