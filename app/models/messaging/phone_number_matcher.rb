# frozen_string_literal: true

module Messaging
  class PhoneNumberMatcher
    def initialize(country_code:, trunk_number:)
      @country_code = digits_only(country_code)
      @trunk_number = digits_only(trunk_number)
    end

    def national(value)
      original = value.to_s
      digits = digits_only(original)
      return if digits.blank?

      if original.start_with?('+') && @country_code.present? && digits.start_with?(@country_code)
        digits = digits.delete_prefix(@country_code)
      end
      return if digits.blank?

      if @trunk_number.present? && digits.start_with?(@trunk_number) && digits.length > @trunk_number.length
        digits = digits.delete_prefix(@trunk_number)
      end

      digits
    end

    def candidates(value)
      number = national(value)
      return [] unless number

      [number, "#{@trunk_number}#{number}", "#{@country_code}#{number}"].uniq
    end

    private

    def digits_only(value)
      value.to_s.sub(/(?:\s+ext(?:ension)?\.?|\s+x|#)\s*\d+\s*\z/i, '').gsub(/[^0-9]/, '')
    end
  end
end
