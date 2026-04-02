# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for NFS store definitions.
    # Migrated from ActivityLogOptions#clean_nfs_store_def (issue #986).
    #
    # Validates nfs_store top-level and can sub-keys, and delegates
    # pipeline cleaning to NfsStore::Config::ExtraOptions.clean_def.
    #
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class NfsStoreConfig < BaseConfiguration
      configure_direct :nfs_store, type: :hash

      def self.store_processed_value?
        true
      end

      validate :validate_nfs_store_keys

      # Delegate pipeline cleaning to NfsStore::Config::ExtraOptions.
      # @param raw [Hash, nil] the raw nfs_store config
      # @param _parent [ExtraOptions] the parent ExtraOptions instance (unused)
      # @return [Hash, nil] the raw config after pipeline cleaning
      def self.prepare_config(raw, _parent)
        return nil unless raw

        NfsStore::Config::ExtraOptions.clean_def(raw)
        raw
      end

      def setup_named_configurations
        self.nfs_store = hash_configuration
      end

      private

      def validate_nfs_store_keys
        raw = hash_configuration
        return if raw.blank?

        unless valid_nfs_store_top_keys?(raw)
          errors.add(:nfs_store,
                     "nfs_store contains invalid keys #{raw.keys} - " \
                     "expected only #{ActivityLogOptions::ValidNfsStoreKeys}")
        end

        can_perform = raw[:can]
        return if can_perform.nil?

        return if valid_nfs_store_can_keys?(can_perform)

        errors.add(:nfs_store,
                   "nfs_store.can contains invalid keys #{can_perform.keys} - " \
                   "expected only #{ActivityLogOptions::ValidNfsStoreCanPerformKeys}")
      end

      def valid_nfs_store_top_keys?(config)
        config.keys.empty? || (config.keys - ActivityLogOptions::ValidNfsStoreKeys).empty?
      end

      def valid_nfs_store_can_keys?(config)
        config.keys.empty? || (config.keys - ActivityLogOptions::ValidNfsStoreCanPerformKeys).empty?
      end
    end
  end
end
