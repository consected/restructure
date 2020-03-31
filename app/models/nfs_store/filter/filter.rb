# frozen_string_literal: true

module NfsStore
  module Filter
    class Filter < Admin::AdminBase
      self.table_name = 'nfs_store_filters'
      include AdminHandler
      include AppTyped
      include UserAndRoles

      belongs_to :user

      validate :filter_is_valid

      # Get the defined filters for this user (from role and user overrides) for the specified activity log.
      # It should be noted that a container can be referenced, and viewed, from within multiple activity logs.
      # This actually allows one extra log type to provide a view onto the container differently from another
      # for the same user and roles.
      # @param item [ActivityLog | NfsStore::Manage::Container] container or the activity log the container is within
      # @param user [User|nil] user that has filter definitions through role membership or user override
      # @return [Array] of filters
      # [ActiveRecord::Relation] resultset of filters
      def self.filters_for(item, user: nil, alt_role: nil)
        user ||= item.current_user

        rn = if item.model_data_type == :activity_log
               item.extra_log_type_config.resource_name
             else
               item.resource_name
             end
        fs = filters_for_resource_named rn, user, alt_role: alt_role

        fs.map { |f| f.filter_for item }
      end

      # Simply lookup the filters based on the resource name for the scoped user roles.
      # Basic function used by those that have activity log and other item instances, or just
      # naming in view templates
      # @param name [String] standard resource name string
      # @param user [User] allow roles and user settings to be applied to filters
      # @param alt_role [String|Array] use alternative role name (or names) instead of the user's defined set
      # @return [ActiveRecord::Relation] resultset of filters
      def self.filters_for_resource_named(name, user, alt_role: nil)
        primary_conditions = {
          resource_name: name
        }
        where(primary_conditions).scope_user_and_role(user, nil, alt_role)
      end

      # List of resource names for definitions of filters
      # @return [Array] list of full activity_log__type and container resource names
      def self.resource_names
        # Get only the names that have an extra log type config with a reference to a container
        names = ActivityLog.extra_log_type_resource_names { |e| e&.references && e.references[:nfs_store__manage__container] }
        (names + [NfsStore::Manage::Container.resource_name]).uniq
      end

      # Evaluate all filters for the current user (and associated roles) in the activity log
      # @return [Boolean]
      def self.evaluate(text, item, user: nil)
        user ||= item.current_user
        fs = filters_for item, user: user
        fs.each do |f|
          return true if evaluate_with f, text
        end

        false
      end

      def filter_for(item)
        # Substitute filters
        self.class.filter_for filter, item
      end

      def self.filter_for(filter, item)
        Admin::MessageTemplate.substitute filter, data: item, tag_subs: nil
      end

      # Evaluate a query directly in the database to produce a filtered set of records
      # Returns an array of results
      # NOTE: stored and archived files to be filtered against appear with an initial forward-slash (/)  character
      # Filter definitions that use the regex ^ (start of line) character must take this into account.
      # For example, a file in the root directory of the container named "00000.dcm"
      # will match "^/0+\.dcm" or "/0+\.dcm"
      # but will not match "^0+\.dcm" since it does not expect to see the initial slash
      # To match any file, use the filter ".*"
      # @param item [ActivityLog|NfsStore::ManageContainer] container or activity log referencing the container
      # @param user [User|nil]
      # @return [Array] all matched records of StoredFile and ArchivedFile types
      def self.evaluate_container_files(item, user: nil, alt_role: nil)
        res = evaluate_container_files_as_scopes item, user: user, alt_role: alt_role
        return [] unless res

        res[:stored_files] + res[:archived_files]
      end

      # Evaluate a query directly in the database to produce a filtered set of records
      # Returns two scopes as a hash {stored_files: ActiveRecord::Relation, archived_files: ActiveRecord::Relation}
      # @param [ActivityLog|NfsStore::ManageContainer] item is a container or activity log referencing the container
      # @param [User|nil] user
      # @param [Array] filters optionally allows a list of filter strings to be supplied rather
      #   than getting them from the stored definition
      # @return [Hash{ActiveRecord::Relation}] resultset of all matched records
      def self.evaluate_container_files_as_scopes(item, user: nil, alt_role: nil, filters: nil)
        user ||= item.current_user
        filters ||= filters_for(item, user: user, alt_role: alt_role)

        # If no filters are defined, exit. At least one is required to return a sensible result.
        return if filters.empty?

        if item.is_a? NfsStore::Manage::Container
          container = item
        elsif item.model_data_type == :activity_log
          container = ModelReference.find_referenced_items(item, record_type: 'NfsStore::Manage::Container').first
        end

        raise FsException::Action, 'No filestore container provided to evaluate filter' unless container

        conds = [''] + filters
        conds[0] = filters.map { |_f| "replace('/' || coalesce(path, '') || '/' || file_name, '//', '/') ~ ?" }.join(' OR ')
        sf = container.stored_files.where(conds)

        conds = [''] + filters
        conds[0] = filters.map { |_f| "replace('/' || archive_file || '/' ||  coalesce(path, '') || '/' || file_name , '//', '/') ~ ?" }.join(' OR ')

        af = container.archived_files.where(conds)

        { stored_files: sf, archived_files: af }
      end

      # Generate filters as SQL for use in reports
      # Handles substitutions {{...}} by allowing any character sequence to match
      # @return [String] SQL that can be used directly in a report for filtering results
      def self.generate_filters_for(activity_log_resource_name, user: nil)
        if activity_log_resource_name.start_with? 'activity_log__'
          res_class = ActivityLog.activity_log_class_from_type(activity_log_resource_name)
          extra_log_types = res_class.definition.extra_log_type_configs.map(&:name)
        else
          raise FphsException, 'Generate Filters requires a resource name starting with activity_log'
        end

        sql_sets = []

        extra_log_types.each do |extra_log_type|
          resource_name = "#{activity_log_resource_name}__#{extra_log_type}"

          filters = filters_for_resource_named(resource_name, user)

          next if filters.empty?

          conds_sf = filters.map { |_f| "(coalesce(nfs_store_stored_files.path, '') || '/' || nfs_store_stored_files.file_name) ~ ?" }.join(' OR ')
          conds_af = filters.map { |_f| "('/' || nfs_store_archived_files.archive_file || '/' ||  coalesce(nfs_store_archived_files.path, '') || '/' || nfs_store_archived_files.file_name) ~ ?" }.join(' OR ')

          # Replace substitution {{...}} markers with .+ to match any character sequence, since we need to produce generic SQL
          filter_strings = filters.map { |f| f.filter.gsub(/\{\{.+\}\}/, '.+') }

          sql_sets << ActiveRecord::Base.send(:sanitize_sql_array, [
            "extra_log_type = ? AND (nfs_store_archived_files.id IS NOT NULL AND (#{conds_af}) OR nfs_store_stored_files.id IS NOT NULL AND (#{conds_sf}))"
          ] + [extra_log_type] + filter_strings + filter_strings)
        end

        res = sql_sets.join("\n  OR\n  ")
        "(\n#{res}\n)"
      end

      # Evaluate the text against the current filter
      # @return [nil, MatchData] if the match is made, a MatchData object is returned, otherwise nil
      def evaluate(text, item)
        self.class.evaluate_with filter_for(item), text
      end

      def self.evaluate_with(filter, text)
        re = Regexp.new filter
        re.match(text)
      end

      private

      def filter_is_valid
        begin
          Regexp.new(filter)
        rescue RegexpError
          failed_regex = true
        end

        if filter.blank? || failed_regex
          errors.add :filter, 'is not a valid regular expression'
          return
        end

        true
      end
    end
  end
end
