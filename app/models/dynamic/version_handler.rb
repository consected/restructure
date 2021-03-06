# frozen_string_literal: true

module Dynamic
  module VersionHandler
    extend ActiveSupport::Concern

    included do
      attr_accessor :def_version # definition version = corresponging id of record in definition history table
    end

    class_methods do
      # The history table table name matching this definition
      def history_table_name
        Admin::MigrationGenerator.history_table_name_for table_name
      end

      # The field that relates the history table for this definition back to the
      # current record in the primary table
      def history_id_attr
        Admin::MigrationGenerator.history_table_id_attr_for table_name
      end
    end
    #
    # Get the definition record version from history, current
    # at the time of the current_at argument
    # If the current_at timestamp is nil then the implementation has probably not be persisted
    # and the current version of the definition is returned (self)
    # @param [Time | nil] current_at
    # @return [ActiveRecord::Base] defintion record
    def versioned(current_at)
      return self unless current_at

      history_id_attr = self.class.history_id_attr

      # Add a second, to avoid rounding issues between Rails and DB
      current_at += 1.second

      # Get the matching version as the first record and the
      # lastest version as the second record
      # allowing us to recognize if the matching version is in fact the latest
      all_res = Admin::MigrationGenerator.connection.execute <<~END_SQL
        (select * from #{self.class.history_table_name} 
        where #{history_id_attr} = #{id}
        and coalesce(updated_at, created_at) < '#{current_at.iso8601(4)}' 
        order by updated_at desc NULLS LAST
        limit 1)
        UNION
        (select * from #{self.class.history_table_name} 
        where #{history_id_attr} = #{id}
        order by id desc
        limit 1)
      END_SQL

      # We expect two results. If not, just return and let the caller decide what to do
      return unless all_res.count == 2

      # If the first and second records match, the matching version is the current version.
      # Just return and let the caller use the current definition.
      return if all_res[0]['id'] == all_res[1]['id']

      res = all_res.first
      res.delete 'admin_id'
      res.delete(history_id_attr)
      res['def_version'] = res['id']
      res['id'] = id

      # Instantiate (but don't save) this version as usable ActiveRecord object
      self.class.new res.to_h
    end

    #
    # Get all definition versions
    # @return [Array {UserBase}] - list of definition records
    def all_versions(active: nil)
      versions = []
      history_id_attr = self.class.history_id_attr

      all_results = Admin::MigrationGenerator.connection.execute <<~END_SQL
        select * from #{self.class.history_table_name} 
        where #{history_id_attr} = #{id}
        #{active ? 'AND (disabled IS NULL or disabled = false)' : ''}
        order by updated_at desc NULLS LAST
      END_SQL

      all_results.each do |res|
        res.delete 'admin_id'
        res.delete(history_id_attr)
        res['def_version'] = res['id']
        res['id'] = id

        # Instantiate (but don't save) this version as usable ActiveRecord object
        versions << self.class.new(res.to_h)
      end

      versions
    end
  end
end
