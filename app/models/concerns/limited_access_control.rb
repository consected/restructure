# frozen_string_literal: true

module LimitedAccessControl
  extend ActiveSupport::Concern

  AssignedToCol = 'assign_access_to_user_id'

  class_methods do
    #
    # Scope queries to assigned users (if the model supports this)
    # Ignored otherwise and returns self
    # @param current_user [User]
    # @return [ActiveRecord::Relation] self if assigned to user not supported,
    #   or scoped where it matches the current user otherwise
    def limit_to_assigned(current_user)
      res = if requires_assigned_user?
              where(AssignedToCol => current_user.id)
            else
              all
            end

      res = res.active if allows_disabled?

      res
    end

    def requires_assigned_user?
      attribute_names.include?(AssignedToCol)
    end

    def allows_disabled?
      attribute_names.include?('disabled')
    end

    #
    # Join an association for a limited_access user access control to the master scope.
    # For access :limited, an inner join ensures that all resources must exist for the
    # user access to be granted access.
    #
    # For access :limited_if_none, a left join ensures that any of the resources must exist for the
    # user access to be granted access. Careful construction of the left join on clause is required,
    # to ensure that all conditions are tested appropriately and don't block one another.
    #
    # If the AssignedToCol is present in the associated model
    # then this must be set on the joins to further limit the access to the current user.
    # @param [Admin::UserAccessControl] uac
    # @param [User] current_user
    # @return [ActiveRecord::Relation]
    def join_limit_to_assigned(uac, current_user)
      assoc_name = uac.resource_name.to_sym
      assoc = (new.send(assoc_name) if new.respond_to?(assoc_name))

      case uac.access
      when 'limited'
        # Set up the inner join based on the user access control and associated dynamic model / external identifiers
        res = joins(assoc_name)
        res = res.only_created_by_current_user(current_user) if assoc_name == :master_created_by_user
        return res unless assoc

        # A real association allows us to check if the dynamic model / external identifier has an assigned user field
        # or can be set as disabled
        table_name = ModelReference.record_type_to_ns_table_name(assoc_name)
        res = res.where(table_name => { AssignedToCol => current_user.id }) if assoc.requires_assigned_user?
        res = res.where(table_name => { disabled: [false, nil] }) if assoc.allows_disabled?
      when 'limited_if_none'
        # Set up the left outer join based on the user access control and
        # associated dynamic model / external identifiers
        table_name = ModelReference.record_type_to_ns_table_name(assoc_name)
        clause = case assoc_name
                 when :master_created_by_user
                   # We join on the *users* table having master records created by users and the "created by user"
                   # matches the current user ID.
                   table_name = 'users'
                   "users.id = masters.created_by_user_id AND masters.created_by_user_id = #{current_user.id}"
                 when :temporary_master
                   # We join on the *masters* table, which has a label "temporary_master", and check the id is in
                   # the list of temporary master IDs
                   real_name = 'masters'
                   "#{table_name}.id = masters.id and temporary_master.id in (#{Master::TemporaryMasterIds.join(', ')})"
                 else
                   # Simply join the master on the foreign key
                   "#{table_name}.master_id = masters.id"
                 end

        if assoc
          # A real association allows us to check if the dynamic model / external identifier has an assigned user field
          # or can be set as disabled. We add these extensions to the original "on" clause. If we had tried to apply
          # these to the query's where clause, they could break the interaction between conditions, leading to one
          # result overriding another incorrectly.
          clause = "#{clause} AND #{table_name}.#{AssignedToCol} = #{current_user.id}" if assoc.requires_assigned_user?
          clause = "#{clause} AND NOT coalesce(#{table_name}.disabled, FALSE)" if assoc.allows_disabled?
        end
        res = joins("LEFT OUTER JOIN #{real_name} #{table_name} on #{clause} ")
      else
        # No limited access was specified, so just return the result
        res = all
      end

      res
    end
  end

  #
  # Allow the *assign_access_to_user_id* attribute to be set by an email address (the user email)
  # or ID.
  # @param [String|Integer] id
  def assign_access_to_user_id=(id)
    if id.is_a?(String) && id.include?('@')
      u = User.where(email: id).first
      raise FphsException, 'No user found for supplied user name' unless u

      id = u.id
    end

    write_attribute :assign_access_to_user_id, id
  end
end
