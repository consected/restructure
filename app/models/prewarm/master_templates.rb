# frozen_string_literal: true

module Prewarm
  # Offline render harness (issue #1362 Stage 2): drives the cached master-template
  # render a real login would, for a given (user, app_type) combination, via
  # ActionController::Renderer rather than a real HTTP request.
  class MasterTemplates
    def self.render_for(user, app_type)
      new.render_for(user, app_type)
    end

    # @param user [User] a real, persisted user - never mutated or saved
    # @param app_type [Admin::AppType] the app type to render for
    # @return [String, nil] the rendered partial, or nil if the render failed
    def render_for(user, app_type)
      prewarm_user = User.find(user.id)
      # In-memory only - deliberately never saved, so a warm pass can never change which
      # app type a real user is actually assigned to.
      prewarm_user.app_type_id = app_type.id

      PrewarmController.prewarm_user = prewarm_user
      fragment_cache_key = master_fragment_cache_key(prewarm_user)
      rendered = PrewarmController.renderer.render(partial: 'masters/cache_search_results_template')
      return rendered if fragment_cache_key.nil? || Rails.cache.exist?(fragment_cache_key)

      Rails.logger.warn(
        "Prewarm::MasterTemplates: fragment was not cached for user=#{user.id} app_type=#{app_type.id}"
      )
      nil
    rescue StandardError => e
      Rails.logger.warn(
        "Prewarm::MasterTemplates: render failed for user=#{user.id} " \
        "app_type=#{app_type.id}: #{e.class}: #{e.message}"
      )
      nil
    ensure
      PrewarmController.prewarm_user = nil
    end

    private

    def master_fragment_cache_key(user)
      return unless Rails.configuration.action_controller.perform_caching

      ApplicationController.helpers.partial_cache_key(
        :master__search_results_template,
        force_user_or_admin: user
      )
    end
  end
end
