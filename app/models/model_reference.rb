# frozen_string_literal: true

# Model references provide a generic mechanism for recording the relationship from a parent "from-record"
# or master record alone, to a configured "to-record".
# Model references are used instead of direct foreign key associations, since they allow configurations for new
# relationships to be added over time without disrupting data tables, and perhaps more importantly allow multiple
# from-records to point to a single to-record.
# The flexible nature of model references comes at a cost. Database level joins between records
# must be performed through the model_references table, which can lead to complex queries and reduced performance.
# There is a plan to allow certain activity logs / dynamic models to represent references directly through
# traditional foreign key relationships, extending the existing model references functionality to provide
# a consistent mechanism for app functionality to find referenced records, independent of mechanism used.
class ModelReference < ActiveRecord::Base
  belongs_to :user

  belongs_to :from_record, polymorphic: true, optional: true
  belongs_to :to_record, polymorphic: true, optional: true

  alias from_record_assoc from_record
  alias to_record_assoc to_record

  scope :active, -> { where 'model_references.disabled is null or model_references.disabled = false' }

  validates :from_record_master_id, presence: true
  # Validations on from_record can not be enforced, since we want to allow reference from master only
  # validates :from_record_id, presence: true
  # validates :from_record_type, presence: true
  validates :to_record_id, presence: true
  validates :to_record_type, presence: true
  validates :to_record_master_id, presence: true, unless: -> { to_record_class.no_master_association || disabled }
  validates :user_id, presence: true
  validate :allows_disable, if: -> { disabled }
  validate :allows_create, if: -> { !persisted? }

  after_save :handle_disabled, if: -> { disabled }
  after_save :reset_memos
  after_create :set_created

  attr_accessor :current_user, :force_create
  attr_writer :to_record

  def self.default_ref_order
    { id: :asc }
  end

  # Create an item referenced from a specific from_item
  # TODO consider if there is a significant race condition that we should be concerned about
  def self.create_with(from_item, to_item, force_create: false)
    m = ModelReference.where from_record_type: from_item.class.name,
                             from_record_id: from_item.id,
                             from_record_master_id: from_item.master_id,
                             to_record_type: to_item.class.name,
                             to_record_id: to_item.id,
                             to_record_master_id: to_item.master_id

    return unless m.limit(1).empty?

    from_item.reset_model_references if from_item.respond_to? :model_references
    ModelReference.create! from_record_type: from_item.class.name,
                           from_record_id: from_item.id,
                           from_record_master_id: from_item.master_id,
                           to_record_type: to_item.class.name,
                           to_record_id: to_item.id,
                           to_record_master_id: to_item.master_id,
                           user: to_item.master_user,
                           current_user: to_item.master_user,
                           force_create: force_create
  end

  # Create a reference from a master only, not an individual item.
  def self.create_from_master_with(from_master, to_item, force_create: false)
    ModelReference.create! from_record_type: nil,
                           from_record_id: nil,
                           from_record_master_id: from_master.id,
                           to_record_type: to_item.class.name,
                           to_record_id: to_item.id,
                           to_record_master_id: to_item.master_id,
                           user: to_item.master_user,
                           current_user: to_item.master_user,
                           force_create: force_create
  end

  # Find the configuration of the creatable reference for the pair of records representing a ModelReference
  # @return [Hash | nil] nil if there is no match or a Hash like
  #         {:label=>"Tech Contacts", :from=>"this", :add=>"many",
  #           :view_as=>{:show=>"not_embedded", :edit=>"select_or_add", :new=>"select_or_add"},
  #           :to_record_label=>"Tech Contacts", :no_master_association=>false}
  def self.find_creatable_config_for(from_item, to_item)
    begin
      return unless from_item

      fr = from_item
      fr.current_user = to_item.master_user

      cmr = fr.creatable_model_references
      if cmr
        cm = cmr.select { |_k, v| v.first.last[:ref_type] == to_item.class.name.ns_underscore.to_sym }.first
        config = cm.last.first.last[:ref_config] if cm
      end
    rescue StandardError => e
      Rails.logger.info "find_creatable_config_for raised an exception: #{e.inspect}\n#{e.backtrace.join('/n')}"
      return nil
    end
    config
  end

  # Find the configuration of the reference for this instance
  # @return [Hash | nil] nil if there is no match or a Hash like
  #         {:label=>"Tech Contacts", :from=>"this", :add=>"many",
  #           :view_as=>{:show=>"not_embedded", :edit=>"select_or_add", :new=>"select_or_add"},
  #           :to_record_label=>"Tech Contacts", :no_master_association=>false}
  def find_config
    begin
      mr = from_record&.option_type_config&.references

      if mr && to_record
        m = mr[to_record_result_key.pluralize.to_sym] || mr[to_record_result_key.to_sym]
        m = m.first.last if m
        config = m
      end
    rescue StandardError => e
      Rails.logger.info "find_creatable_config_for raised an exception: #{e.inspect}\n#{e.backtrace.join('/n')}"
      return nil
    end
    config
  end

  # Find the configuration of the creatable reference for this instance
  # @return [Hash | nil]
  def find_creatable_config
    self.class.find_creatable_config_for from_record, to_record
  end

  #
  # Lookup items referenced from the current item or master,
  # optionally filtering by a record type. After finding the references
  # each of the 'to records' are instantiated and returned in an array
  # @param [UserBase | Master] from_item_or_master
  # @param [String|nil] record_type (optional) fully qualified class name for to record type
  # @return [Array{UserBase}] instantiated items
  def self.find_referenced_items(from_item_or_master, record_type: nil)
    mrs = find_references from_item_or_master, to_record_type: record_type
    res = []
    mrs.each do |m|
      rec = m.to_record
      rec.master.current_user = from_item_or_master.master_user
      res << rec
    end
    res
  end

  # Find referenced items belonging to either an item or a master record
  # If belonging to an item, the results may be further limited to those with a to_record_type
  # If belonging to a master record, the to_record_type must be specified.
  # These can be further limited by a filter_by condition on the to_record,
  # allowing for specific records to be selected from the master (such as a specific 'type' of referenced record)
  # The param active == true returns only results that are not disabled
  # order_by forces ordering against fields in the target (ro_record) records
  def self.find_references(from_item_or_master,
                           to_record_type: nil,
                           filter_by: nil,
                           without_reference: false,
                           ref_order: nil,
                           active: nil,
                           order_by: nil,
                           ref_created_by_user: nil)

    ref_order ||= default_ref_order
    filter_by = substitute_filter(filter_by, from_item_or_master)

    if to_record_type
      to_record_type_class = to_record_class_for_type(to_record_type)
      to_record_type = to_record_type_class.name if to_record_type_class
    end

    if ref_created_by_user
      from_record_type = from_item_or_master.class.name
      from_record_id = from_item_or_master.id

      without_reference = true
      filter_by ||= {}
      if ref_created_by_user == 'user_is_creator'
        filter_by.merge! created_by_user_id: from_item_or_master.current_user.id
      end
    end

    if without_reference
      if to_record_type_class.respond_to?(:master) && from_item_or_master &&
         !ref_created_by_user && without_reference != 'outside_master'
        cond = { master: from_item_or_master }
      end
      cond ||= {}
      cond.merge!(filter_by) if filter_by

      recs = to_record_type_class.where(cond).order(ref_order)
      recs = recs.active if active
      res = []
      recs.each do |r|
        res << ModelReference.new(from_record_type: from_record_type,
                                  from_record_id: from_record_id,
                                  from_record_master_id: from_item_or_master.id,
                                  to_record_type: r.class.name,
                                  to_record_id: r.id,
                                  to_record_master_id: r.master_id,
                                  current_user: from_item_or_master.current_user)
      end
    elsif from_item_or_master.is_a? Master
      res = ModelReference.find_records_in_master to_record_type: to_record_type,
                                                  master: from_item_or_master,
                                                  filter_by: filter_by,
                                                  active: active
    else
      cond = { from_record_type: from_item_or_master.class.name, from_record_id: from_item_or_master.id }
      cond[:to_record_type] = to_record_type if to_record_type

      mr = ModelReference
      if filter_by || order_by
        item_name = to_record_type.ns_underscore.pluralize
        tn = ModelReference.record_type_to_table_name(item_name)
        ij = "INNER JOIN #{tn} ON model_references.to_record_id = #{tn}.id"
        mr = mr.joins(ij)
      end

      cond.merge! tn => filter_by if filter_by
      ref_order = order_by if order_by

      res = mr.where(cond).order(ref_order)
      res = res.active if active
      res = res.preload(:from_record)
    end

    # Set the current user, so that access controls can be correctly applied
    mu = if from_item_or_master.respond_to? :master_user
           from_item_or_master.master_user
         else
           from_item_or_master.current_user
         end

    res.each do |r|
      r.current_user ||= mu
    end
    res
  end

  # Find referenced items belonging to a master record
  # whether or not they belong to a specific instance (from_record_id) too.
  # These can be further limited by a filter_by condition on the to_record,
  # allowing for specific records to be selected from the master (such as a specific 'type' of referenced record)
  # The param active == true returns only results that are not disabled
  # order_by forces ordering against fields in the target (ro_record) records
  def self.find_records_in_master(master: nil, to_record_type: nil, filter_by: nil,
                                  ref_order: default_ref_order, active: nil)
    res = []
    cond = { master: master }
    filter_by = substitute_filter(filter_by, master)
    cond.merge! filter_by if filter_by

    to_record_class_for_type(to_record_type).where(cond).order(ref_order).each do |i|
      recs = ModelReference.where from_record_master_id: master.id,
                                  to_record_type: to_record_type,
                                  to_record_id: i.id,
                                  to_record_master_id: i.master_id
      recs = recs.active if active
      rec = recs.first
      if rec
        rec.to_record = i
        res << rec
      end
    end

    res
  end

  #
  # Find the model references that point to the to_item
  # @param [UserBase] to_item
  # @return [ActiveRecord::Relation]
  def self.find_references_to(to_item)
    cond = { to_record_type: to_item.class.name, to_record_id: to_item.id }
    ModelReference.where cond
  end

  #
  # Return all the objects that refer to the to_item through model references
  # @param [UserBase] to_item
  # @return [Array{UserBase}]
  def self.find_where_referenced_from(to_item)
    res = find_references_to(to_item)
    # Set the current user, so that access controls can be correctly applied
    mu = if to_item.respond_to? :master_user
           to_item.master_user
         else
           to_item.current_user
         end
    res.each do |r|
      r.current_user ||= mu
    end
    res
  end

  #
  # Model reference *filter:* definition allows substitutions
  # @param [Hash] filter - definition (duped to avoid accidental change)
  # @param [UserBase] data - to use for substitutions
  # @return [Hash] returns updated filter hash
  def self.substitute_filter(filter, data)
    filter = filter.dup
    if filter.is_a? Hash
      filter.each do |k, v|
        if v.is_a?(String) && v.include?('{{')
          filter[k] = Formatter::Substitution.substitute(v, data: data, ignore_missing: true)
        end
      end
    end
    filter
  end

  #
  # Takes a string representing a record type and generates the class.
  # This utility method is used widely
  # @param [String] rec_type - namespace underscored representation of the name
  # @return [UserBase] resulting class
  def self.to_record_class_for_type(rec_type)
    rec_type.ns_camelize.constantize
  rescue NameError => e
    Rails.logger.error "Attempt to get to_record_class_for_type #{rec_type} failed as the type does not exist.\n"\
                        "#{e.backtrace[0..20].join("\n")}"
    nil
  end

  #
  # Params are provided for singularize and pluralize to highlight the fact that otherwise we rely on the data that is
  # passed in and don't enforce it one way or another.
  # This means that if a singular record_type is passed in, the result is may not truly be a table name,
  # since the result will be singular unless explicitly pluralized.
  # This is required, since dynamic models may use singular table names
  def self.record_type_to_ns_table_name(record_type, pluralize: nil, singularize: nil)
    if record_type.is_a?(String) || record_type.is_a?(Symbol)
      res = record_type.to_s
    elsif record_type.respond_to? :name
      res = record_type.name.ns_underscore
    elsif record_type.respond_to? :class
      res = record_type.class.name.ns_underscore
    end

    return unless res

    res = res.sub('dynamic_model__', '')

    return res.pluralize if pluralize

    return res.singularize if singularize

    res
  end

  #
  # @see ModelReference.record_type_to_ns_table_name
  # The result has double underscores removed, to truly represent a DB table name
  # NOTE: it relies on the pluralization of the record type to be correct
  def self.record_type_to_table_name(record_type)
    record_type_to_ns_table_name(record_type).gsub('__', '_')
  end

  #
  # Convert a string, class or instance to a symbol association name
  # The result is checked to ensure Master actually includes this association
  # @param [Object] record_type - one of many representations
  # @return [Symbol | nil] - master association name as a symbol
  def self.record_type_to_assoc_sym(record_type)
    if record_type.is_a?(String) || record_type.is_a?(Symbol)
      res = record_type.to_s
    elsif record_type.respond_to? :name
      res = record_type.name.ns_underscore
    elsif record_type.respond_to? :class
      res = record_type.class.name.ns_underscore
    else
      return
    end

    assoc = res.pluralize
    return assoc.to_sym if Master.get_all_associations.include?(assoc)

    raise FphsException,
          "record_type_to_assoc_sym produced an association #{assoc} not recognized by Master"
  end

  #
  # Allow model references to be created without checking user access allows it
  def force_create?
    @force_create
  end

  def item_type
    'model_reference'
  end

  def to_record_class
    to_record_type.camelize.constantize
  end

  def to_record_label
    to_record_options_config && to_record_options_config[:result_label] || to_record.human_name
  end

  def to_record_type_us
    to_record_type.ns_underscore
  end

  def to_record_type_us_plural
    to_record_type.ns_underscore.pluralize
  end

  def to_record_short_type_us
    to_record_type.split('::').last.ns_underscore
  end

  def to_record_resource_name
    to_record.resource_name
  end

  #
  # Check if the to-record is viewable, based on table user access controls only.
  # @todo - Consider whether this should be extended to include option config showable_if rules
  def to_record_viewable
    return @to_record_viewable unless @to_record_viewable.nil?

    @to_record_viewable = !!current_user.has_access_to?(:access, :table, to_record_type_us.pluralize)
  end

  #
  # Is the to-record editable based on user access controls and editable_as option configuration
  # Memoized to allow repetitive calls.
  # @return [Boolean]
  def to_record_editable
    return @to_record_editable unless @to_record_editable.nil?

    @to_record_editable = !!current_user.has_access_to?(:edit, :table, to_record_type_us.pluralize)
    return unless @to_record_editable

    if to_record.respond_to?(:can_edit?)
      to_record.current_user ||= current_user
      @to_record_editable = !!to_record.can_edit?
    else
      @to_record_editable
    end
  end

  def from_record_type_us
    return unless from_record_type

    from_record_type.ns_underscore
  end

  def from_record_short_type_us
    return unless from_record_type

    from_record_type.split('::').last.ns_underscore
  end

  #
  # Is the from-record viewable based on table user access controls only
  # This method appears to be unused
  # @todo - evaluate if this should be extended to
  # check access more granularly (showable_if config) before use.
  def from_record_viewable
    return unless from_record_type_us

    !!current_user.has_access_to?(:access, :table, from_record_type_us.pluralize)
  end

  #
  # The actual instance a model reference the from_record_type/id corresponds to
  # @return [UserBase | nil] - returns nil if from_record_type/id are not set
  def from_record
    return @from_record if @from_record
    return unless from_record_type && from_record_id

    @from_record = from_record_assoc
    # @from_record = from_record_type.ns_constantize.find(from_record_id)
    @from_record.current_user ||= current_user
    @from_record
  end

  def to_record_data
    to_record.data if to_record_viewable
  end

  #
  # The actual instance a model reference points to with
  # the to_record_type/id
  # @return [UserBase]
  def to_record
    return @to_record if @to_record

    # @to_record = to_record_class.find(to_record_id)
    @to_record = to_record_assoc

    unless @to_record
      raise FphsException, "Model Reference (#{id}) 'to record' not found: #{to_record_class} #{to_record_id}"
    end

    @to_record.current_user ||= current_user
    @to_record.parent_item = from_record if to_record.respond_to?(:parent_item)
    @to_record
  end

  #
  # A 'key' used by the front end to identify the parent instance and form that this result actually belongs to
  def to_record_result_key
    return "#{to_record_type_us}_#{to_record.extra_log_type}" if to_record.respond_to? :extra_log_type

    to_record_type_us
  end

  #
  # Helps the front end identify which template should be used to render this result
  def to_record_template
    return "#{to_record_type_us}_#{to_record.extra_log_type}" if to_record.respond_to? :extra_log_type

    to_record_short_type_us
  end

  # Name of the association from the master
  def to_record_assoc_name
    @to_record_assoc_name ||= to_record_class.assoc_inverse
  end

  #
  # Configuration for model reference (as defined in the from-record's option config)
  # corresponding to the to-record.
  # @return [Hash | nil]
  def to_record_options_config
    return unless from_record.respond_to?(:option_type_config)

    res = from_record&.option_type_config&.model_reference_config(self)
    return unless res

    res[to_record_assoc_name.to_s.singularize.to_sym]
  end

  # The reference can be disabled if:
  # the from record can be edited (if the from record is set) OR allow_disable_if_not_editable is set
  # AND
  #   the prevent_disable option is not set
  #   OR
  #   the prevent_disable options is a Hash and the calculated if resolves to false
  def can_disable
    return @can_disable unless @can_disable.nil?

    c = find_config || {}
    if from_record && c.is_a?(Hash) && from_record.respond_to?(:option_type_config) && from_record.option_type_config
      pd = from_record.option_type_config.calc_reference_if c, :prevent_disable, to_record
      ane = from_record.option_type_config.calc_reference_if c, :allow_disable_if_not_editable, to_record
    else
      pd = false
      ane = false
    end

    @can_disable = (!pd && (!from_record || ane || from_record.can_edit?))
  end

  # Ensures that parent records are updated in the UI if a change has been made to the reference, such as disabling it
  def referenced_from
    [{
      from_record_master_id: from_record_master_id,
      from_record_type_us: from_record_type_us,
      from_record_id: from_record_id
    }]
  end

  def _updated
    @was_updated
  end

  def _created
    @was_created
  end

  def as_json(extras = {})
    extras[:methods] ||= []
    extras[:methods] << :to_record_id
    extras[:methods] << :to_record_master_id
    extras[:methods] << :to_record_type
    extras[:methods] << :to_record_resource_name
    extras[:methods] << :to_record_type_us
    extras[:methods] << :to_record_type_us_plural
    extras[:methods] << :to_record_short_type_us
    extras[:methods] << :to_record_label
    extras[:methods] << :to_record_viewable
    extras[:methods] << :to_record_editable

    extras[:methods] << :to_record_data

    extras[:methods] << :to_record_options_config
    extras[:methods] << :from_record_type_us
    extras[:methods] << :from_record_short_type_us
    extras[:methods] << :from_record_viewable
    extras[:methods] << :to_record_result_key
    extras[:methods] << :to_record_template
    extras[:methods] << :item_type
    extras[:methods] << :can_disable
    extras[:methods] << :referenced_from
    extras[:methods] << :_updated
    extras[:methods] << :_created

    # Don't return the full referenced object
    super(extras)
  end

  private

  #
  # Validation method enforcing the can_disable rule for the model reference
  # with a validation error if can not disable.
  # @return [true | nil]
  def allows_disable
    unless can_disable
      errors.add :disable, 'of this reference is not allowed'
      return
    end
    true
  end

  #
  # Validation method enforcing a compount rule for the model reference
  # based on can_edit? and can_add_reference? on the from-record
  # with a validation error if can not disable.
  # The #force_create? method is checked to see if these checks should be disregarded,
  # allowing save triggers to create references from items that a front-end user does not
  # have permission to create from.
  # @return [true | nil]
  def allows_create
    return true unless from_record

    unless force_create? || from_record.can_edit? || from_record.can_add_reference?
      errors.add :reference,
                 'can not be created from a read-only parent '\
                 "(from: #{from_record_type} "\
                 "id: #{from_record_id} "\
                 "to: #{to_record_type}) => ("\
                 "force? #{!!force_create?} || "\
                 "edit? #{!!from_record.can_edit?} || "\
                 "add reference? #{!!from_record.can_add_reference?})"
    end
    true
  end

  #
  # Handles the situation when a model reference is disabled, checking the configuration
  # if the to-record should also be disabled, and if so disabling it.
  def handle_disabled
    @was_updated = 'updated'
    return true unless saved_change_to_disabled?

    troc = to_record_options_config
    to_record.model_reference_disable if troc && troc[:also_disable_record]
  end

  #
  # On save, reset the from_record's memos, if it is set. If we have created a record from a master
  # then the caller will need to handle this itself.
  def reset_memos
    return unless from_record

    from_record.reset_model_references if from_record.respond_to?(:reset_model_references)
  end

  #
  # Simply set an attribute flag if the model reference was just created
  # @return [String]
  def set_created
    @was_created = 'created'
  end
end
