# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1098:
# - Model generation from CSV should return a usable error when migration fails.
RSpec.describe Imports::ModelGeneratorsController, type: :controller do
  include ::UserSupport

  render_views

  before :each do
    create_admin
  end

  before_each_login_admin

  describe 'POST #create_model' do
    it 'returns an actionable error when the migration fails for a reserved field name' do
      model_generator = Imports::ModelGenerator.create!(
        name: 'Reserved field test',
        dynamic_model_table: "dynamic_test.test_reserved_field_#{SecureRandom.hex(4)}_recs",
        category: 'dynamic-test-env',
        current_admin: @admin
      )

      allow(Imports::ModelGenerator).to receive(:find).with(model_generator.id.to_s).and_return(model_generator)
      allow(model_generator).to receive(:create_dynamic_model)
        .and_raise(ActiveRecord::StatementInvalid.new('PG::SyntaxError: ERROR: syntax error at or near "group"'))

      post :create_model, params: { id: model_generator.id }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include('group')
      expect(response.body).to include('syntax error')
    end
  end
end
