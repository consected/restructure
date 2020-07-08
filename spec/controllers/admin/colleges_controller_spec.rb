# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::CollegesController, type: :controller do
  include CollegeSupport

  def object_class
    Classification::College
  end

  def item
    @college
  end

  it_behaves_like 'a standard admin controller'
end
