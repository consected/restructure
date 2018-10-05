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
      # @param user [User] user that has filter definitions through role membership or user override
      # @param activity_log [NfsStore::Manage::Container] the activity log the container is within
      # @return [ActiveRecord::Relation] resultset of filters
      def self.filters_for user, activity_log

        rn = activity_log.extra_log_type_config.resource_name
        primary_conditions = {
          resource_name: rn
        }
        self.where(primary_conditions).scope_user_and_role(user)

      end

      # List of resource names for definitions of filters
      # @return [Array] list of full activity_log__type resource names
      def self.resource_names
        return ActivityLog.extra_log_type_resource_names
      end

      # Evaluate the text against the current filter
      # @return [nil, MatchData] if the match is made, a MatchData object is returned, otherwise nil
      def evaluate text
        re = Regexp.new self.filter
        re.match(text)
      end

      # Evaluate all filters for the current user (and associated roles) in the activity log
      # @return [Boolean]
      def self.evaluate text, user, activity_log
        fs = filters_for user, activity_log
        fs.each do |f|
          return true if f.evaluate text
        end

        false
      end

      # Evaluate a query directly in the database to produce a filtered set of records
      # Acts as a scope on ActiveRecord relations
      # @param textfield [String|Symbol] set of arguments text field in records to evaluate against
      # @return [ActiveRecord::Relation] resultset of all matched records
      def self.evaluate_container_files user, activity_log

        filters = filters_for(user, activity_log).pluck(:filter)
        conds = [""] + filters
        conds[0] = filters.map{|f| "(coalesce(path, '') || '/' || file_name) ~ ?"}.join(' OR ')

        activity_log_container = ModelReference.find_referenced_items(activity_log, record_type: 'NfsStore::Manage::Container').first

        raise FsException::Action.new "No filestore container referenced by activity log" unless activity_log_container

        sf = activity_log_container.stored_files.where(conds)
        af = activity_log_container.archived_files.where(conds)

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
