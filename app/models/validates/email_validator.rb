class Validates::EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || message) unless value_is_valid?(value)
  end

  def message
    "is not an email"
  end

  def value_is_valid? value
    value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  end
end
