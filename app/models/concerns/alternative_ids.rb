# frozen_string_literal: true

# Alternative IDs provide additional IDs for each master record.
# These may be provided directly on the masters table as crosswalk IDs,
# or they may be provided by ExternalIdentifier definitions.
# Either may be used interchangably for finding a master record, just by
# specifying the alternative ID field name to search against.
module AlternativeIds
  extend ActiveSupport::Concern

  included do
    @stored_external_id_matching_fields = nil
  end

  class_methods do
    # Crosswalk attributes are those attributes on the masters table that can be
    # used as an alternative way to directly identify a master record
    # We assume that any field that is not a 'standard' field can be used as
    # a crosswalk identifier.
    def crosswalk_attrs
      attribute_names.map(&:to_sym) - %i[id master_id user_id created_at updated_at rank]
    end

    # Does the attr_name correspond to a crosswalk attribute on the masters table?
    def crosswalk_attr?(attr_name)
      attr_name = attr_name.to_sym
      crosswalk_attrs.include?(attr_name)
    end

    # Get (and memoize) the list of external identifier ID attributes (as symbols)
    def external_id_matching_fields
      # Cache the result, because it speeds up template use of ids hugely
      return @stored_external_id_matching_fields if @stored_external_id_matching_fields

      @stored_external_id_matching_fields = ExternalIdentifier.active_model_configurations.map { |f| f.external_id_attribute.to_sym }
    end

    # Force a reset of the external fields, allowing new definitions to appear
    def reset_external_id_matching_fields!
      @stored_external_id_matching_fields = nil
    end

    # Generate an instance method that allow easy access to alternative_id values
    # such as #scantron_id
    #
    def add_alternative_id_method(attr_name)
      define_method attr_name.to_sym do
        alternative_id_value attr_name
      end
    end

    # Does the attribute name correspond to an external id?
    def external_id?(attr_name)
      attr_name = attr_name.to_sym
      external_id_matching_fields.include? attr_name
    end

    # All alternative ID field names (as symbols)
    # @return [Array]
    def alternative_id_fields
      crosswalk_attrs + external_id_matching_fields
    end

    # Does the attr_name correspond to an alternative ID field?
    def alternative_id?(attr_name)
      attr_name = attr_name.to_sym
      alternative_id_fields.include?(attr_name)
    end

    #
    # Get the ExternalIdentifer definition for the named external_id_attribute
    # Returns nil if not matched
    # @param [String] field_name
    # @return [ExternalIdentifier | nil]
    def external_id_definition(attr_name)
      return @external_id_definition[attr_name] if @external_id_definition&.key?(attr_name)

      @external_id_definition ||= {}
      @external_id_definition[attr_name] = ExternalIdentifier.active.where(external_id_attribute: attr_name).first
    end

    #
    # Find a master record using a named alternative ID and its value
    # @param [String | Symbol] field_name named alternative ID to match
    # @param [String | Integer] value to match
    # @return [Master | nil] matched master record or nil if unmatched
    def find_with_alternative_id(field_name, value)
      return if value.blank?

      field_name = field_name.to_sym
      # Start by attempting to match on a field in the master record
      unless alternative_id_fields.include?(field_name)
        raise "Can not match on this field. It is not an accepted alterative ID field. #{field_name}"
      end
      return where(field_name => value).first if attribute_names.include?(field_name.to_s)

      # No master record field was found. So try an external ID instead
      if external_id_matching_fields.include?(field_name.to_sym)
        ei = ExternalIdentifier.class_for(field_name).find_by_external_id(value)
        ei&.master
      else
        raise FphsException, 'The field specified is not valid for external identifier matching'
      end
    end
  end

  #
  # Get the value of a master record's alternative ID
  # If there are crosswalk IDs in the masters table, see if field_name matches one of these
  # and get its value.
  # Alternatively, the field_name matches the name of an external identifier ID field ending with _id
  # If no matching ID fields are found, return nil
  # @param [String | Symbol] field_name is the name of the external identifier field to get
  # @return [String | Integer | nil]
  def alternative_id_value(field_name)
    field_name = field_name.to_sym
    # Start by attempting to match on a field in the master record
    unless self.class.alternative_id_fields.include?(field_name)
      raise "Can not match on this field. It is not an accepted alterative ID field. #{field_name}"
    end

    return attributes[field_name.to_s] if self.class.crosswalk_attrs.include?(field_name)

    eid = self.class.external_id_definition(field_name)
    raise(FphsException, "External ID definition is not active for #{field_name}") unless eid

    assoc_name = eid.model_association_name

    return unless self.class.external_id_matching_fields.include?(field_name.to_sym)

    # Ensure the first item is used, since adding new IDs could lead to spurious results
    m = send(assoc_name).order(id: :asc).first
    return unless m

    m.external_id
  end

  #
  # Get a hash of all the alternative IDs and values for a master record
  # @return [Hash] a hash with symbol keys
  def alternative_ids
    res = {}
    self.class.alternative_id_fields.each { |f| res[f] = alternative_id_value(f) }
    res
  end
end
