# frozen_string_literal: true

module Formatter
  #
  # Handle formatting of data by adding a Luhn checksum to it, to allow subsequent checking
  module Checksum
    def self.format(data, _options = nil)
      return unless data.present?

      res = checksum(data)
      "#{data}#{res}"
    end

    #
    # Calculate the Luhn checksum number for an integer or string representing an integer
    # @param [Integer | String] number
    # @return [Intger]
    def self.checksum(number)
      digits = number.to_s.reverse.split('').map(&:to_i)
      digits = digits.each_with_index.map do |d, i|
        d *= 2 if i.even?
        d > 9 ? d - 9 : d
      end
      sum = digits.sum
      mod = 10 - sum % 10
      mod == 10 ? 0 : mod
    end

    #
    # Validate a number includes a valid checksum digit
    # @param [Integer | String] number
    # @return [Boolean]
    def self.number_valid?(number)
      return if number.blank?

      snum = number.to_s
      checksum(snum[0..-2]) == snum.last.to_i
    end

    def self.format_error_message(_data = nil)
      'Check the number is valid.'
    end
  end
end
