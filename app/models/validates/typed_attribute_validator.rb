# frozen_string_literal: true

class Validates::TypedAttributeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    expected_type = record.class.typed_attribute_types[attribute]
    return if expected_type.nil?
    return if value.is_a?(expected_type)

    record.errors.add(attribute, :invalid_type,
                      message: "must be a #{expected_type.name}, got #{value.class.name}")
  end
end
