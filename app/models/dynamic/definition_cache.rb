# frozen_string_literal: true

module Dynamic
  # Cache only values derived from dynamic definitions. Tokenized keys leave other Rails.cache entries untouched.
  module DefinitionCache
    MaxTrackedCacheKeys = 500
    CacheKeysListLock = Mutex.new
    RefreshThreadKey = :dynamic_definition_cache_refreshing

    class << self
      def key(*key_components)
        (key_components + [DefinitionCacheVersion.token]).join('-')
      end

      def fetch(*key_components, refresh: false, on_miss: nil, current: nil)
        cache_key = key(*key_components)
        delete_cache_key(cache_key) if refresh
        cached = Rails.cache.read(cache_key)
        return cached unless cached.nil?

        refresh_dynamic_definitions(on_miss)
        value = yield
        current ||= -> { definitions_current? }
        write_cache_key(cache_key, value) if current.call
        value
      end

      def read(*key_components)
        Rails.cache.read(key(*key_components))
      end

      def write(*key_components, value:)
        write_cache_key(key(*key_components), value)
      end

      def delete(*key_components)
        delete_cache_key(key(*key_components))
      end

      def delete_all
        cache_keys = CacheKeysListLock.synchronize do
          keys = @cache_keys_list&.keys || []
          @cache_keys_list = {}
          keys
        end
        cache_keys.each { |cache_key| Rails.cache.delete(cache_key) }
      end

      def with_refresh_suppressed
        previous = Thread.current[RefreshThreadKey]
        Thread.current[RefreshThreadKey] = true
        yield
      ensure
        Thread.current[RefreshThreadKey] = previous
      end

      def definitions_current?
        [ActivityLog, DynamicModel, ExternalIdentifier].all? do |definition_class|
          definition_class.definition_refresh_status == :current
        end
      end

      private

      def refresh_dynamic_definitions(on_miss)
        return if Thread.current[RefreshThreadKey]

        Thread.current[RefreshThreadKey] = true
        begin
          (on_miss || -> { Application.refresh_dynamic_defs }).call
        ensure
          Thread.current[RefreshThreadKey] = false
        end
      end

      def write_cache_key(cache_key, value)
        written = Rails.cache.write(cache_key, value)
        track_cache_key(cache_key) if written
        written
      end

      def delete_cache_key(cache_key)
        CacheKeysListLock.synchronize { @cache_keys_list&.delete(cache_key) }
        Rails.cache.delete(cache_key)
      end

      def track_cache_key(cache_key)
        pruned_key = CacheKeysListLock.synchronize do
          @cache_keys_list ||= {}
          unless @cache_keys_list.key?(cache_key)
            pruned = @cache_keys_list.shift.first if @cache_keys_list.length >= MaxTrackedCacheKeys
            @cache_keys_list[cache_key] = true
            pruned
          end
        end
        Rails.cache.delete(pruned_key) if pruned_key
      end
    end
  end
end
