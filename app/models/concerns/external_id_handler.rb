module ExternalIdHandler

  extend ActiveSupport::Concern

  class NoUnassignedAvailable < FphsException
    def message
      "No available IDs for assignment"
    end
  end

  included do

    attr_accessor :create_count, :just_assigned, :assign_all, :assign_all_request
    after_initialize :init_vars_external_id_handler

    before_validation :during_create_master
    after_save :return_all

    scope :assigned, -> {where "master_id is not null"}
    scope :unassigned, -> {where "master_id is null"}
    #default_scope -> {order id: :desc}
    default_scope -> {order updated_at: :desc, id: :desc}

    # @prevent_create = nil
    # @prevent_edit = nil
    # @id_formatter = nil
    # @label = nil

    validates self.external_id_attribute, presence: true,
                                          numericality: {
                                            only_integer: true,
                                            greater_than_or_equal_to: (external_id_range.min || 0),
                                            less_than_or_equal_to: (external_id_range.max || 0)
                                          },
                                          unless: :alphanumeric?
    validate :external_id_tests

  end

  class_methods do

    def find_by_external_id value
      self.where(external_id_attribute => value).first
    end



    # Get the next unassigned ID item from the the external id table
    def next_available owner
      # Have to use #unscoped to ensure that the scope of the association does not interfere with
      # the unassigned query (or any queries from the class in fact), which seems to incorporate
      # a master_id = ? condition automatically, based on the underlying association.
      # Not sure when this requirement was introduced, but it is necessary.
      item = unscoped.unassigned.first
      raise ::ExternalIdHandler::NoUnassignedAvailable  unless item
      logger.info "Got next available external id #{item.id}"
      item.assigned_by = "fphsapp" if item.respond_to? :assigned_by=
      item
    end

    def allow_to_generate_ids?
      @allow_to_generate_ids
    end

    def prevent_edit= val
      @prevent_edit = val
    end

    def prevent_create= val
      @prevent_create = val
    end

    def external_id_attribute= val
      @external_id_attribute = val
    end

    def external_id_view_formatter= val
      @id_formatter = val
    end

    def external_id_range= val
      @external_id_range = val
    end

    def external_id_edit_pattern= val
      @external_edit_id_pattern = val
    end

    def label= val
      unless defined? @label
        @label = nil
      end
      @label
    end

    def human_name
      self.label
    end

    def prevent_edit?
      return @prevent_edit unless @prevent_edit.nil?
      false
    end

    def prevent_create?
      return @prevent_create unless @prevent_create.nil?
      false
    end

    def alphanumeric
      @alphanumeric
    end

    def external_id_attribute
      @external_id_attribute
    end

    def external_id_view_formatter
      @external_id_view_formatter
    end

    def external_id_range
      unless defined? @external_id_range
        @external_id_range = nil
      end
      @external_id_range || (1..9999999999)
    end

    def external_id_edit_pattern
      @external_id_edit_pattern# || '\\d{0,10}'
    end

    def plural_name
      name.underscore.pluralize
    end

    def hyphenated_plural_name
      name.underscore.pluralize.hyphenate
    end
    def label
      @label || self.name.underscore.humanize.titleize
    end

    # For external ID models that require an auto-generated or auto-assigned (from an existing list) ID,
    # the master association build method will use this method.
    # By default, the next available ID will be generated randomly.
    def master_build_with_random_id owner, att=nil
      if att
        self.assign_random_id owner
      else
        self.new master: owner
      end
    end

    # We assign the random id
    def assign_random_id master
      item = self.new master: master
      item[external_id_attribute] = self.generate_random_id
      item.just_assigned = true
      item
    end

    # Generate a random number with no leading zeros or spaces in the defined external_id_range
    def generate_random_id
      m = external_id_range.max
      add = (m+1)/10
      upper = m - add
      SecureRandom.random_number(upper) + add
    end

    # SageAssignments for example expand on the master_build_with_random_id method
    # in order to pluck the next available pre-generated ID from a list.
    def master_build_with_next_id owner, att=nil
      if att
        self.assign_next_available_id owner
      else
        self.new master: owner
      end
    end

    def assign_next_available_id master

      item = self.next_available master
      item.just_assigned = true
      item.master = master
      item

    end

    def masters_without_assignment
      all_assigned = self.where('master_id is not null').map(&:master_id)

      # Add a dummy item that prevents the query returning no items if
      # the all_assigned array is empty
      all_assigned << -1
      Master.where("id not in (?)", all_assigned)
    end

    def generate_ids_for_all_masters admin
      raise "Only admins can perform this function" unless admin && admin.enabled? && allow_to_generate_ids?
      res = []
      errors = []

      raise FphsException.new "No master records without an assignment" if masters_without_assignment.count == 0

      begin
        items = []
        value_items = []
        tnow = DateTime.now.iso8601
        self.transaction do
          sql = "INSERT into #{self.table_name} (#{external_id_attribute}, admin_id, master_id, created_at, updated_at) VALUES "
          masters_without_assignment.pluck(:id).each do |m|
            item = m
            value_items << "('#{generate_random_id.to_s}', #{admin.id}, #{m}, '#{tnow}', '#{tnow}')"
            items << item
          end
          sql << value_items.join(',')
          self.connection.execute sql
        end
        res = items
      rescue PG::UniqueViolation
        logger.info "Failed to create a #{self.name.humanize} record due to an random duplicate."
      end
      res
    end

    def generate_ids admin, count=10

      raise "Only admins can perform this function" unless admin && admin.enabled? && allow_to_generate_ids?

      res = []

      begin
        items = []
        value_items = []
        tnow = DateTime.now.iso8601

        self.transaction do
          sql = "INSERT into #{self.table_name} (#{external_id_attribute}, admin_id, master_id, created_at, updated_at) VALUES "
          (1..count).each do |c|
            item = c
            value_items << "('#{generate_random_id.to_s}', #{admin.id}, NULL, '#{tnow}', '#{tnow}')"
            items << item
          end
          sql << value_items.join(',')
          self.connection.execute sql
        end

        res = items

      rescue PG::UniqueViolation
        logger.info "Failed to create a #{self.name.humanize} record due to an random duplicate"
      end


      res
    end


  end

  def current_user
    master.current_user
  end

  def current_user= cu
    master.current_user = cu
  end

  def alphanumeric?
    !!self.class.alphanumeric
  end

  def data
    self.external_id
  end

  def no_master_association
    false
  end

  def allows_nil_master?
    self.class.allow_to_generate_ids?
  end

  def creatable_without_user
    self.class.allow_to_generate_ids?
  end

  def external_id
    send(self.class.external_id_attribute)
  end

  def external_id= val
    send("#{self.class.external_id_attribute}=", val)
  end

  def external_id_changed?
    send("#{self.class.external_id_attribute}_changed?")
  end

  def check_status
    @was_created = id_changed? || just_assigned ? 'created' : false
    @was_updated = updated_at_changed? ? 'updated' : false
  end

  def return_all
    self.multiple_results = self.master.send(self.class.assoc_inverse).all if self.master && self.class.prevent_edit?
  end

  def init_vars_external_id_handler
    instance_var_init :admin_set
  end

  # A special case to handle the creation of instances during the creation of a master (under the app configuration :create_master_with)
  # Since we don't want this to fail due to a validation error with a blank external ID, force the ID to the min value
  # if the external ID is not already set
  def during_create_master

    if creating_master
      if external_id.blank?
        self.external_id = self.class.external_id_range.min
      end
    end
  end

  def external_id_tests

    if self.external_id.blank?
      errors.add self.class.external_id_attribute, "can not be blank"
    end

    if persisted? && external_id_changed? && self.class.prevent_edit?
      errors.add self.class.external_id_attribute, "can not be changed"
    end

    if persisted? && master_id_changed? && !master_id_was.nil?
      errors.add :master, "record this #{self.class.label} is associated with can not be changed"
    end

    if master_id.nil? && (!respond_to?(:admin_id) || admin_id.nil?)
      errors.add :master_id, "must be set when adding #{self.class.external_id_attribute}"
    end

    if external_id_changed? || !persisted?

      s = self.class.find_by_external_id(external_id)
      if s
        errors.add self.class.external_id_attribute, "already exists in this master record" if s.master_id == self.master_id
        errors.add self.class.external_id_attribute, "already exists in another master record (master ID: #{s.master_id})" if s.master_id != self.master_id
      end

    end

  end


end
