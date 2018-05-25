class Validates::PhoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || message) unless value_is_valid?(value)
  end

  def message
    "is not a valid phone number"
  end

  def value_is_valid? value
    value =~ /\([0-9]{3}\)[0-9]{3}-[0-9]{4}.*/i
  end
end
