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
      # @return [ActiveRecord::Relation] resultset of filters
      def self.filters_for item, user: nil

        user ||= item.current_user

        if item.model_data_type == :activity_log
          rn = item.extra_log_type_config.resource_name
        else
          rn = item.resource_name
        end
        primary_conditions = {
          resource_name: rn
        }
        self.where(primary_conditions).scope_user_and_role(user)

      end

      # List of resource names for definitions of filters
      # @return [Array] list of full activity_log__type and container resource names
      def self.resource_names
        return ActivityLog.extra_log_type_resource_names + [NfsStore::Manage::Container.resource_name]
      end

      # Evaluate the text against the current filter
      # @return [nil, MatchData] if the match is made, a MatchData object is returned, otherwise nil
      def evaluate text
        re = Regexp.new self.filter
        re.match(text)
      end

      # Evaluate all filters for the current user (and associated roles) in the activity log
      # @return [Boolean]
      def self.evaluate text, item, user: nil
        user ||= item.current_user
        fs = filters_for item, user: user
        fs.each do |f|
          return true if f.evaluate text
        end

        false
      end

      # Evaluate a query directly in the database to produce a filtered set of records
      # Acts as a scope on ActiveRecord relations
      # @param item [ActivityLog|NfsStore::ManageContainer] container or activity log referencing the container
      # @param user [User|nil]
      # @return [ActiveRecord::Relation] resultset of all matched records
      def self.evaluate_container_files item, user: nil

        user ||= item.current_user
        filters = filters_for(item, user: user).pluck(:filter)

        if item.model_data_type == :activity_log
          container  = ModelReference.find_referenced_items(item, record_type: 'NfsStore::Manage::Container').first
        end

        raise FsException::Action.new "No filestore container provided to evaluate filter" unless container

        conds = [""] + filters
        conds[0] = filters.map{|f| "(coalesce(path, '') || '/' || file_name) ~ ?"}.join(' OR ')
        sf = container.stored_files.where(conds)

        conds = [""] + filters
        conds[0] = filters.map{|f| "('/' || archive_file || '/' ||  coalesce(path, '') || '/' || file_name) ~ ?"}.join(' OR ')

        af = container.archived_files.where(conds)

        sf + af
      end

      private

        def filter_is_valid

          begin
            Regexp.new(self.filter)
          rescue RegexpError => e
            failed_regex = true
          end

          if self.filter.blank? || failed_regex
            errors.add :filter, "is not a valid regular expression"
            return
          end

          true
        end


    end
  end
end
