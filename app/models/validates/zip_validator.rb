class Validates::ZipValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || message) unless value_is_valid?(value)
  end

  def message
    "is not a valid ZIP"
  end

  def value_is_valid? value
      value =~ /^[0-9]{5}(-[0-9]{4})?$/i
  end
end
