# frozen_string_literal: true

class Classification::GeneralSelection < ActiveRecord::Base
  # Handle general selection functionality, typically for looking up drop-down values from cache

  self.table_name = 'general_selections'

  include AdminHandler
  include SelectorCache
  BasicItemTypes = %i[player_infos_source
                      player_contacts_type player_contacts_source player_contacts_rank
                      addresses_type addresses_source addresses_rank].freeze

  default_scope { order item_type: :asc, disabled: :asc, position: :asc }

  before_validation :prevent_value_change, on: :update
  validates :name, presence: true
  validates :value, presence: true
  validate :not_duplicated

  def self.item_types(refresh: false)
    if refresh
      Rails.cache.delete('Classification::GeneralSelection.item_types')
      @implementation_classes = nil
    end
    Rails.cache.fetch('Classification::GeneralSelection.item_types') do
      BasicItemTypes +
        Report.item_types(refresh: refresh) +
        ActivityLog.item_types(refresh: refresh) +
        DynamicModel.item_types(refresh: refresh) +
        ExternalIdentifier.item_types(refresh: refresh)
    end
  end

  # Format the item type source string for looking up different selection types from the general_selections table
  def self.item_type_source_for(record, type = :source)
    record = record.new unless record.respond_to?(:class) && record.class != Class
    "#{prefix_name(record)}_#{type}"
  end

  # Get an array of name value pairs for a particular record, and the type of attribute it corresponds to
  def self.item_type_name_value_pair(record, type = :source)
    src = item_type_source_for record, type
    selector_name_value_pair(item_type: src)
  end

  # Quickly lookup the name for a general_selection record with a specific value, corresponding to a 'record',
  # with the type of attribute it corresponds to
  def self.name_for(record, value, type = :source)
    res = item_type_name_value_pair record, type

    resn = res.select { |l| l.last.to_s == value.to_s }
    return resn.first.first if resn.length >= 1

    nil
  end

  # Prefix name for a form field in a record
  # @param record [UserBase] a standard user record, typically a form_object_instance
  # @return [String]
  def self.prefix_name(record)
    if record.model_data_type == :activity_log
      record.item_type_us
    elsif record.model_data_type == :report
      "report_#{record.definition.name.id_underscore}"
    else
      record.item_type_us.pluralize
    end
  end

  # Quick check if a field in a record is a general selection type
  # @param record [UserBase] a standard UserBase instance, typically a form_object_instance in a view
  # @param field_name [String | Symbol] field name to check
  # @return [Boolean]
  def self.exists_for?(record, field_name)
    item_types.include?("#{prefix_name(record)}_#{field_name}".to_sym)
  end

  def self.implementation_classes
    # For each of the implementation classes that can provide form_options.edit_as.alt_options configurations
    @implementation_classes ||= ActivityLog.implementation_classes + DynamicModel.implementation_classes
  end

  #
  # Check if an attribute can have general selection entries added
  # This is based on the attribute names
  # @param [String] attr is the attribute name
  # @return [Boolean]
  def self.use_with_attribute? attr
    !attr.in?(%w[disabled user_id created_at updated_at]) && (
      attr.start_with?('select_') ||
      attr.start_with?('multi_select_') ||
      attr.end_with?('_selection') ||
      attr.in?(%w[source rec_type rank])
    )
  end

  # Get the general selection configurations and override them with the form_options.edit_as.alt_options
  # from dynamic model and activity log extra option type configurations.
  # If alt_options override an existing select_... field, the general selection records for this will
  # be removed from the results and the alt options will be used instead.
  # If alt_options appear for a field that is not a select_... then the new options will just be added
  # with the current field name. It is the responsibility of the client to see this.
  # This is used on the client side for the display of form values.
  # @param conditions [Hash] any conditions to be passed to retrieve the appropriate general selections
  # => conditions[:extra_log_type] states the extra log type in use if this is an activity log
  # => conditions[:item_type] states the item type to use
  # @return [Array] serializable array of general_selection and alt_options overrides
  def self.selector_with_config_overrides(conditions = nil)
    if conditions.is_a? Hash
      extra_log_type = conditions.delete(:extra_log_type)
      item_type = conditions.delete(:item_type)
    end

    # Get the underlying general selection data and make it into an array of results
    res = selector_collection(conditions)
    res = res.to_ary

    impl_classes = implementation_classes
    # Check the definition is ready to use and prepare it for use
    impl_classes.select! { |ic| ic.definition.ready_to_generate? }

    impl_classes = impl_classes.select { |ic| ic.new.item_type == item_type } if item_type
    impl_classes.each do |itc|
      ito = itc.new

      # If an extra log type was specified, use it, since the overrides may be different than the defaults
      if extra_log_type && ito.respond_to?(:extra_log_type)
        ito.extra_log_type = extra_log_type
      else
        extra_log_type = nil
      end

      it = prefix_name(ito)

      if item_type
        its = ito.attribute_names.map { |a| "#{it}_#{a}" }
        res = res.select { |r| r[:item_type].in? its }
      end

      # Get the option overrides
      oo = option_overrides ito

      next unless oo

      # Overrides were found for this implementation.
      # Run through each field that has an override
      # remove the existing general_selection results that match the item_type (if any)
      # and add in the new options
      oo.each do |fn, fo|
        n = fn

        gsit = "#{it}_#{n}"
        res.reject! { |r| r[:item_type] == gsit }

        o = fo[:edit_as][:alt_options]
        # If the options are an array, make them into a hash for consistency
        unless o.is_a? Hash
          newo = {}
          o.each do |oi|
            newo[oi] = oi
          end
          o = newo
        end

        o.each do |k, v|
          res << {
            id: nil,
            item_type: gsit,
            name: k,
            value: v,
            create_with: nil,
            edit_if_set: nil,
            edit_always: true,
            lock: nil
          }
        end
      end
    end

    res
  end

  # Cached version of the general selections and config overrides (alt_options)
  # as a hash of arrays
  def self.field_selections
    Rails.cache.fetch('field_selections_hash') do
      res = {}
      selector_with_config_overrides.each do |s|
        item_type = s[:item_type].to_sym
        res[item_type] ||= []
        res[item_type] << s
      end
      res
    end
  end

  # Cached version of the general selections and config overrides (alt_options)
  # as a hash of hashes
  def self.field_selections_hashes
    Rails.cache.fetch('field_selections_hash_of_hashes') do
      res = {}
      selector_with_config_overrides.each do |s|
        item_type = s[:item_type].to_sym
        res[item_type] ||= {}
        res[item_type][s[:value]] = s
      end
      res
    end
  end

  # Get the form_options.edit_as.alt_options configurations for a specific item type object
  # which can be a simple new and uninitialized dynamic model or activity log.
  # For activity logs, generally the extra_log_type attribute is set, allowing the appropriate
  # configuration to be pulled.
  # @return [Hash | nil] returns the edit_as configurations per field, or nil if there are none
  def self.option_overrides(item_type_object)
    if item_type_object.model_data_type.in?(%i[activity_log dynamic_model])
      fndefs = item_type_object.option_type_config.field_options.select { |_fn, f| f && f[:edit_as] && f[:edit_as][:alt_options] }
      return if fndefs.empty?

      return fndefs
    end
    nil
  end

  protected

  def prevent_value_change
    if value_changed? && persisted?
      errors.add(:value, 'change not allowed!')
      # throw(:abort)

    end
    if item_type_changed? && persisted?
      errors.add(:item_type, 'change not allowed!')
      # throw(:abort)
    end
  end

  private

  def not_duplicated
    return true if disabled?

    if already_taken(:item_type, :value)
      errors.add :duplicated, "existing general selection with item type #{item_type} and value #{value}"
    end

    true
  end
end
