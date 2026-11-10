# frozen_string_literal: true

# Verifies the master-template fragment is persisted only after its nested Handlebars
# multi-bundle assembly succeeds, so a transient compile/read failure remains retryable.

require 'rails_helper'

RSpec.describe 'masters/_cache_search_results_template', type: :view do
  let(:cache_key) { "master-template-fragment-spec-#{SecureRandom.hex(6)}" }

  before do
    @perform_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true
    allow(view).to receive(:partial_cache_key).and_return(cache_key)
    allow(view).to receive(:render).and_call_original
    Rails.cache.delete(cache_key)
  end

  after do
    Rails.cache.delete(cache_key)
    Rails.configuration.action_controller.perform_caching = @perform_caching
  end

  it 'serves without caching the rendered fragment when bundle assembly is incomplete' do
    allow(view).to receive(:render).with(partial: 'masters/search_results_template') do
      view.instance_variable_set(:@handlebars_template_bundle_failed, true)
      '<script src="/missing-bundle.js"></script>'
    end

    render partial: 'masters/cache_search_results_template'

    expect(rendered).to include('/missing-bundle.js')
    expect(Rails.cache.exist?(cache_key)).to be false
  end

  it 'caches the rendered fragment after successful bundle assembly' do
    allow(view).to receive(:render).with(partial: 'masters/search_results_template') do
      view.instance_variable_set(:@handlebars_template_bundle_failed, false)
      '<script src="/complete-bundle.js"></script>'
    end

    render partial: 'masters/cache_search_results_template'

    expect(Rails.cache.read(cache_key)).to include('/complete-bundle.js')
  end
end
