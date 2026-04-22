# frozen_string_literal: true

# ControllerUtils Concern Spec (issue #63)
#
# Tests the set_browser_cache method added to support private cache headers
# for user/admin-specific content, preventing WAFs from caching sensitive data.
#
# Test Coverage:
# - set_browser_cache sets Cache-Control with private and max-age directives
# - set_browser_cache sets Expires header computed from max_age
# - set_browser_cache adds immutable directive when requested
# - set_browser_cache does not add immutable by default

require 'rails_helper'

RSpec.describe ControllerUtils, type: :controller do
  include ModelSupport

  # Use MastersController as a concrete controller that includes ControllerUtils
  controller(MastersController) do
    # Inherits all behavior from MastersController
  end

  before_each_login_user

  describe '#set_browser_cache' do
    it 'sets Cache-Control with private and max-age directives' do
      get :index
      subject.send(:set_browser_cache, max_age: 300)

      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('private')
      expect(cache_control).to include('max-age=300')
    end

    it 'sets Expires header computed from max_age' do
      get :index
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)
      subject.send(:set_browser_cache, max_age: 300)

      expect(response.headers['Expires']).to eq((freeze_time + 300).httpdate)
    end

    it 'adds immutable directive when requested' do
      get :index
      subject.send(:set_browser_cache, max_age: 604_800, immutable: true)

      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('private')
      expect(cache_control).to include('max-age=604800')
      expect(cache_control).to include('immutable')
    end

    it 'does not add immutable by default' do
      get :index
      subject.send(:set_browser_cache, max_age: 30)

      expect(response.headers['Cache-Control']).not_to include('immutable')
    end
  end
end
