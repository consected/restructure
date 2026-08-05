# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1098:
# - create_model returns a usable 400 error body for migration failures from CSV-derived fields.
RSpec.describe 'Imports::ModelGenerators create_model', type: :request do
  include UserSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
  end

  before :each do
    @admin, = create_admin
    sign_in @admin
  end

  describe 'POST /imports/model_generators/:id/create_model' do
    it 'returns a bad request with actionable details when model generation raises a DB error' do
      model_generator = Imports::ModelGenerator.create!(
        name: 'Reserved field request test',
        dynamic_model_table: "dynamic_test.test_reserved_field_req_#{SecureRandom.hex(4)}_recs",
        category: 'dynamic-test-env',
        current_admin: @admin
      )

      allow(Imports::ModelGenerator).to receive(:find).with(model_generator.id.to_s).and_return(model_generator)
      allow(model_generator).to receive(:create_dynamic_model)
        .and_raise(ActiveRecord::StatementInvalid.new('PG::SyntaxError: ERROR: syntax error at or near "group"'))

      post create_model_imports_model_generator_path(model_generator)

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include('Failed to generate the dynamic model table')
      expect(response.body).to include('group')
    end
  end
end
