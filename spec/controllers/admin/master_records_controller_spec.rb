# frozen_string_literal: true

# Tests for Admin::MasterRecordsController (issue #930)
#
# The Master Records admin page appears under the "Definitions" section of the
# admin panel. It is a read-only page (no create/update/destroy) that shows:
#   - An informational header about the masters table
#   - A table of standard master-associated models with a Show button
#
# These tests verify:
# - The index action requires admin authentication
# - The index action is accessible to an admin with the :master_records capability
# - An admin without the :master_records capability receives HTTP 401
# - The index action assigns the list of master record presenters
# - The show action returns the details for a specific master-associated model
# - Create, update and destroy routes do not exist (read-only resource)

require 'rails_helper'

RSpec.describe Admin::MasterRecordsController, type: :controller do
  include ModelSupport

  describe 'GET #index' do
    context 'when not authenticated' do
      it 'redirects to the admin sign-in page' do
        get :index
        expect(response).to redirect_to(new_admin_session_path)
      end
    end

    context 'when authenticated as an admin with master_records capability' do
      before_each_login_admin

      it 'returns HTTP 200' do
        get :index
        expect(response).to have_http_status(200)
      end

      it 'assigns the list of master record presenters to @admin_objects' do
        get :index
        expect(assigns(:admin_objects)).to be_an Array
        expect(assigns(:admin_objects).length).to eq 7
        expect(assigns(:admin_objects).first).to be_a Admin::MasterRecord
        expect(assigns(:admin_objects).first.table_name).to eq 'masters'
      end

      it 'assigns @masters_info with crosswalk, readonly and temp master id details' do
        get :index
        info = assigns(:masters_info)
        expect(info).to be_a Hash
        expect(info[:crosswalk_attrs]).to be_an Array
        expect(info[:crosswalk_attrs]).not_to be_empty
        expect(info[:readonly_attrs]).to be_an Array
        expect(info[:readonly_attrs]).not_to be_empty
        expect(info[:temporary_master_ids]).to eq Master::TemporaryMasterIds
      end
    end

    context 'when authenticated as an admin without master_records capability' do
      before_each_login_limited_admin with_capabilities: ['dynamic_models']

      it 'returns HTTP 401 (unauthorized) when master_records capability is absent' do
        get :index
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET #show' do
    context 'when authenticated as an admin with master_records capability' do
      before_each_login_admin

      it 'returns HTTP 200 for the first master record (masters)' do
        get :show, params: { id: 1 }
        expect(response).to have_http_status(200)
      end

      it 'returns HTTP 200 for the second master record (player_infos)' do
        get :show, params: { id: 2 }
        expect(response).to have_http_status(200)
      end

      it 'returns HTTP 200 for the last master record (tracker_histories)' do
        get :show, params: { id: 7 }
        expect(response).to have_http_status(200)
      end

      it 'assigns the correct Admin::MasterRecord presenter to @admin_object' do
        get :show, params: { id: 2 }
        obj = assigns(:admin_object)
        expect(obj).to be_a Admin::MasterRecord
        expect(obj.table_name).to eq Settings::DefaultSubjectInfoTableName
      end

      it 'returns HTTP 404 for an out-of-range id' do
        get :show, params: { id: 99 }
        expect(response).to have_http_status(404)
      end
    end

    context 'when not authenticated' do
      it 'redirects to the admin sign-in page' do
        get :show, params: { id: 1 }
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe 'non-existent write routes' do
    before_each_login_admin

    it 'does not route POST #create' do
      expect_to_be_bad_route(post: 'admin/master_records')
    end

    it 'does not route PATCH #update' do
      expect_to_be_bad_route(patch: 'admin/master_records/1')
    end

    it 'does not route DELETE #destroy' do
      expect_to_be_bad_route(delete: 'admin/master_records/1')
    end
  end
end
