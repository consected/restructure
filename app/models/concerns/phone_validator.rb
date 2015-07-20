class PhoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || "is not a valid phone number") unless
      value =~ /\([0-9]{3}\)[0-9]{3}-[0-9]{4}.*/i
  end
end