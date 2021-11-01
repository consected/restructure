# frozen_string_literal: true

module NfsStore
  module Filter
    #
    # Filtering of Stored and Archived Files for user browsing, viewing and uploading.
    # May also be used to identify files for automated background processing.
    class Filter < Admin::AdminBase
      self.table_name = 'nfs_store_filters'
      include AdminHandler
      include AppTyped
      include UserAndRoles

      belongs_to :user, optional: true

      validate :filter_is_valid

      after_save :clear_memos

      #
      # Get the defined filters for this user (from role and user overrides) for the specified activity log.
      # It should be noted that a container can be referenced, and viewed, from within multiple activity logs.
      # This actually allows one extra log type to provide a view onto the container differently from another
      # for the same user and roles.
      # We memoize the filter result for the user and role in the item, to avoid leaking memory long term,
      # while still allowing a significant speedup by preventing unnecessary DB calls.
      # @param item [ActivityLog | NfsStore::Manage::Container] container or the activity log the container is within
      # @param user [User|nil] user that has filter definitions through role membership or user override
      # @return [Array] of filters
      def self.filters_for(item, user: nil, alt_role: nil)
        key = "#{user&.id}-#{alt_role}-#{latest_filter_id}"
        ivs = item.instance_variable_get(:@filters_for) || {}
        return ivs[key] if ivs[key]

        user ||= item.current_user

        rn = if item.model_data_type == :activity_log
               item.extra_log_type_config.resource_name
             else
               item.resource_name
             end
        fs = filters_for_resource_named rn, user, alt_role: alt_role

        res = ivs[key] = fs.map { |f| f.filter_for item }
        item.instance_variable_set(:@filters_for, ivs)

        res
      end

      #
      # Get the "human" version of each of the filters returned by NfsStore::Filter::Filter.filters_for
      # This is a rough approximation of what a user would expect to see as file wildcards
      # @return [Array{String}]
      def self.human_filters_for(item, user:nil, alt_role:nil)
        filters_for(item).uniq.sort.map do |f|
          f.gsub('\.', '.').gsub('.*', '*').gsub('.+', '*').gsub(/^\*$/, '*.*').gsub('^/', '').gsub('^', '').gsub('$', '')
        end
      end

      #
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

      #
      # List of resource names for definitions of filters
      # @return [Array] list of full activity_log__type and container resource names
      def self.resource_names
        Resources::FilestoreFilter.resource_descriptions.keys
      end

      # Evaluate all filters for the current user (and associated roles) in the activity log
      # @return [Boolean]
      def self.evaluate(text, item, user: nil)
        user ||= item.current_user
        fs = filters_for item, user: user
        fs.each do |f|
          return true if evaluate_raw_filter f, text
        end

        false
      end

      #
      # Setup the filter, ensuring substitutions for the item data are applied
      # @param [String] item
      # @return [String]
      def filter_for(item)
        self.class.filter_for filter, item
      end

      #
      # Setup the filter, ensuring substitutions for the item data are applied
      # @param [NfsStore::Filter::Filter] filter
      # @param [String] item
      # @return [String]
      def self.filter_for(filter, item)
        Formatter::Substitution.substitute filter, data: item, tag_subs: nil
      end

      #
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
      def self.evaluate_container_files(item, user: nil, alt_role: nil, include_flags: nil)
        res = evaluate_container_files_as_scopes item, user: user, alt_role: alt_role
        return [] unless res

        include_flags&.each do |rt|
          res[rt] = res[rt].includes(:item_flags)
        end

        res[:stored_files] + res[:archived_files]
      end

      #
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

        filters = [filters] if filters.is_a? String

        container = if item.is_a? NfsStore::Manage::Container
                      item
                    else
                      NfsStore::Manage::Container.referenced_container item
                    end

        raise FsException::Action, 'No filestore container provided to evaluate filter' unless container

        sf_sql = "replace('/' || coalesce(path, '') || '/' || file_name, '//', '/') ~ ?"
        af_sql = "replace('/' || archive_file || '/' ||  coalesce(path, '') || '/' || file_name , '//', '/') ~ ?"

        conds = [''] + filters
        conds[0] = filters
                   .map { |_f| sf_sql }
                   .join(' OR ')
        sf = container.stored_files.where(conds)

        conds = [''] + filters
        conds[0] = filters
                   .map { |_f| af_sql }
                   .join(' OR ')

        af = container.archived_files.where(conds)

        { stored_files: sf, archived_files: af }
      end

      #
      # Generate filters as SQL for use in reports
      # Handles substitutions {{...}} by allowing any character sequence to match
      # @return [String] SQL that can be used directly in a report for filtering results
      def self.generate_filters_for(activity_log_resource_name, user: nil)
        unless activity_log_resource_name.start_with? 'activity_log__'
          raise FphsException, 'Generate Filters requires a resource name starting with activity_log'
        end

        res_class = ActivityLog.activity_log_class_from_type(activity_log_resource_name)
        extra_log_types = res_class.definition.option_configs_names || []

        sql_sets = []

        extra_log_types.each do |extra_log_type|
          resource_name = "#{activity_log_resource_name}__#{extra_log_type}"

          filters = filters_for_resource_named(resource_name, user)

          next if filters.empty?

          sf_sql = "(coalesce(nfs_store_stored_files.path, '') || '/' || nfs_store_stored_files.file_name) ~ ?"
          af_sql = "('/' || nfs_store_archived_files.archive_file || '/' || " \
                    "coalesce(nfs_store_archived_files.path, '') " \
                    "|| '/' || nfs_store_archived_files.file_name) ~ ?"
          conds_sf = filters
                     .map { |_f| sf_sql }
                     .join(' OR ')
          conds_af = filters
                     .map { |_f| af_sql }
                     .join(' OR ')

          # Replace substitution {{...}} markers with .+ to match any character sequence,
          # since we need to produce generic SQL
          filter_strings = filters.map { |f| f.filter.gsub(/\{\{.+\}\}/, '.+') }

          full_sql = "extra_log_type = ? AND (nfs_store_archived_files.id IS NOT NULL AND (#{conds_af}) " \
                     "OR nfs_store_stored_files.id IS NOT NULL AND (#{conds_sf}))"
          sql_sets << ActiveRecord::Base.send(:sanitize_sql_array,
                                              [full_sql] + [extra_log_type] + filter_strings + filter_strings)
        end

        res = sql_sets.join("\n  OR\n  ")
        "(\n#{res}\n)"
      end

      #
      # Evaluate the text against the current filter, ensuring substitutions with item data are made
      # before passing the filter text to the underlying evaluation
      # @return [nil, MatchData] if the match is made, a MatchData object is returned, otherwise nil
      def evaluate(text, item)
        self.class.evaluate_raw_filter filter_for(item), text
      end

      #
      # Handle the base matching of filter text against a text string
      # @param [String] filter - prepared filter (with any necessary substitutions) to use
      # @param [String] text - text to test against the filter
      # @return [<Type>] <description>
      def self.evaluate_raw_filter(filter, text)
        re = Regexp.new filter
        re.match(text)
      end

      def clear_memos
        self.class.reset_latest_filter_id
      end

      #
      # Get the latest filter record id, to automatically handle memoization,
      # storing it in a class instance variable
      def self.latest_filter_id
        @latest_filter_id ||= reorder('').order(Arel.sql('coalesce(updated_at, created_at) desc, id desc')).first&.id
      end

      #
      # Reset the class instance variable storing the latest filter id
      def self.reset_latest_filter_id
        @latest_filter_id = nil
      end

      private

      #
      # Check filter is valid definition.
      # Adds to #errors if the filter is an invalid regex
      # @return [true | nil]
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
