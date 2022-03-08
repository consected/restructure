module LimitedAccessControl
  extend ActiveSupport::Concern

  AssignedToCol = 'assign_access_to_user_id'.freeze

  class_methods do
    # Scope queries to assigned users (if the model supports this)
    # Ignored otherwise and returns self
    # @param current_user [User]
    # @return [ActiveRecord::Relation] self if assigned to user not supported,
    #   or scoped where it matches the current user otherwise

    def limit_to_assigned(current_user)
      if requires_assigned_user?
        where(AssignedToCol => current_user.id)
      else
        all
      end
    end

    def requires_assigned_user?
      attribute_names.include?(AssignedToCol)
    end

    #
    # Join association for a limited_access user access control to the master scope.
    # For access :limited, and inner join ensures that all resources must exist for the
    # user access to be
    #
    # If the AssignedToCol is present in the associated model used to limit access
    # then this must be set on the scope to further limit the access to the current user.
    #
    # The assoc may not be set if the association is a :belongs_to:
    # this is used by the :user and :master_created_by_user associations.
    # For these, existence depends on an join of a single item anyway,
    # so the additional limitation is not required
    def join_limit_to_assigned(assoc, current_user)
      assoc_name = assoc.resource_name.to_sym
      res = case assoc.access
            when 'limited'
              joins(assoc_name)
            when 'limited_if_none'
              left_joins(assoc_name)
            else
              all
            end

      assoc = (new.send(assoc_name) if new.respond_to?(assoc_name))

      if assoc&.requires_assigned_user?
        table_name = ModelReference.record_type_to_ns_table_name(assoc_name)
        res = res.where(table_name => { AssignedToCol => current_user.id })
      end

      res
    end
  end

  def assign_access_to_user_id=(id)
    if id.is_a?(String) && id.include?('@')
      u = User.where(email: id).first
      raise FphsException, 'No user found for supplied user name' unless u

      id = u.id
    end

    write_attribute :assign_access_to_user_id, id
  end
end
