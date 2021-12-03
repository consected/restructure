# frozen_string_literal: true

class Validates::SourceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || neg_message) unless value_is_valid?(value, record)
  end

  def neg_message
    'is not a valid source'
  end

  def message
    'a valid source'
  end

  def value_is_valid?(value, record)
    return true if value.blank?

    list = Classification::GeneralSelection.item_type_name_value_pair(record)
    matches = (list.select { |a| a.last.downcase == value })
    matches.present?
  end
end
