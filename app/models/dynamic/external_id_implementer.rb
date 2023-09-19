# frozen_string_literal: true

module Dynamic
  module ExternalIdImplementer
    extend ActiveSupport::Concern

    class NoUnassignedAvailable < FphsException
      def message
        'No available IDs for assignment'
      end
    end

    included do
      attr_accessor :create_count, :just_assigned, :assign_all, :assign_all_request, :existing_item_updated

      after_initialize :init_vars_external_id_handler

      before_validation :during_create_master
      after_save :return_all

      scope :assigned, -> { where 'master_id is not null' }
      scope :unassigned, -> { where 'master_id is null' }
      # default_scope -> {order id: :desc}
      default_scope -> { order updated_at: :desc, id: :desc }

      validates external_id_attribute, presence: true,
                                       numericality: {
                                         only_integer: true,
                                         greater_than_or_equal_to: (external_id_range.min || 0),
                                         less_than_or_equal_to: (external_id_range.max || 0)
                                       },
                                       unless: :alphanumeric?
      validate :external_id_tests
    end

    class_methods do
      #
      # The secondary_key to use for lookups of records using #find_by_secondary_key
      # @return [String] field name
      def secondary_key
        definition.secondary_key
      end

      def is_external_identifier?
        true
      end

      def external_id_edit_pattern
        @external_id_edit_pattern = definition.external_id_edit_pattern
      end

      def extra_fields
        @extra_fields = definition.extra_fields
      end

      def find_by_external_id(value)
        where(external_id_attribute => value).first
      end

      # Get the next unassigned ID item from the the external id table
      def next_available(_owner)
        # Have to use #unscoped to ensure that the scope of the association does not interfere with
        # the unassigned query (or any queries from the class in fact), which seems to incorporate
        # a master_id = ? condition automatically, based on the underlying association.
        # Not sure when this requirement was introduced, but it is necessary.
        item = unscoped.unassigned.first
        raise NoUnassignedAvailable unless item

        logger.info "Got next available external id #{item.id}"
        item.assigned_by = 'fphsapp' if item.respond_to? :assigned_by=
        item
      end

      def allow_to_generate_ids?
        @allow_to_generate_ids = definition.pregenerate_ids
      end

      def human_name
        label
      end

      def prevent_edit?
        @prevent_edit = definition.prevent_edit
        return @prevent_edit unless @prevent_edit.nil?

        false
      end

      def prevent_create?
        nil
      end

      def alphanumeric
        @alphanumeric = definition.alphanumeric
      end

      def external_id_attribute
        @external_id_attribute = definition.external_id_attribute
      end

      def external_id_view_formatter
        @external_id_view_formatter = definition.external_id_view_formatter
      end

      def external_id_range
        @external_id_range ||= definition.external_id_range || ExternalIdentifier::DefaultRange
      end

      def external_id_edit_pattern
        @external_id_edit_pattern = definition.external_id_edit_pattern
      end

      def plural_name
        name.underscore.pluralize
      end

      def hyphenated_plural_name
        name.underscore.pluralize.hyphenate
      end

      def label
        @label ||= definition.label || name.underscore.humanize.captionize
      end

      # For external ID models that require an auto-generated or auto-assigned (from an existing list) ID,
      # the master association build method will use this method.
      # By default, the next available ID will be generated randomly.
      def master_build_with_random_id(owner, att = nil)
        if att
          assign_random_id owner
        else
          new master: owner
        end
      end

      # We assign the random id
      def assign_random_id(master)
        item = new master: master
        item[external_id_attribute] = generate_random_id
        item.just_assigned = true
        item
      end

      # Generate a random number with no leading zeros or spaces in the defined external_id_range
      def generate_random_id
        m = external_id_range.max
        add = (m + 1) / 10
        upper = m - add
        SecureRandom.random_number(upper) + add
      end

      # SageAssignments for example expand on the master_build_with_random_id method
      # in order to pluck the next available pre-generated ID from a list.
      def master_build_with_next_id(owner, att = nil)
        # For the case when we are building one for edit form, no attributes are provided
        return new master: owner unless att

        # If attributes are provided, ensure they don't attempt to do anything bad
        att = att.to_h.symbolize_keys
        if att[external_id_attribute.to_sym].present?
          # Fail if there is an attempt to set the value manually
          obj = new master: owner
          obj.errors.add external_id_attribute, 'is assigned automatically and can not be assigned manually'
          return obj
        end

        item = assign_next_available_id owner

        # Merge in the attributes
        att.each do |k, v|
          item.send("#{k}=", v) unless k == external_id_attribute.to_sym
        end

        item
      end

      def assign_next_available_id(master)
        item = next_available master
        item.just_assigned = true
        item.master = master
        item
      end

      def masters_without_assignment
        all_assigned = where('master_id is not null').map(&:master_id)

        # Add a dummy item that prevents the query returning no items if
        # the all_assigned array is empty
        all_assigned << -1
        Master.where('id not in (?)', all_assigned)
      end

      def generate_ids_for_all_masters(admin)
        raise 'Only admins can perform this function' unless admin&.enabled? && allow_to_generate_ids?

        res = []
        raise FphsException, 'No master records without an assignment' if masters_without_assignment.count == 0

        begin
          items = []
          value_items = []
          tnow = DateTime.now.iso8601
          transaction do
            sql = "INSERT into #{table_name} (#{external_id_attribute}, admin_id, master_id, created_at, updated_at) VALUES "
            masters_without_assignment.pluck(:id).each do |m|
              item = m
              value_items << "('#{generate_random_id}', #{admin.id}, #{m}, '#{tnow}', '#{tnow}')"
              items << item
            end
            sql += value_items.join(',')
            connection.execute sql
          end
          res = items
        rescue PG::UniqueViolation
          logger.info "Failed to create a #{name.humanize} record due to an random duplicate."
        end
        res
      end

      def generate_ids(admin, count = 10)
        raise 'Only admins can perform this function' unless admin&.enabled? && allow_to_generate_ids?

        res = []

        begin
          items = []
          value_items = []
          tnow = DateTime.now.iso8601

          transaction do
            sql = "INSERT into #{table_name} (#{external_id_attribute}, admin_id, master_id, created_at, updated_at) VALUES "
            (1..count).each do |c|
              item = c
              value_items << "('#{generate_random_id}', #{admin.id}, NULL, '#{tnow}', '#{tnow}')"
              items << item
            end
            sql += value_items.join(',')
            connection.execute sql
          end

          res = items
        rescue PG::UniqueViolation
          logger.info "Failed to create a #{name.humanize} record due to an random duplicate"
        end

        res
      end
    end

    #
    # No versioning of templates at this time
    def def_version
      nil
    end

    def initialize(attr = {})
      super
      return unless master_id

      assign_generated_or_random_id
    end

    #
    # Override the #update method to ensure that embedded objects
    # that have not yet been persisted, but are updated with new attributes
    # are assigned an appropriate external ID if set for
    # pregenerated IDs or random IDs
    # @param [Hash] attr - attributes to be updated
    # @return [Boolean] result from super
    def update(attr)
      if (self.class.allow_to_generate_ids? || self.class.prevent_edit?) && !(persisted? || external_id)
        attr.delete self.class.external_id_attribute
        assign_generated_or_random_id
      end

      if existing_item_updated
        existing_item_updated.update attr
        self.updated_at = existing_item_updated.updated_at
        self.id = existing_item_updated.id
      else
        super
      end
    end

    def assign_generated_or_random_id
      if self.class.allow_to_generate_ids?
        assign_with_next_generated_id
      elsif self.class.prevent_edit?
        assign_with_random_id
      end
    end

    def assign_with_random_id
      self[self.class.external_id_attribute.to_sym] = self.class.generate_random_id
      self.just_assigned = true
    end

    def assign_with_next_generated_id
      return unless master_id && self.class.allow_to_generate_ids?

      c_user = current_user
      external_id_attribute = self.class.external_id_attribute.to_sym

      if attributes[external_id_attribute].present?
        # Fail if there is an attempt to set the value manually
        errors.add external_id_attribute, 'is assigned automatically and can not be assigned manually'
        return
      end

      next_item = self.class.assign_next_available_id master

      # Merge in the attributes from the existing item, to make the new instance represent the original
      attributes.each do |k, v|
        next_item.send("#{k}=", v) unless v.blank? || k.in?(%w[user_id master_id])
      end

      next_item.current_user = c_user
      self.existing_item_updated = next_item

      next_item.attributes
    end

    def model_data_type
      :external_identifier
    end

    def current_user
      master.current_user
    end

    def current_user=(cu)
      master.current_user = cu
    end

    def alphanumeric?
      !!self.class.alphanumeric
    end

    def data
      res = super
      return res unless res.blank?

      external_id
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

    def external_id=(val)
      send("#{self.class.external_id_attribute}=", val)
    end

    def external_id_changed?
      send("#{self.class.external_id_attribute}_changed?")
    end

    # Override standard operation for previous operation flags
    # External identifiers can exists as records that are not considered fully created
    # until they have been assigned to a master record. The standard mechanism that checks for
    # a created record does not achieve the desired effect.
    # was_created can be true even if the actual record was not just created:
    # If it was just assigned a master_id, then was_created is set to true
    def set_previous_action_flags
      @was_created = saved_change_to_id? || just_assigned ? 'created' : false
      @was_updated = saved_change_to_updated_at? ? 'updated' : false
    end

    def return_all
      self.multiple_results = master.send(self.class.assoc_inverse).all if master && self.class.prevent_edit?
    end

    def init_vars_external_id_handler
      instance_var_init :admin_set
    end

    # A special case to handle the creation of instances during the creation
    # of a master (under the app configuration :create_master_with)
    # Since we don't want this to fail due to a validation error with
    # a blank external ID, force the ID to the min value
    # if the external ID is not already set
    def during_create_master
      return unless creating_master
      return unless external_id.blank?

      self.external_id = self.class.external_id_range.min
    end

    def external_id_tests
      errors.add self.class.external_id_attribute, 'can not be blank' if external_id.blank?

      if persisted? && external_id_changed? && self.class.prevent_edit?
        errors.add self.class.external_id_attribute, 'can not be changed'
      end

      if persisted? && master_id_changed? && !master_id_was.nil?
        errors.add :master, "record this #{self.class.label} is associated with can not be changed"
      end

      if master_id.nil? && (!respond_to?(:admin_id) || admin_id.nil?)
        errors.add :master_id, "must be set when adding #{self.class.external_id_attribute}"
      end

      return unless external_id_changed? || !persisted?

      s = self.class.find_by_external_id(external_id)
      return unless s

      errors.add self.class.external_id_attribute, 'already exists in this master record' if s.master_id == master_id
      return if s.master_id == master_id || s.id == id

      errors.add self.class.external_id_attribute, "already exists in another master record (master ID: #{s.master_id})"
    end
  end
end
