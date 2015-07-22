class SourceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    
    
    list = GeneralSelection.item_type_name_value_pair(record)
    matches = (list.select {|a| a.last.downcase == value})
    unless value.blank? || matches.length > 0
      Rails.logger.info "Bad source for #{record} in list #{list}. Matches #{matches} with value #{value}"
      record.errors.add attribute, (options[:message] || "is not a valid Source") 
    end
  end
end