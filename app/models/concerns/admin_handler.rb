# frozen_string_literal: true

module AdminHandler
  extend ActiveSupport::Concern

  included do
    after_initialize :init_vars_admin_handler

    # If the class including this concern has already set the class variable
    # `@admin_optional = true`, use it to change the optional requirement on the
    # admin association
    belongs_to :admin, optional: @admin_optional
    scope :active, -> { where 'disabled is null or disabled = false' }
    scope :disabled, -> { where 'disabled = true' }

    before_validation :ensure_admin_set
    before_create :setup_values

    scope :limited_index, -> {}
  end

  def init_vars_admin_handler
    instance_var_init :admin_set
    instance_var_init :current_admin
  end

  def setup_values
    self.disabled = false if disabled.nil?
  end

  def enabled?
    !disabled
  end

  def disable!(current_admin = nil)
    self.current_admin = current_admin if current_admin
    self.disabled = true
    save
  end

  def enable!(current_admin = nil)
    self.current_admin = current_admin if current_admin
    self.disabled = false
    save!
  end

  def admin_name
    return unless admin

    admin.email
  end

  def admin=(_new_admin)
    raise 'can not change admin'
  end

  def admin_id=(_new_admin)
    raise 'can not change admin id'
  end

  def current_admin=(new_admin)
    raise 'Bad Admin' unless new_admin.is_a?(Admin) && new_admin.id && !new_admin.disabled

    @admin_set = true
    @current_admin = new_admin
    write_attribute(:admin_id, new_admin.id)
  end

  # Chainable function, allowing something like:
  # admin_resource.with_admin(admin).disable!
  def with_admin(admin)
    self.current_admin = admin
    self
  end

  def current_admin
    return nil unless @admin_set

    @current_admin
  end

  # use this to check whether a current admin user has been assigned to act on this record
  def admin_set?
    !!@admin_set
  end

  # user email to allow simplified exports
  def user_email
    user.email if respond_to?(:user) && user
  end

  def as_json(options = {})
    options[:methods] ||= []

    options[:methods] << :user_email

    super(options)
  end

  def ensure_admin_set
    return if admin_set?

    errors.add(:admin, 'has not been set')
    # throw(:abort)
  end

  def prevent_item_type_change
    if item_type_changed? && persisted?
      errors.add(:item_type, 'change not allowed!')
      # throw(:abort)
    end
  end

  # Check if a specific attribute value has already been used in an active definition
  # @param *attrs any number of attributes to compare against
  # @return [true | false]
  def already_taken(*attrs)
    comp = {}
    attrs.each do |a|
      comp[a] = self[a.to_s]
    end

    res = self.class.active.where(comp)
    res = res.where('id <> ?', id) if id

    !!res.first
  end
end
