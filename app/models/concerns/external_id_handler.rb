module ExternalIdHandler

  extend ActiveSupport::Concern

  class NoUnassignedAvailable < FphsException
    def message
      "No available IDs for assignment"
    end
  end

  included do

    attr_accessor :create_count, :just_assigned
    after_initialize :init_vars_external_id_handler
    after_save :return_all

    scope :assigned, -> {where "master_id is not null"}
    scope :unassigned, -> {where "master_id is null"}
    default_scope -> {order id: :desc}

    # @prevent_create = nil
    # @prevent_edit = nil
    # @id_formatter = nil
    # @label = nil

    validates self.external_id_attribute, presence: true,  numericality: { only_integer: true, greater_than_or_equal_to: external_id_range.min, less_than_or_equal_to: external_id_range.max }
    validate :external_id_tests

  end

  class_methods do

    def find_by_external_id value
      self.where(external_id_attribute => value).first
    end



    # Get the next unassigned ID item from the the external id table
    def next_available owner
      item = unassigned.unscope(:order).first
      raise ::ExternalIdHandler::NoUnassignedAvailable  unless item
      logger.info "Got next available external id #{item.id}"
      item.assigned_by = "fphsapp" if item.respond_to? :assigned_by=
      item
    end

    def allow_to_generate_ids?
      true
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

    def prevent_edit?
      return @prevent_edit unless @prevent_edit.nil?
      false
    end

    def prevent_create?
      return @prevent_create unless @prevent_create.nil?
      false
    end

    def external_id_attribute
      @external_id_attribute
    end

    def external_id_view_formatter
      @id_formatter || ''
    end

    def external_id_range
      unless defined? @external_id_range
        @external_id_range = nil
      end
      @external_id_range || (1..9999999999)
    end

    def external_id_edit_pattern
      @external_id_edit_pattern || '\\d{0,10}'
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


    def generate_ids admin, count=10

      raise "Only admins can perform this function" unless admin && admin.enabled? && allow_to_generate_ids?

      res = []

      (1..count).each do |c|

        begin
          item = self.new(external_id_attribute => generate_random_id.to_s, admin_id: admin.id)
          item.no_track = true
          item.save!
          res << item
        rescue PG::UniqueViolation
          logger.info "Failed to create a #{self.name.humanize} record due to an random duplicate"
        end

      end

      res
    end


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

  def external_id_changed?
    send("#{self.class.external_id_attribute}_changed?")
  end

  def check_status
    @was_created = id_changed? || just_assigned ? 'created' : false
    @was_updated = updated_at_changed? ? 'updated' : false
  end

  def return_all
    self.multiple_results = self.master.send(assoc_inverse_name).all if self.master
  end


  def init_vars_external_id_handler
    instance_var_init :admin_set
  end

  def external_id_tests

    if self.external_id.blank?
      errors.add self.class.external_id_attribute, "can not be blank"
    end

    if persisted? && external_id_changed? && !@prevent_edit
      errors.add self.class.external_id_attribute, "can not be changed"
    end

    if persisted? && master_id_changed? && !master_id_was.nil?
      errors.add :master, "record this #{self.class.label} is associated with can not be changed"
    end

    if external_id_changed? || !persisted?

      s = self.class.find_by_external_id(external_id)
      if s
        errors.add self.class.external_id_attribute, "already exists in this master record" if s.master_id == self.master_id
        errors.add self.class.external_id_attribute, "already exists in another master record (#{s.master.msid ? "MSID: #{s.master.msid}" : "master ID: #{s.master_id}"})" if s.master_id != self.master_id
      end

    end

  end


end
