# frozen_string_literal: true

# User roles provide an app specific mechanism for granting users permissions to
# data and functionality, but this remains very much about access to specific
# panels and application features.
# To address this, role templates group user roles together, to provide a way
# of indicating a user performs a specific functional role, which is more related
# to the business operations. These are grouped by assigning user roles to "template"
# users - users with usernames ending in @template.
# The user template role groups a user has is decided by checking if a user has all roles
# a user@template has. This is performed by the view *ml_app.user_app_functional_groups*
# See (app-scripts/create_ml_app_user_app_functional_groups_view.sql)
class Admin::RoleDescription < Admin::AdminBase
  self.table_name = 'role_descriptions'

  include AdminHandler
  include AppTyped

  validates :role_name, presence: true, unless: -> { role_template.present? }
  validates :role_template, presence: true, unless: -> { role_name.present? }
  validate :must_be_unique

  def self.no_downcase_attributes
    [:name]
  end

  #
  # Get role names from, either unfiltered, or from a previous scope
  # @return [Array{String}] list of string role names
  def self.user_role_names
    conditions = { app_types: { id: Settings::OnlyLoadAppTypes } } if Settings::OnlyLoadAppTypes
    Admin::UserRole.role_names_by_app_name(conditions: conditions)
  end

  def self.role_names_by_app_name
    conditions = { app_types: { id: Settings::OnlyLoadAppTypes } } if Settings::OnlyLoadAppTypes
    Admin::UserRole.role_names_by_app_name(conditions: conditions)
  end

  #
  # Get template names, which are user emails ending in '@template' attached to user roles
  # @return [Array{String}] list of template names
  def self.role_templates
    items = {}
    condsql = '(user_roles.disabled is null or user_roles.disabled = false) AND '\
          '(users.disabled is null or users.disabled = false) AND ' \
          "users.email LIKE '%@template' AND users.email <> 'template@template'"

    res = Admin::UserRole
          .joins(:user, :app_type)
          .includes(:user, :app_type)
          .where(condsql)

    res = if Settings::OnlyLoadAppTypes
            res.where(app_types: { id: Settings::OnlyLoadAppTypes })
          else
            res.where.not(app_types: { id: nil })
          end

    res = res.each do |r|
      k = "#{r.app_type_id}/#{r.app_type.name}"
      if items[k]
        items[k] << r.user.email unless items[k].include?(r.user.email)
      else
        items[k] = [r.user.email]
      end
    end

    items
  end

  private

  #
  # Validation for uniqueness
  def must_be_unique
    if role_template.present? &&
       self.class.active
           .where(
             app_type_id: app_type_id,
             role_template: role_template
           )
           .where.not(id: id)
           .first
      errors.add :role_template, 'already exists'
    end

    if role_name.present? &&
       self.class.active
           .where(
             app_type_id: app_type_id,
             role_name: role_name
           )
           .where.not(id: id)
           .first
      errors.add :role_name, 'already exists'
    end

    true
  end
end
