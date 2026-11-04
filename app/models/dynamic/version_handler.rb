# frozen_string_literal: true

module Dynamic
  module VersionHandler
    extend ActiveSupport::Concern

    # Maximum number of historical version rows fetched/displayed for the admin
    # versions panel at once. Definitions with very large histories otherwise
    # cause the panel to time out (see issue #1343). This does not limit
    # `all_versions`, which is used for real definition-version lookups.
    MAX_DISPLAYED_VERSIONS = 10
    VERSION_MEMO_INITIALIZATION_LOCK = Mutex.new

    included do
      attr_accessor :def_version # definition version = corresponging id of record in definition history table
      attr_accessor :current_definition # latest defined configuration

      after_save :reset_all_versions
      after_touch :reset_all_versions
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
        all_versions_mutex.synchronize { @all_versions_memo ||= {} }
      end

      def all_versions_memo=(av)
        all_versions_mutex.synchronize do
          @all_versions_memo = av
          @all_versions_generation = (@all_versions_generation || 0) + 1
        end
      end

      def read_all_versions_memo(key)
        all_versions_mutex.synchronize do
          [(@all_versions_memo ||= {})[key], (@all_versions_generation ||= 0)]
        end
      end

      def write_all_versions_memo(key, versions, generation)
        all_versions_mutex.synchronize do
          return unless generation == (@all_versions_generation ||= 0)

          (@all_versions_memo ||= {})[key] = versions
        end
      end

      def clear_all_versions_memo
        all_versions_mutex.synchronize do
          (@all_versions_memo ||= {}).clear
          @all_versions_generation = (@all_versions_generation || 0) + 1
        end
      end

      def delete_all_versions_memo(key)
        all_versions_mutex.synchronize do
          deleted = (@all_versions_memo ||= {}).delete(key)
          @all_versions_generation = (@all_versions_generation || 0) + 1
          deleted
        end
      end

      def all_versions_mutex
        @all_versions_mutex ||= VERSION_MEMO_INITIALIZATION_LOCK.synchronize do
          @all_versions_mutex ||= Mutex.new
        end
      end
      private :all_versions_mutex
    end

    def history_table_name
      @history_table_name ||= Admin::MigrationGenerator.history_table_name_for(table_name)
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
      key = versions_memo_key
      versions, generation = self.class.read_all_versions_memo(key)
      return versions if versions

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

      self.class.write_all_versions_memo(key, vs, generation)
      vs
    end

    # @param limit [Integer, nil] restrict to at most this many of the most recent
    #   version rows. Used by the admin versions panel display; pass nil (the
    #   default) to fetch the full history, as required by `all_versions`.
    def all_versions_query(limit: nil)
      limit_clause = limit ? "limit #{limit.to_i}" : ''
      qres = Admin::MigrationGenerator.connection.execute <<~END_SQL
        select * from #{self.class.history_table_name}
        where #{history_id_attr} = #{id}
        order by
          EXTRACT(EPOCH FROM coalesce(updated_at, created_at)) desc nulls last,
          id desc
        #{limit_clause}
      END_SQL
      qres.map(&:to_h)
    end

    # Latest history-row id used to label the live definition's template config.
    def current_def_version
      return if id.blank?
      return @current_def_version if instance_variable_defined?(:@current_def_version)

      @current_def_version = latest_history_row_id
    end

    def refresh_current_def_version!
      return if id.blank?

      @current_def_version = latest_history_row_id
      remove_instance_variable(:@current_template_library_tokens) if
        instance_variable_defined?(:@current_template_library_tokens)
      remove_instance_variable(:@template_version_token) if instance_variable_defined?(:@template_version_token)
      @template_version_token = calculate_template_version_token
      @current_def_version
    end

    # Label the current or historical template config without changing def_version semantics.
    def template_version_token
      return def_version.to_i if def_version
      return @template_version_token if instance_variable_defined?(:@template_version_token)

      @template_version_token = calculate_template_version_token
    end

    # Total number of historical version rows for this record, independent of
    # any display limit applied by all_versions_query.
    # @return [Integer]
    def all_versions_count
      qres = Admin::MigrationGenerator.connection.execute <<~END_SQL
        select count(*) as count from #{self.class.history_table_name}
        where #{history_id_attr} = #{id}
      END_SQL
      qres.first['count'].to_i
    end

    def current_template_library_tokens
      return [] unless uses_current_definition_version?

      @current_template_library_tokens ||= Dynamic::TemplateVersionTokens.live_config_library_tokens([self])
    end

    private

    def history_id_attr
      @history_id_attr ||= self.class.history_id_attr
    end

    def reset_all_versions
      self.class.delete_all_versions_memo(versions_memo_key)
      remove_instance_variable(:@current_def_version) if instance_variable_defined?(:@current_def_version)
      remove_instance_variable(:@template_version_token) if instance_variable_defined?(:@template_version_token)
      remove_instance_variable(:@current_template_library_tokens) if
        instance_variable_defined?(:@current_template_library_tokens)
    end

    def calculate_template_version_token
      history_id = current_def_version || updated_at_version_token
      return history_id unless uses_current_definition_version?

      library_tokens = current_template_library_tokens
      return history_id if library_tokens.empty?

      digest = Digest::SHA256.hexdigest([history_id, library_tokens].to_json)
      1_000_000_000_000 + digest.first(12).to_i(16)
    end

    def latest_history_row_id
      all_versions_query(limit: 1).first&.fetch('id')&.to_i
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::UndefinedTable)

      nil
    rescue PG::UndefinedTable
      nil
    end

    def updated_at_version_token
      return 0 unless updated_at

      (updated_at.to_r * 1_000_000).to_i
    end

    def versions_memo_key
      "#{self.class.name}-#{id}"
    end
  end
end
