# frozen_string_literal: true

module Dynamic
  #
  # A single token that rotates whenever any dynamic definition (dynamic model, activity log or
  # external identifier) is saved, or a YAML config library used by one of them changes.
  # Caches derived from the set of definitions include it in their keys.
  module DefinitionCacheVersion
    def self.token
      Rails.cache.fetch(cache_key) { SecureRandom.hex }
    end

    def self.rotate!
      Rails.cache.write(cache_key, SecureRandom.hex)
    end

    def self.cache_key
      "dynamic-definitions-cache-version-#{Application.version}"
    end
    private_class_method :cache_key
  end
end
