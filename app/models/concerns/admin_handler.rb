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
    scope :limited_index, -> {}

    before_validation :ensure_admin_set, unless: -> { self.class.admin_optional }
    before_create :setup_values
    after_save :invalidate_cache

    attr_reader :updated_from_report

    add_model_to_list
  end

  class_methods do
    #
    # Provide access to the @admin_optional class variable
    # @return [Boolean]
    def admin_optional
      @admin_optional
    end

    #
    # Get the latest updated_at or created_at value for this type and memoize it
    # The memo can be dropped with reset_latest_update
    # @param [true|nil] force - force the latest update memo to be updated (default nil)
    # @return [DateTime]
    def latest_update(force: nil)
      return @latest_update if @latest_update && !force

      obj = reorder('').order(Arel.sql('coalesce(updated_at, created_at) desc nulls last')).first
      @latest_update = obj&.updated_at&.to_time || obj&.created_at&.to_time
    end

    #
    # Reset the memo for latest_update for this class
    def reset_latest_update
      @latest_update = nil
    end

    def resource_name
      return super if defined? super

      name.ns_underscore.pluralize
    end

    # Resource name for a single instance of the model
    def resource_item_name
      resource_name.to_s.singularize.to_sym
    end

    def human_name
      name.underscore.humanize.titleize
    end

    #
    # Save this model in the resources list
    def add_model_to_list
      Resources::Models.add self unless abstract_class
    end

    # The base string for route
    # For example "admin/app_types"
    # Dynamic configurations will override this
    def base_route_segments
      "admin/#{table_name}"
    end

    def base_route_short_name
      table_name
    end

    # The base string for route names
    # For example `send("new_#{base_route_name}_path")` returns the path
    # to the "new" controller action
    def base_route_name
      base_route_segments.singularize.gsub('/', '_')
    end

    unless respond_to? :no_master_association
      # In case we are attempting to use the admin models in references or
      # other dynamic definition configurations, ensure they know there is no master association defined
      def no_master_association
        true
      end
    end
  end

  def init_vars_admin_handler
    instance_var_init :admin_set
    instance_var_init :current_admin
    instance_var_init :current_admin_id
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

  def updated_from_report!
    @updated_from_report = true
  end

  def admin_name
    return unless admin_id

    Admin.emails_by_id[admin_id]
  end

  def admin_email
    admin_name
  end

  def admin=(_new_admin)
    raise 'can not change admin'
  end

  def admin_id=(_new_admin)
    raise 'can not change admin id'
  end

  def current_admin=(new_admin)
    raise 'Current admin not set' unless new_admin&.id
    raise 'Bad Admin' unless new_admin.is_a?(Admin)
    raise 'Admin not enabled' if new_admin.disabled

    @admin_set = true
    @current_admin = new_admin
    write_attribute(:admin_id, new_admin.id)
  end

  def current_admin_id=(new_admin_id)
    new_admin = Admin.find_by(id: new_admin_id)
    self.current_admin = new_admin
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
    return unless respond_to?(:user_id) && user_id

    User.emails_by_id[user_id]
  end

  def _class_name
    self.class.name
  end

  def as_json(options = {})
    options[:methods] ||= []

    options[:methods] << :_class_name
    options[:methods] << :user_email

    # If the record has been updated from a report, ensure that we override
    # any except options to ensure all fields are included in the results.
    # Devise will apply a very restrictive set of fields otherwise
    options[:force_except] = [] if updated_from_report

    super(options)
  end

  def ensure_admin_set
    return if admin_set?

    errors.add(:admin, 'has not been set')
    # throw(:abort)
  end

  def prevent_item_type_change
    return unless item_type_changed? && persisted?

    errors.add(:item_type, 'change not allowed!')
    # throw(:abort)
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

  #
  # Resource name used to identify models in for admin / user matched resources and elsewhere.
  # @return [String]
  def admin_resource_name
    self.class.name.ns_underscore.pluralize
  end

  def resource_name
    return super if defined? super

    admin_resource_name
  end

  # Resource name for a single instance of the model
  def resource_item_name
    resource_name.to_s.singularize.to_sym
  end

  # Provide a usable name if this is not overriden or
  # already exists as a DB attribute
  def name
    return super if defined? super

    resource_name.humanize
  end

  #
  # Returns the full model name, namespaced like 'module__class' if there is a namespace.
  # otherwise it returns just the basic name
  def admin_item_type
    self.class.name.singularize.ns_underscore
  end

  def admin_item_type_us
    admin_item_type.ns_underscore
  end

  def model_data_type
    :admin_model
  end

  #
  # Invalidate the cache and latest update value
  # @return [<Type>] <description>
  def invalidate_cache
    # Allows caching in other classes to reset
    self.class.reset_latest_update

    return unless clear_rails_cache_on_save?

    logger.info "Admin record added or updated (#{self.class.name}). Invalidating cache"

    # Unfortunately we have no way to clear pattern matched keys with memcached so we just clear the whole cache
    Rails.cache.clear
  end

  #
  # Whether this save should clear the entire Rails cache.
  # Defaults to true for all admin models. Override in models that are saved
  # very frequently during normal operation (e.g. User, Admin) to limit
  # the whole-cache clear to only the changes that actually require it.
  # @return [Boolean]
  def clear_rails_cache_on_save?
    true
  end
end
