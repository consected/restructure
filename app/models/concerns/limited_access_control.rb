module LimitedAccessControl

  extend ActiveSupport::Concern

  AssignedToCol = 'assign_access_to_user_id'.freeze

  class_methods do

    # Scope queries to assigned users (if the model supports this)
    # Ignored otherwise and returns self
    # @param current_user [User]
    # @return [ActiveRecord::Relation] self if assigned to user not supported,
    #   or scoped where it matches the current user otherwise

    def limit_to_assigned current_user

      if requires_assigned_user?
        where(AssignedToCol => current_user.id)
      else
        all
      end

    end

    def requires_assigned_user?
      attribute_names.include?(AssignedToCol)
    end

    def join_limit_to_assigned assoc_name, current_user

      res = self.joins(assoc_name)
      assoc = self.new.send(assoc_name)

      if assoc.requires_assigned_user?
        table_name = ModelReference.record_type_to_ns_table_name(assoc_name)
        res = res.where(table_name => {AssignedToCol => current_user.id})
      end

      res
    end

  end

  def assign_access_to_user_id= id

    if id.is_a?(String) && id.include?('@')
      u = User.where(email: id).first
      raise FphsException.new("No user found for supplied user name") unless u
      id = u.id
    end

    write_attribute :assign_access_to_user_id, id
  end

end
