# frozen_string_literal: true

# Tests for Dalli memcached cache store configuration (issue #886).
#
# These specs verify that when the TEST_MEM_CACHE_STORE environment variable
# is set, the cache store switches from :memory_store to :mem_cache_store
# using the :meta protocol. This ensures the Dalli binary protocol deprecation
# warning is resolved and the app is compatible with Dalli 5.0.
#
# Run with memcached:
#   TEST_MEM_CACHE_STORE=true bundle exec rspec spec/models/cache_store_spec.rb
#
# Run without memcached (default, memcached tests are skipped):
#   bundle exec rspec spec/models/cache_store_spec.rb

require 'rails_helper'

RSpec.describe 'Cache store configuration', type: :model do
  def unique_cache_key
    "dalli_test_#{SecureRandom.hex(8)}"
  end

  context 'when TEST_MEM_CACHE_STORE is set', memcached: true do
    before do
      skip 'Set TEST_MEM_CACHE_STORE=true to run Dalli/memcached tests' unless ENV['TEST_MEM_CACHE_STORE'] == 'true'
    end

    it 'uses MemCacheStore as the cache store' do
      expect(Rails.cache).to be_a(ActiveSupport::Cache::MemCacheStore)
    end

    it 'can write and read a cache entry' do
      key = unique_cache_key
      Rails.cache.write(key, 'hello from dalli')
      expect(Rails.cache.read(key)).to eq('hello from dalli')
      Rails.cache.delete(key)
    end

    it 'can delete a cache entry' do
      key = unique_cache_key
      Rails.cache.write(key, 'to be deleted')
      Rails.cache.delete(key)
      expect(Rails.cache.read(key)).to be_nil
    end

    it 'does not emit a Dalli binary protocol deprecation warning' do
      key = unique_cache_key
      stderr_output = StringIO.new
      original_stderr = $stderr
      $stderr = stderr_output

      begin
        Rails.cache.write(key, 'deprecation check')
        Rails.cache.read(key)
        Rails.cache.delete(key)
      ensure
        $stderr = original_stderr
      end

      expect(stderr_output.string).not_to include('[DEPRECATION]')
      expect(stderr_output.string).not_to include('binary protocol is deprecated')
    end
  end

  context 'when TEST_MEM_CACHE_STORE is not set' do
    it 'uses MemoryStore as the default test cache store' do
      if ENV['TEST_MEM_CACHE_STORE'] == 'true'
        skip 'Verifies default behavior; not applicable when TEST_MEM_CACHE_STORE is set'
      end

      expect(Rails.cache).to be_a(ActiveSupport::Cache::MemoryStore)
    end
  end
end
