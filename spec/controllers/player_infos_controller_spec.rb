# frozen_string_literal: true

# PlayerInfosController Spec
#
# Tests for the PlayerInfosController, which includes MasterHandler.
# - Standard user controller behavior (shared examples)
# - MasterHandler cached index sets private Cache-Control header (issue #63)

require 'rails_helper'

RSpec.describe PlayerInfosController, type: :controller do
  include PlayerInfoSupport

  def object_class
    PlayerInfo
  end

  def item
    @player_info
  end

  def edit_form_prefix
    @edit_form_prefix = 'common_templates'
  end

  it_behaves_like 'a standard user controller'

  # Issue #63: MasterHandler cached index should set private Cache-Control header
  describe 'GET #index with cache_result (issue #63)' do
    before_each_login_user

    before :each do
      create_admin
      setup_access :player_infos
      create_items
    end

    it 'sets Cache-Control with private and max-age when cache_result is present' do
      get :index, params: { master_id: @master_id, cache_result: true, format: :json }

      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('private')
      expect(cache_control).to include('max-age=30')
      expect(cache_control).not_to include('immutable')
    end
  end
end
