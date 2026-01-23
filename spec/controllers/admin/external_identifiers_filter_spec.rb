# frozen_string_literal: true

require 'rails_helper'

# Tests for the ExternalIdentifiersController admin panel enhancements:
# - in_current_app_type filter
# - extra_index_columns for "In current app type" column
#
# Issue #859: Dynamic model and external identifier access summaries in admin panel
RSpec.describe Admin::ExternalIdentifiersController, type: :controller do
  include ModelSupport

  describe 'filtering by in_current_app_type' do
    before :all do
      create_admin
      create_user
      @app_type = create_app_type(name: "ei_filter_test_#{rand(100_000)}", label: 'EI Filter Test')

      # Create a test user
      @test_user = User.create!(
        email: "ei_filter_test_#{rand(100_000)}@test.com",
        first_name: 'EIFilter',
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

      # Find an existing active external identifier for testing
      @ei_in_app = ExternalIdentifier.active.first
      next unless @ei_in_app

      # Add UAC for the external identifier to associate it with the app type
      Admin::UserAccessControl.create!(
        app_type: @app_type,
        resource_type: :table,
        resource_name: @ei_in_app.name,
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

    it 'filters external identifiers that are in the current app type when filter is yes' do
      next unless @ei_in_app

      controller.instance_variable_set(:@current_admin, @admin)
      allow(controller).to receive(:current_admin).and_return(@admin)
      # Set the instance variable that filter_params populates
      controller.instance_variable_set(:@in_current_app_type_filter, 'yes')
      # Return empty hash so parent doesn't try to filter on non-existent column
      allow(controller).to receive(:filter_params).and_return({})

      pm = controller.send(:filtered_primary_model)
      expect(pm.pluck(:id)).to include(@ei_in_app.id)
    end

    it 'filters external identifiers that are NOT in the current app type when filter is no' do
      next unless @ei_in_app

      allow(@admin).to receive(:matching_user).and_return(@test_user)
      controller.instance_variable_set(:@current_admin, @admin)
      allow(controller).to receive(:current_admin).and_return(@admin)
      # Set the instance variable that filter_params populates
      controller.instance_variable_set(:@in_current_app_type_filter, 'no')
      # Return empty hash so parent doesn't try to filter on non-existent column
      allow(controller).to receive(:filter_params).and_return({})

      pm = controller.send(:filtered_primary_model)
      expect(pm.pluck(:id)).not_to include(@ei_in_app.id)
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
  end

  describe 'extra_index_columns' do
    before do
      create_admin
      sign_in @admin
    end

    it 'includes in_current_app_type_result_checkbox' do
      extra_columns = controller.send(:extra_index_columns)
      expect(extra_columns).to have_key(:in_current_app_type_result_checkbox)
      expect(extra_columns[:in_current_app_type_result_checkbox]).to eq('In current app type')
    end
  end
end
