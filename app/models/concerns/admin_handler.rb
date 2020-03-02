module AdminHandler
  extend ActiveSupport::Concern

  included do
    after_initialize :init_vars_admin_handler
    belongs_to :admin
    scope :active, -> {where "disabled is null or disabled = false"}
    scope :disabled, -> {where "disabled = true"}

    before_validation :ensure_admin_set
    before_create :setup_values

    scope :index, -> {}
  end

  def init_vars_admin_handler
    instance_var_init :admin_set
    instance_var_init :current_admin
  end

  def setup_values
    disabled = false if disabled.nil?
    true
  end

  def enabled?
    !disabled
  end

  def disable! current_admin=nil
    self.current_admin = current_admin if current_admin
    self.disabled = true
    self.save
  end

  def enable! current_admin=nil
    self.current_admin = current_admin if current_admin
    self.disabled = false
    self.save!
  end

  def admin_name
    return unless admin
    admin.email
  end

  def admin= new_admin
    raise "can not change admin"
  end

  def admin_id= new_admin
    raise "can not change admin id"
  end

  def current_admin= new_admin
    raise "Bad Admin" unless new_admin.is_a?(Admin) && new_admin.id && !new_admin.disabled
    @admin_set = true
    @current_admin = new_admin
    write_attribute(:admin_id, new_admin.id)
  end

  # Chainable function, allowing something like:
  # admin_resource.with_admin(admin).disable!
  def with_admin admin
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
    if respond_to?(:user) && user
      user.email
    end
  end

  def as_json options={}

    options[:methods] ||= []


    options[:methods] << :user_email

    super(options)
  end

  def ensure_admin_set
    errors.add(:admin, "has not been set") unless admin_set?
  end

  def prevent_item_type_change
    if item_type_changed? && self.persisted?
      errors.add(:item_type, "change not allowed!")
    end
  end


  # Check if a specific attribute value has already been used in an active definition
  # @param *attrs any number of attributes to compare against
  # @return [true | false]
  def already_taken *attrs

    comp = {}
    attrs.each do |a|
      comp[a] = self[a.to_s]
    end

    res = self.class.active.where(comp)
    res = res.where("id <> ?", self.id) if id

    !!res.first
  end

end
