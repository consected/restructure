# frozen_string_literal: true

# Alternative IDs provide additional IDs for each master record.
# These may be provided directly on the masters table as crosswalk IDs,
# or they may be provided by ExternalIdentifier definitions.
# Either may be used interchangably for finding a master record, just by
# specifying the alternative ID field name to search against.
module AlternativeIds
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    #
    # Crosswalk attributes are those attributes on the masters table that can be
    # used as an alternative way to directly identify a master record (rather than primary key *id*)
    # We assume that any field that is not a 'standard' field can be used as
    # a crosswalk identifier.
    # @param [Boolean | nil] access_by - optional (and ignored), but consistent with others and may be use in the future
    # @return [Array{Symbol}]
    def crosswalk_attrs(access_by: nil)
      attribute_names.map(&:to_sym) - %i[id master_id user_id created_at updated_at rank created_by_user_id]
    end

    #
    # Does the attr_name correspond to a crosswalk attribute on the masters table?
    # If *access_by* is nil, no access controls are applied
    # NOTE: access_by is specified for consistency with other methods, but is not currently used.
    # It may be used to enforce access to specific attributes in the future.
    # @param [String | Symbol] attr_name
    # @param [User | nil] access_by - current user making the request.
    # @return [Boolean]
    def crosswalk_attr?(attr_name, access_by: nil)
      attr_name = attr_name.to_sym
      crosswalk_attrs(access_by: access_by).include?(attr_name)
    end

    #
    # Get the list of external identifier ID attributes (as symbols)
    # Filter the results based on user access controls if access_by is supplied.
    # This relies on already memoized data
    # @param [User | nil] access_by - the current user making the request or nil to ignore access controls
    # @return [Array{Symbol}] array of symbols representing the id field names
    def external_id_matching_fields(access_by: nil)
      results = if access_by
                  external_id_definitions_access_by(access_by)
                else
                  external_id_definitions
                end

      results.keys
    end

    #
    # Memoize a hash of the full set of active external identifier definitions
    # keyed by the alternative id attribute (as a symbol)
    # @return [Hash{Symbol => ExternalIdentifier}]
    def external_id_definitions
      return @external_id_definitions if @external_id_definitions

      @external_id_definitions = {}
      recs = ExternalIdentifier.active_model_configurations
      recs.each do |e|
        @external_id_definitions[e.external_id_attribute.to_sym] = e
      end

      @external_id_definitions
    end

    #
    # Memoize a hash of active external identifier definitions accessible by user
    # The hash result is keyed by the alternative id attribute (as a symbol)
    # @return [Hash{Symbol => ExternalIdentifier}]
    def external_id_definitions_access_by(access_by)
      key = access_by_key(access_by)
      if @external_id_definitions_access_by&.key?(key)
        user_results = @external_id_definitions_access_by[key]
      else
        @external_id_definitions_access_by ||= {}
        user_results = external_id_definitions.filter { |_k, v| access_by.has_access_to?(:access, :table, v.name) }
        @external_id_definitions_access_by[key] = user_results
      end
      user_results
    end

    #
    # Get the ExternalIdentifer definition for the named external_id_attribute
    # Returns nil if not matched
    # @param [String | Symbol] field_name
    # @param [User | nil] access_by
    # @return [ExternalIdentifier | nil]
    def external_id_definition(attr_name, access_by: nil)
      attr_name = attr_name.to_sym

      results = if access_by
                  external_id_definitions_access_by(access_by)
                else
                  external_id_definitions
                end

      results[attr_name]
    end

    # Force a reset of the external fields, allowing new definitions to appear
    def reset_external_id_matching_fields!
      @external_id_definitions_access_by = nil
      @external_id_definitions = nil
    end

    # Generate an instance method that allow easy access to alternative_id values
    # such as #scantron_id
    def add_alternative_id_method(attr_name)
      define_method attr_name.to_sym do
        alternative_id_value attr_name
      end
    end

    #
    # Does the attribute name correspond to an external id?
    # If *access_by* is nil, no access controls are applied
    # @param [String | Symbol] attr_name
    # @param [User | nil] access_by - current user making the request.
    # @return [Boolean]
    def external_id?(attr_name, access_by: nil)
      attr_name = attr_name.to_sym
      external_id_matching_fields(access_by: access_by).include? attr_name
    end

    # All alternative ID field names (as symbols)
    # @param [User] access_by - (optional) user making the request to apply access controls
    # @return [Array{Symbol}]
    def alternative_id_fields(access_by: nil)
      crosswalk_attrs(access_by: access_by) + external_id_matching_fields(access_by: access_by)
    end

    #
    # Does the attr_name correspond to an alternative ID field?
    # If *access_by* is nil, no access controls are applied
    # @param [String | Symbol] attr_name
    # @param [User | nil] access_by - current user making the request.
    # @return [Boolean]
    def alternative_id?(attr_name, access_by: nil)
      attr_name = attr_name.to_sym
      alternative_id_fields(access_by: access_by).include?(attr_name)
    end

    #
    # Find a master record using a named alternative ID and its value
    # @param [String | Symbol] field_name named alternative ID to match
    # @param [String | Integer] value to match
    # @param [User | Symbol] current_user controls access to external identifiers or :no_user to
    #   state that no user access control enforcement is required
    # @return [Master | nil] matched master record or nil if unmatched
    def find_with_alternative_id(field_name, value, current_user)
      return if value.blank?

      unless current_user.is_a?(User) || current_user == :no_user
        raise FphsException, 'find_with_alternative_id requires a current_user'
      end

      current_user = nil if current_user == :no_user

      field_name = field_name.to_sym

      unless alternative_id?(field_name, access_by: current_user)
        raise FphsException, "Can not match on this field (#{field_name}). " \
          'It is not an accepted alterative ID field for this user.'
      end

      # Start by attempting to match on a field in the master record
      return where(field_name => value).first if crosswalk_attr?(field_name)

      # No crosswalk field was found. Try an external ID instead
      unless external_id?(field_name, access_by: current_user)
        raise FphsException, 'The field specified is not valid for external identifier matching'
      end

      ei = ExternalIdentifier.class_for(field_name).find_by_external_id(value)
      ei&.master
    end

    #
    # Memoization key for the access_by user
    # @param [User] access_by
    # @return [String]
    def access_by_key(access_by)
      "#{access_by.id}--#{access_by.app_type_id}"
    end

    #
    # add the alternative_id_fields from the master as attributes, so we can use them for matching
    # @param [UserBase] in_class - the class to define the methods in
    def setup_resource_alternative_id_fields(in_class)
      # Check Master is ready to accept alternative id fields
      # since it may not be during loading
      if Master.respond_to? :alternative_id_fields
        alternative_id_fields.each do |f|
          #
          # Writer method like field_name_id=
          in_class.define_method :"#{f}=" do |value|
            if attribute_names.include? f.to_s
              write_attribute(f, value)
            else
              instance_variable_set("@#{f}", value)
              return master if master

              self.master = Master.find_with_alternative_id(f, value, :no_user)
            end
          end

          #
          # Reader method like field_name_id
          in_class.define_method :"#{f}" do
            if attribute_names.include? f.to_s
              read_attribute(f)
            else
              instance_variable_get("@#{f}")
            end
          end
        end
      else
        puts 'Master does not respond to alternative_id_fields. Hopefully this is just during seeding'
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
    @alternative_id_value ||= {}
    return @alternative_id_value[field_name] if @alternative_id_value.key? field_name

    # Start by attempting to match on a field in the master record
    unless self.class.alternative_id?(field_name, access_by: current_user)
      raise "Can not match on this field. It is not an accepted alterative ID field. #{field_name}"
    end

    @alternative_id_value[field_name] = attributes[field_name.to_s]
    return @alternative_id_value[field_name] if self.class.crosswalk_attr?(field_name, access_by: current_user)

    ext_id = self.class.external_id_definition(field_name, access_by: current_user)
    unless ext_id
      raise(FphsException,
            "External ID definition is not active for #{field_name}. Key: #{self.class.access_by_key(current_user)}")
    end

    @alternative_id_value[field_name] = self.class.external_id?(field_name, access_by: current_user)
    return unless @alternative_id_value[field_name]

    assoc_name = ext_id.model_association_name
    # Ensure the first item is used, since adding new IDs could lead to spurious results
    # Also check that the master has this association defined, as there are unusual situations where
    # this can cause unexpected errors
    m = send(assoc_name).reorder('').order(id: :asc).first if respond_to?(assoc_name)

    @alternative_id_value[field_name] = m&.external_id
  end

  #
  # Get a hash of all the alternative IDs and values for a master record
  # @return [Hash] a hash with symbol keys
  def alternative_ids
    return @alternative_ids if @alternative_ids

    res = {}
    self.class.alternative_id_fields(access_by: current_user).each { |f| res[f] = alternative_id_value(f) }
    @alternative_ids = res
  end
end
