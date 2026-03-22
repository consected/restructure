# frozen_string_literal: true

module UserAndRoles
  extend ActiveSupport::Concern

  private

  class_methods do
    # Standard ordering clause for lists and evaluation of user and roles
    def priority_order
      Arel.sql <<~END_SQL
        app_type_id ASC NULLS LAST,
        CASE
        WHEN user_id IS NOT NULL THEN user_id::varchar
        WHEN (role_name IS NOT NULL AND role_name <> '') THEN role_name
        ELSE user_id::varchar
        END
      END_SQL
    end

    # Ordered scope of user and role conditions used in user access controls and app configurations
    # @param user [User] the user to apply the conditions to
    # @param alt_app_type [Admin::AppType | Integer] app type or ID for the app type to apply to if the user does not have a current app_type set
    # @param alt_role_name [String] role name for an Admin::UserRole when the role control is to override the default controls
    # @return [ActiveRecord] scoped query
    def scope_user_and_role(user, alt_app_type = nil, alt_role_name = nil)
      where_user_and_role(user, alt_app_type, alt_role_name).order_user_and_role
    end

    # Scope the user and role conditions used in user access controls and app configurations
    # @param user [User] the user to apply the conditions to
    # @param alt_app_type [Admin::AppType | Integer | Symbol] app type or ID for the app type to apply to if
    #   the user does not have a current app_type set. If set to :ignore, do not apply an app_type condition at all
    # @param alt_role_name [String] role name for an Admin::UserRole when the role control is to override the default controls
    # @return [ActiveRecord] scoped query
    def where_user_and_role(user, alt_app_type = nil, alt_role_name = nil)
      where_clause = ''
      where_conditions = []
      if user
        where_clause += 'user_id = ?'
        where_conditions << user.id
      end

      app_type = alt_app_type || user&.app_type_id
      app_type_id = if app_type.is_a? Admin::AppType
                      app_type.id
                    else
                      app_type
                    end

      if alt_role_name
        rn = alt_role_name
        rn = [rn] unless rn.is_a? Array
        app_type_role_names = rn.map { |v| [app_type_id, v] }
      elsif user
        app_type_role_names = user.app_type_role_names(app_type_id: app_type)
      end

      if app_type_role_names&.present?
        app_type_role_names.each do |pair|
          where_clause += ' OR ' if where_clause.present?
          app_type_clause = if pair.first
                              'app_type_id = ?'
                            else
                              pair = [pair.last]
                              'app_type_id IS NULL'
                            end
          where_clause += "(#{app_type_clause} AND role_name = ?)"
          where_conditions += pair
        end
      end

      where_clause += ' OR ' if where_clause.present?
      where_clause += "(user_id IS NULL AND (role_name IS NULL OR role_name = ''))"
      conditions = [where_clause] + where_conditions

      active.where(app_type_id: [app_type_id, nil]).where(conditions)
    end

    def order_user_and_role
      order(priority_order)
    end
  end
end
