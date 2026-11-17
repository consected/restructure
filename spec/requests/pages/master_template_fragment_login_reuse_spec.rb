# frozen_string_literal: true

# Verifies the issue #1400 payoff through the full request/view stack: advancing a user's
# login timestamp must not force the expensive master-template ERB fragment to render again.
# A paired cache-miss control proves the render counter detects the former behavior.

require 'rails_helper'

RSpec.describe 'Master template fragment reuse across user logins', type: :request do
  include CacheKeyMemoizationSupport
  include ModelSupport
  include MasterSupport

  before(:all) do
    @admin, = create_admin
    @user, = create_user
    create_master(@user)
  end

  before do
    @previous_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true
    reset_shared_helper_cache_key_memoization
    sign_in @user
  end

  after do
    reset_shared_helper_cache_key_memoization
    Rails.configuration.action_controller.perform_caching = @previous_caching
  end

  def bust_fragment_cache!
    server_cache_version = Rails.cache.read('server_cache_version')
    Rails.cache.clear
    Rails.cache.write('server_cache_version', server_cache_version) if server_cache_version
  end

  it 'renders once before login renewal and reuses that fragment afterwards' do
    helper = ApplicationController.helpers
    first_token = Digest::SHA256.hexdigest(helper.partial_cache_key(:loaded, force_user_or_admin: @user))
    bust_fragment_cache!

    render_counts = []
    subscriber = ActiveSupport::Notifications.subscribe('render_partial.action_view') do |*, payload|
      next unless payload[:identifier].end_with?('/masters/_search_results_template.html.erb')

      render_counts[-1] += 1
    end

    render_counts << 0
    get "/pages/#{first_token}/template"
    expect(response).to have_http_status(:ok)

    sign_out :user
    @user.update!(current_sign_in_at: 1.minute.from_now)
    sign_in @user
    second_token = Digest::SHA256.hexdigest(helper.partial_cache_key(:loaded, force_user_or_admin: @user))

    render_counts << 0
    get "/pages/#{second_token}/template"
    expect(response).to have_http_status(:ok)

    expect(second_token).to eq(first_token)
    expect(render_counts).to eq([1, 0])
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    bust_fragment_cache!
  end

  it 'renders twice when login renewal cannot reuse the previous fragment' do
    helper = ApplicationController.helpers
    token = Digest::SHA256.hexdigest(helper.partial_cache_key(:loaded, force_user_or_admin: @user))
    bust_fragment_cache!

    render_counts = []
    subscriber = ActiveSupport::Notifications.subscribe('render_partial.action_view') do |*, payload|
      next unless payload[:identifier].end_with?('/masters/_search_results_template.html.erb')

      render_counts[-1] += 1
    end

    render_counts << 0
    get "/pages/#{token}/template"
    expect(response).to have_http_status(:ok)

    sign_out :user
    @user.update!(current_sign_in_at: 1.minute.from_now)
    sign_in @user
    bust_fragment_cache! # Simulates the cache miss caused by the former login-scoped key.

    render_counts << 0
    get "/pages/#{token}/template"
    expect(response).to have_http_status(:ok)

    expect(render_counts).to eq([1, 1])
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
    bust_fragment_cache!
  end
end
