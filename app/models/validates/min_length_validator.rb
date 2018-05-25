class Validates::MinLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || message) unless value_is_valid?(value)
  end

  def message
    "minimum length: #{options[:min_length]}"
  end

  def value_is_valid? value
    value.length >= options[:min_length]
  end
end
