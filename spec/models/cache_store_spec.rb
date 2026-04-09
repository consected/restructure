# frozen_string_literal: true

# Tests for Dalli memcached cache store configuration (issues #886, #1038).
#
# These specs verify that when the TEST_MEM_CACHE_STORE environment variable
# is set, the cache store switches from :memory_store to :mem_cache_store
# using the :meta protocol. This ensures the Dalli binary protocol deprecation
# warning is resolved and the app is compatible with Dalli 5.0.
#
# Issue #1038: Verify that the Dalli Marshal security warning is suppressed by
# explicitly configuring `serializer: Marshal` in the cache store options.
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

  describe 'Dalli Marshal security warning suppression (issue #1038)' do
    it 'configures mem_cache_store with explicit serializer: Marshal in all environments' do
      %w[production development].each do |env_name|
        env_file = Rails.root.join('config', 'environments', "#{env_name}.rb")
        content = File.read(env_file)

        # Verify that every :mem_cache_store config includes serializer: Marshal
        # to suppress the Dalli SECURITY WARNING about Marshal serialization
        content.scan(/config\.cache_store\s*=.*:mem_cache_store.*?\n(?:.*\n)*?.*?\}/).each do |match|
          expect(match).to include('serializer'),
                           "Expected #{env_name}.rb mem_cache_store config to include serializer option"
        end
      end
    end

    it 'configures test mem_cache_store with explicit serializer: Marshal' do
      env_file = Rails.root.join('config', 'environments', 'test.rb')
      content = File.read(env_file)

      mem_cache_section = content[/\[:mem_cache_store.*?\]/m]
      expect(mem_cache_section).to be_present
      expect(mem_cache_section).to include('serializer'),
                                   'Expected test.rb mem_cache_store config to include serializer option'
    end

    it 'does not emit a Dalli Marshal security warning when creating a new client' do
      log_output = StringIO.new
      original_logger = Dalli.logger
      Dalli.logger = Logger.new(log_output)

      # Reset the class variable so the warning would fire if not suppressed
      # rubocop:disable Style/ClassVars
      Dalli::Protocol::ValueSerializer.class_variable_set(:@@marshal_warning_logged, false)

      begin
        # Create a client with explicit serializer: Marshal (as our config does)
        Dalli::Client.new(nil, protocol: :meta, serializer: Marshal)
      ensure
        Dalli.logger = original_logger
        # Reset again so other tests aren't affected
        Dalli::Protocol::ValueSerializer.class_variable_set(:@@marshal_warning_logged, false)
        # rubocop:enable Style/ClassVars
      end

      expect(log_output.string).not_to include('SECURITY WARNING')
    end
  end
end
