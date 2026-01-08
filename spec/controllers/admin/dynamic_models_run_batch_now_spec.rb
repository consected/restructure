# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DynamicModelsController, type: :controller do
  include ModelSupport
  include UserSupport

  describe 'POST #run_batch_now' do
    before do
      create_admin
      sign_in @admin, scope: :admin
      SetupHelper.setup_al_player_contact_phones
    end

    let!(:dynamic_model) do
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: 'Test Batch Model',
        table_name: 'test_version_tracking_recs',
        schema_name: 'dynamic_test',
        category: 'test',
        field_list: 'test_field',
        options: <<~YAML
          _configurations:
            batch_trigger:
              frequency: '1 hour'
              limit: 10
              user: batch_user@test.com

          default:
            label: Default
            fields:
              - test_field
          #{'  '}
            batch_trigger:
              on_record:
                update_this:
                  one:
                    with:
                      test_field: 'processed'
        YAML
      )
      dm.current_admin = @admin
      dm.update_tracker_events
      dm
    end

    it 'returns error when batch_trigger is not configured' do
      dm_no_batch = DynamicModel.create!(
        current_admin: @admin,
        name: 'No Batch Model',
        table_name: 'test_version_tracking_recs',
        schema_name: 'dynamic_test',
        category: 'test',
        field_list: 'test_field',
        options: <<~YAML
          default:
            label: Default
            fields:
              - test_field
        YAML
      )

      post :run_batch_now, params: { id: dm_no_batch.id }, format: :js

      expect(response).to have_http_status(:success)
      expect(assigns(:error_message)).to eq('Batch trigger not configured for this model')
    end

    it 'successfully runs batch processing' do
      # Get the implementation class and mock trigger_batch_now
      impl_class = dynamic_model.implementation_class

      # We need to allow the class method to be called
      expect(impl_class).to receive(:trigger_batch_now).with(limit: 10, alt_user: instance_of(User)).and_return([1, 2, 3])

      post :run_batch_now, params: { id: dynamic_model.id }, format: :js

      expect(response).to have_http_status(:success)
      expect(assigns(:success_message)).to include('Batch processing completed')
      expect(assigns(:success_message)).to include('3 record(s)')
      expect(assigns(:processed_ids)).to eq([1, 2, 3])
    end

    it 'handles errors gracefully' do
      # Get the implementation class and mock to raise error
      impl_class = dynamic_model.implementation_class

      # Expect trigger_batch_now to be called and raise error
      expect(impl_class).to receive(:trigger_batch_now).with(limit: 10, alt_user: instance_of(User)).and_raise(StandardError.new('Test error'))

      post :run_batch_now, params: { id: dynamic_model.id }, format: :js

      expect(response).to have_http_status(:success)
      expect(assigns(:error_message)).to include('Batch processing failed')
      expect(assigns(:error_message)).to include('Test error')
    end

    it 'requires admin authentication' do
      sign_out @admin

      post :run_batch_now, params: { id: dynamic_model.id }, format: :js

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
