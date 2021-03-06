class Validates::ZipValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || neg_message) unless value_is_valid?(value)
  end

  def neg_message
    "is not a valid ZIP"
  end

  def message
    "a valid ZIP"
  end

  def value_is_valid? value, record=nil
      value =~ /^[0-9]{5}(-[0-9]{4})?$/i
  end
end
