# frozen_string_literal: true

module AlternativeIds
  extend ActiveSupport::Concern

  included do
    @stored_external_id_matching_fields = nil
  end

  class_methods do
    def crosswalk_attrs
      attribute_names.map(&:to_sym) - %i[id master_id user_id created_at updated_at rank]
    end

    def external_id_matching_fields
      # Cache the result, because it speeds up template use of ids hugely
      return @stored_external_id_matching_fields if @stored_external_id_matching_fields

      @stored_external_id_matching_fields = ExternalIdentifier.active_model_configurations.map { |f| f.external_id_attribute.to_sym }
    end

    # Force a reset of the external fields, allowing new definitions to appear
    def reset_external_id_matching_fields!
      @stored_external_id_matching_fields = nil
    end

    def external_id?(attr_name)
      external_id_matching_fields.include? attr_name
    end

    def alternative_id_fields
      crosswalk_attrs + external_id_matching_fields
    end

    def external_id_definition(attr_name)
      ExternalIdentifier.active.where(external_id_attribute: attr_name).first
    end

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
        raise 'The field specified is not valid for external identifier matching'
      end
    end
  end

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

    if self.class.external_id_matching_fields.include?(field_name.to_sym)
      m = send(assoc_name).first
      return unless m

      m.external_id
    end
  end

  def alternative_ids
    res = {}
    self.class.alternative_id_fields.each { |f| res[f] = alternative_id_value(f) }
    res
  end
end
