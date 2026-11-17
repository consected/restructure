# frozen_string_literal: true

require 'rails_helper'

# Tests for the DynamicModelsController admin panel enhancements:
# - in_current_app_type filter
RSpec.describe Admin::DynamicModelsController, type: :controller do
  include ModelSupport
  include DynamicModelSupport

  describe 'filtering by in_current_app_type' do
    before :all do
      create_admin
      create_user
      @app_type = create_app_type(name: "filter_test_#{rand(100_000)}", label: 'Filter Test')

      # Create a test user
      @test_user = User.create!(
        email: "filter_test_#{rand(100_000)}@test.com",
        first_name: 'Filter',
        last_name: 'Test',
        current_admin: @admin
      )

      # Grant user access to the app type (required before app_type can be set)
      Admin::UserAccessControl.create!(
        app_type: @app_type,
        user: @test_user,
        resource_type: :general,
        resource_name: :app_type,
        access: :read,
        current_admin: @admin
      )

      # Now set app_type on user
      @test_user.app_type = @app_type
      @test_user.save!
      @test_user.reload
      raise "Test user app_type_id not set: #{@test_user.app_type_id}" unless @test_user.app_type_id == @app_type.id

      # Find or create a dynamic model for testing
      # First try to find an active one, if not try any that exists (may have been disabled by other tests)
      @dm_in_app = DynamicModel.active.where(table_name: 'test_created_by_recs').first
      unless @dm_in_app
        # Try to re-enable an existing disabled one
        disabled_dm = DynamicModel.where(table_name: 'test_created_by_recs', disabled: true).first
        if disabled_dm
          disabled_dm.current_admin = @admin
          disabled_dm.update!(disabled: false)
          @dm_in_app = disabled_dm
        else
          # Create a new one
          generate_test_dynamic_model
          @dm_in_app = DynamicModel.active.where(table_name: 'test_created_by_recs').first
        end
      end
      raise 'Test dynamic model not created' unless @dm_in_app

      # Add UAC for the dynamic model to associate it with the app type
      Admin::UserAccessControl.create!(
        app_type: @app_type,
        resource_type: :table,
        resource_name: @dm_in_app.resource_name.pluralize,
        access: :read,
        current_admin: @admin
      )
    end

    after :all do
      @app_type&.update!(disabled: true, current_admin: @admin)
    end

    before :each do
      sign_in @admin
      # Set up the matching user for the admin
      allow(@admin).to receive(:matching_user).and_return(@test_user)
    end

    it 'filters dynamic models that are in the current app type when filter is yes' do
      controller.instance_variable_set(:@current_admin, @admin)
      allow(controller).to receive(:current_admin).and_return(@admin)
      # Set the instance variable that filter_params populates
      controller.instance_variable_set(:@in_current_app_type_filter, 'yes')
      # Return empty hash so parent doesn't try to filter on non-existent column
      allow(controller).to receive(:filter_params).and_return({})

      pm = controller.send(:filtered_primary_model)
      expect(pm.pluck(:id)).to include(@dm_in_app.id)
    end

    it 'filters dynamic models that are NOT in the current app type when filter is no' do
      allow(@admin).to receive(:matching_user).and_return(@test_user)
      controller.instance_variable_set(:@current_admin, @admin)
      allow(controller).to receive(:current_admin).and_return(@admin)
      # Set the instance variable that filter_params populates
      controller.instance_variable_set(:@in_current_app_type_filter, 'no')
      # Return empty hash so parent doesn't try to filter on non-existent column
      allow(controller).to receive(:filter_params).and_return({})

      pm = controller.send(:filtered_primary_model)
      expect(pm.pluck(:id)).not_to include(@dm_in_app.id)
    end
  end

  describe 'filters configuration' do
    before do
      create_admin
      sign_in @admin
    end

    it 'includes in_current_app_type in the filters' do
      filters = controller.send(:filters)
      expect(filters).to have_key(:in_current_app_type)
      expect(filters[:in_current_app_type]).to eq(%w[yes no])
    end

    it 'includes in_current_app_type in filters_on' do
      filters_on = controller.send(:filters_on)
      expect(filters_on).to include(:in_current_app_type)
    end

    it 'does not strip in_current_app_type from filter_params, so the filter dropdown can show the current selection' do
      get :index, params: { filter: { in_current_app_type: 'yes' } }
      expect(controller.send(:filter_params)[:in_current_app_type]).to eq('yes')
    end

    it 'declares in_current_app_type as a non-column filter key, so its "Not set" dropdown option is suppressed' do
      expect(controller.send(:non_column_filter_keys)).to include(:in_current_app_type)
    end
  end
end
