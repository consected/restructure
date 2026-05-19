# frozen_string_literal: true

require 'rails_helper'

# Tests for the automatic name filter feature in AdminControllerHandler - Issue #1159
# "Any admin page that has a 'name' field should also have a filter on that field"
#
# Verifies that AdminControllerHandler adds two new methods:
#   - #effective_filters  - returns #filters merged with auto-detected name filter
#   - #effective_filters_on - returns #filters_on with :name auto-appended when needed
#
# Test Coverage:
# - effective_filters auto-includes name filter for models with a name column
# - effective_filters_on auto-includes :name for models with a name column
# - Neither method duplicates name when it is already explicitly defined
# - filter_params_permitted honours effective_filters_on so name params are permitted
#
# Uses Admin::AccuracyScoresController because:
#   - its primary model (Classification::AccuracyScore) has a 'name' column
#   - it defines no explicit filters or filters_on, making auto-detection unambiguous

RSpec.describe Admin::AccuracyScoresController, type: :controller do
  include ModelSupport
  include AccuracyScoreSupport

  before :all do
    create_admin
  end

  before :each do
    sign_in @admin
  end

  # ---------------------------------------------------------------------------
  # effective_filters
  # ---------------------------------------------------------------------------
  describe '#effective_filters' do
    context 'when the primary model has a name column and no name filter is defined' do
      it 'auto-includes the name filter key' do
        # AccuracyScoresController defines no filters, but Classification::AccuracyScore
        # has a 'name' column – effective_filters should detect this automatically.
        effective = controller.send(:effective_filters)

        expect(effective).to have_key(:name)
      end

      it 'returns an Array as the name filter values' do
        effective = controller.send(:effective_filters)

        expect(effective[:name]).to be_an(Array)
      end

      it 'merges the auto-detected name filter with any pre-existing filters' do
        allow(controller).to receive(:filters).and_return({ value: [1, 2] })

        effective = controller.send(:effective_filters)

        expect(effective).to have_key(:value)
        expect(effective).to have_key(:name)
      end
    end

    context 'when the primary model already has a name filter defined' do
      it 'does not duplicate the name key' do
        allow(controller).to receive(:filters).and_return({ name: %w[foo bar] })

        effective = controller.send(:effective_filters)

        expect(effective.keys.count { |k| k == :name }).to eq(1)
      end

      it 'preserves the existing name filter values' do
        allow(controller).to receive(:filters).and_return({ name: %w[foo bar] })

        effective = controller.send(:effective_filters)

        expect(effective[:name]).to eq(%w[foo bar])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # effective_filters_on
  # ---------------------------------------------------------------------------
  describe '#effective_filters_on' do
    context 'when the primary model has a name column and :name is not in filters_on' do
      it 'auto-appends :name to the filters_on list' do
        # AccuracyScoresController returns [] from filters_on
        effective_on = controller.send(:effective_filters_on)

        expect(effective_on).to include(:name)
      end
    end

    context 'when :name is already in filters_on' do
      it 'does not duplicate :name' do
        allow(controller).to receive(:filters_on).and_return([:name])

        effective_on = controller.send(:effective_filters_on)

        expect(effective_on.count(:name)).to eq(1)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: filter_params_permitted honours effective_filters_on
  # ---------------------------------------------------------------------------
  describe 'filter_params_permitted integration' do
    it 'permits :name when a name filter param is provided' do
      # Set up request params as if the user navigated to the filtered index page
      controller.params = ActionController::Parameters.new(
        filter: { name: 'test_name_value' }
      )

      # Before implementation: filters_on returns [] → name is not in permitted params
      # After  implementation: effective_filters_on includes :name → name IS permitted
      permitted = controller.send(:filter_params_permitted)

      expect(permitted).not_to be_nil
      expect(permitted[:name]).to eq('test_name_value')
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: filtered_primary_model respects name filtering end-to-end
  # ---------------------------------------------------------------------------
  describe 'filtered_primary_model with name filter' do
    before :all do
      @score_alpha = Classification::AccuracyScore.where(name: 'zz_nf_spec_alpha').first_or_create!(
        value: 9811,
        current_admin: @admin
      )
      @score_beta = Classification::AccuracyScore.where(name: 'zz_nf_spec_beta').first_or_create!(
        value: 9812,
        current_admin: @admin
      )
    end

    after :all do
      # Disable rather than destroy to avoid FK violation from accuracy_score_history
      Classification::AccuracyScore.where(name: %w[zz_nf_spec_alpha zz_nf_spec_beta]).update_all(disabled: true)
    end

    before :each do
      sign_in @admin
    end

    it 'returns only records matching the name when filter params include name' do
      # Directly set the processed filter params to simulate a permitted name filter.
      # This tests that filtered_primary_model correctly applies a WHERE name = ... clause.
      allow(controller).to receive(:filter_params).and_return(
        ActionController::Parameters.new('name' => 'zz_nf_spec_alpha').permit!
      )

      pm = controller.send(:filtered_primary_model)
      names = pm.pluck(:name)

      expect(names).to include('zz_nf_spec_alpha')
      expect(names).not_to include('zz_nf_spec_beta')
    end
  end
end
