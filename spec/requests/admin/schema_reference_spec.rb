# frozen_string_literal: true

# Tests for the schema_reference collection action on the three admin controllers:
# Admin::DynamicModelsController, Admin::ActivityLogsController, Admin::ExternalIdentifiersController
#
# The action returns the accepted config schema for the respective option configs class
# in JSON or YAML format based on the request format.
# The activity log schema additionally includes activity-log-specific configs (e_sign_config, nfs_store)
# that are not present in the dynamic model or external identifier schemas.
# Unauthenticated requests are redirected to the admin sign-in page.

require 'rails_helper'

describe 'Admin schema_reference endpoints' do
  include ModelSupport

  before(:each) do
    create_admin
    sign_in @admin
  end

  describe 'GET /admin/dynamic_models/schema_reference' do
    context 'when requesting JSON' do
      before { get '/admin/dynamic_models/schema_reference.json' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns application/json content type' do
        expect(response.content_type).to include('application/json')
      end

      it 'returns a JSON schema with trigger_types key' do
        body = JSON.parse(response.body)
        expect(body).to have_key('trigger_types')
      end

      it 'does not include e_sign_config in base_option_configs' do
        body = JSON.parse(response.body)
        base_configs = body['base_option_configs'] || {}
        expect(base_configs.keys).not_to include('e_sign_config')
        expect(base_configs.keys).not_to include('nfs_store')
      end
    end

    context 'when requesting YAML' do
      before { get '/admin/dynamic_models/schema_reference.yaml' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns YAML content type' do
        expect(response.content_type).to include('application/x-yaml')
      end

      it 'returns parseable YAML with trigger_types key' do
        body = YAML.safe_load(response.body)
        expect(body).to have_key('trigger_types')
      end
    end
  end

  describe 'GET /admin/activity_logs/schema_reference' do
    context 'when requesting JSON' do
      before { get '/admin/activity_logs/schema_reference.json' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns application/json content type' do
        expect(response.content_type).to include('application/json')
      end

      it 'returns a JSON schema with trigger_types key' do
        body = JSON.parse(response.body)
        expect(body).to have_key('trigger_types')
      end

      it 'includes e_sign_config and nfs_store in base_option_configs' do
        body = JSON.parse(response.body)
        base_configs = body['base_option_configs'] || {}
        expect(base_configs.keys).to include('e_sign_config')
        expect(base_configs.keys).to include('nfs_store')
      end
    end

    context 'when requesting YAML' do
      before { get '/admin/activity_logs/schema_reference.yaml' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns YAML content type' do
        expect(response.content_type).to include('application/x-yaml')
      end

      it 'returns parseable YAML including e_sign_config' do
        body = YAML.safe_load(response.body)
        base_configs = body['base_option_configs'] || {}
        expect(base_configs.keys).to include('e_sign_config')
      end
    end
  end

  describe 'GET /admin/external_identifiers/schema_reference' do
    context 'when requesting JSON' do
      before { get '/admin/external_identifiers/schema_reference.json' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns application/json content type' do
        expect(response.content_type).to include('application/json')
      end

      it 'returns a JSON schema with trigger_types key' do
        body = JSON.parse(response.body)
        expect(body).to have_key('trigger_types')
      end

      it 'does not include e_sign_config in base_option_configs' do
        body = JSON.parse(response.body)
        base_configs = body['base_option_configs'] || {}
        expect(base_configs.keys).not_to include('e_sign_config')
        expect(base_configs.keys).not_to include('nfs_store')
      end
    end

    context 'when requesting YAML' do
      before { get '/admin/external_identifiers/schema_reference.yaml' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns YAML content type' do
        expect(response.content_type).to include('application/x-yaml')
      end

      it 'returns parseable YAML with trigger_types key' do
        body = YAML.safe_load(response.body)
        expect(body).to have_key('trigger_types')
      end
    end
  end

  describe 'unauthenticated access' do
    before { sign_out @admin }

    # Non-HTML format requests return 401 (Devise failure behavior for JSON/YAML clients)
    it 'returns 401 for dynamic_models schema_reference without authentication' do
      get '/admin/dynamic_models/schema_reference.json'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 for activity_logs schema_reference without authentication' do
      get '/admin/activity_logs/schema_reference.json'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 for external_identifiers schema_reference without authentication' do
      get '/admin/external_identifiers/schema_reference.json'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
