# frozen_string_literal: true

module Dynamic
  #
  # A single token that rotates whenever any dynamic definition (dynamic model, activity log or
  # external identifier) is saved, or a YAML config library used by one of them changes.
  # Caches derived from the set of definitions include it in their keys.
  module DefinitionCacheVersion
    PUBLISH_ATTEMPTS = 3

    # While the token can't be published to the shared cache, every call returns a unique value so that
    # no worker can treat its definitions as verified, and caches keyed on it can't be hit with stale data.
    def self.token
      if @publish_pending
        publish_token(SecureRandom.hex) || return_unpublished_token
      else
        existing = Rails.cache.read(cache_key)
        existing.presence || publish_token(SecureRandom.hex) || return_unpublished_token
      end
    end

    # Rotate the shared token, checking that it really reached the shared cache.
    # If it can't be published (for example the cache server is unreachable) the failure is logged and reported,
    # and this process falls back to unique tokens until a later call publishes successfully.
    # @return [Boolean] whether the new token was published
    def self.rotate!
      return true if publish_token(SecureRandom.hex)

      @publish_pending = true
      message = 'Dynamic definition cache version token could not be published to the shared cache. ' \
                'Other workers may not notice definition changes until it is.'
      Rails.logger.error message
      Rails.error.report(RuntimeError.new(message), handled: true, severity: :error)
      false
    end

    def self.publish_pending?
      @publish_pending ? true : false
    end

    def self.publish_token(value)
      PUBLISH_ATTEMPTS.times do
        Rails.cache.write(cache_key, value)
        if Rails.cache.read(cache_key) == value
          @publish_pending = false
          return value
        end
      end
      nil
    end
    private_class_method :publish_token

    def self.return_unpublished_token
      "unpublished-#{SecureRandom.hex}"
    end
    private_class_method :return_unpublished_token

    def self.cache_key
      "dynamic-definitions-cache-version-#{Application.version}"
    end
    private_class_method :cache_key
  end
end
