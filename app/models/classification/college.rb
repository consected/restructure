# frozen_string_literal: true

class Classification::College < ActiveRecord::Base
  self.table_name = 'colleges'
  @admin_optional = true

  include AdminHandler
  include SelectorCache

  # Override standard admin association to make it optional
  belongs_to :user, optional: true

  default_scope -> { order 'colleges.updated_at DESC nulls last' }

  before_validation :downcase_name
  before_validation :prevent_name_change, on: :update
  before_validation :check_synonym
  before_validation :either_admin_or_user, on: :create
  validates :name, presence: true, uniqueness: true

  # Check if the college with 'name' exists. If so, return truthy value
  def self.exists?(name)
    res = all.exists? name: name.downcase
    res
  end

  # Create a new named college (working as the specified user) if the college does not exist already
  def self.create_if_new(name, user)
    return if exists? name

    logger.info "Adding new college to list: #{name}"
    c = Classification::College.new
    c.name = name.downcase
    c.current_user = user
    c.save!
    c
  end

  # Required to get user email address for admin view of who created the college record
  def user_name
    return nil unless user

    user.email
  end

  def current_user=(new_user)
    raise 'bad user set' unless new_user.is_a? User

    @user_set = true
    self.user = new_user
  end

  def user_set?
    return nil unless defined? @user_set

    !!@user_set
  end

  # Lookup the name of the record this is a synonym for
  def synonym_name
    return nil unless synonym_for_id

    c = Classification::College.find_by_id(synonym_for_id)
    return nil unless c

    c.name
  end

  protected

  def prevent_name_change
    if name_changed? && persisted? && !admin_set?
      errors.add(:name, 'change not allowed!')
      # throw(:abort)
    end
  end

  def ensure_admin_set
    # Override the standard test for admin being set, since users can create (but not update) colleges
    errors.add(:admin, 'has not been set') if persisted? && !admin_set?
  end

  # Validate that the college this record is being set as a synonym for actually exists
  def check_synonym
    if synonym_for_id
      sc = Classification::College.find_by_id(synonym_for_id)
      if !sc || sc.disabled
        errors.add :synonym, 'does not exist as a college already'
        # throw(:abort)
      end
    end

    true
  end

  def either_admin_or_user
    return if user_set? || admin_set?

    errors.add(:user, 'has not been set when not acting as admin')
    # throw(:abort)
  end

  def downcase_name
    return unless name

    self.name = name.downcase
  end
end
