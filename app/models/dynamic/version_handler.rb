# frozen_string_literal: true

module Dynamic
  module VersionHandler
    extend ActiveSupport::Concern

    included do
      attr_accessor :def_version # definition version = corresponging id of record in definition history table
      attr_accessor :current_definition # latest defined configuration

      after_save :reset_all_versions
    end

    class_methods do
      # The history table table name matching this definition
      def history_table_name
        @history_table_name ||= Admin::MigrationGenerator.history_table_name_for(table_name)
      end

      # The field that relates the history table for this definition back to the
      # current record in the primary table
      def history_id_attr
        @history_id_attr ||= Admin::MigrationGenerator.history_table_id_attr_for(table_name)
      end

      def all_versions_memo
        @all_versions_memo ||= {}
      end

      def all_versions_memo=(av)
        @all_versions_memo = av
      end
    end

    #
    # Get the definition record version from history, current
    # at the time of the current_at argument
    # If the current_at timestamp is nil then the implementation has probably not be persisted
    # and the current version of the definition is returned (self)
    # If the latest version returned is the current version, return nil and
    # let the caller decide what to do.
    # Versioning can be disabled completely with Settings::DisableVDef (typically for development mode)
    # @param [Time | nil] current_at
    # @return [ActiveRecord::Base] defintion record
    def versioned(current_at)
      return self if Settings::DisableVDef || !current_at

      # Add a second, to avoid rounding issues between Rails and DB
      current_at += 1.second

      matched_version = nil
      avs = all_versions
      # Iterate through all available versions.
      # Since the versions are getting older as we progress,
      # as soon as the definition version
      # was updated or created less recently than the item current_at
      # timestamp, then we know it was the one the item
      # was created from. Break the loop.
      avs.each do |version|
        matched_version = version
        break if (version.updated_at || version.created_at) < current_at
      end

      # If no version was matched it probably means the item was created
      # from the current version. Return nil.
      # If the version matched is the first in the list then just
      # return nil and let the caller decide.
      return if matched_version.nil? || matched_version.def_version == avs.first.def_version

      # Return the matched version
      matched_version
    end

    #
    # Get all definition versions as instances,
    # ordered in reverse chronological order,
    # based on the updated date (or created if updated is null).
    # The result is memoized in a class variable, so a full set of
    # definitions are kept initialized (including the extra option config YAMLs)
    # saving reloading the definition versions.
    # @return [Array {ActiveRecord::Base}] - list of dynamic definition records
    def all_versions
      return self.class.all_versions_memo[versions_memo_key] if self.class.all_versions_memo.key? versions_memo_key

      vs = []

      all_res = all_versions_query

      all_res.each do |res|
        res.delete 'admin_id'
        res.delete(history_id_attr)
        res['def_version'] = res['id']
        res['id'] = id
        res['current_definition'] = self

        # Instantiate (but don't save) this version as usable ActiveRecord object
        vs << self.class.new(res.to_h)
      end

      self.class.all_versions_memo[versions_memo_key] = vs
    end

    def all_versions_query
      qres = Admin::MigrationGenerator.connection.execute <<~END_SQL
        select * from #{self.class.history_table_name}
        where #{history_id_attr} = #{id}
        order by
          EXTRACT(EPOCH FROM coalesce(updated_at, created_at)) desc nulls last,
          id desc
      END_SQL
      qres.map(&:to_h)
    end

    private

    def history_id_attr
      @history_id_attr ||= self.class.history_id_attr
    end

    def reset_all_versions
      self.class.all_versions_memo.delete versions_memo_key
    end

    def versions_memo_key
      "#{self.class.name}-#{id}"
    end
  end
end
