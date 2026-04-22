# frozen_string_literal: true

# Admin::ReportsController Spec (issue #63)
#
# Tests the search_attr_definer action cache headers.
# The action should set private Cache-Control headers to prevent WAFs
# from caching admin-specific content.

require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do
  include MasterSupport

  before_each_login_admin

  describe '#search_attr_definer (issue #63)' do
    it 'sets Cache-Control with private and max-age' do
      get :search_attr_definer

      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('private')
      expect(cache_control).to include("max-age=#{48.hours.to_i}")
      expect(cache_control).not_to include('immutable')
    end
  end
end
