class ZipValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || "is not a valid ZIP") unless
      value =~ /^[0-9]{5}$/i
  end
end