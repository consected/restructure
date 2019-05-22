module Formatter
  module Phone

    # Format a phone number to US format: "(aaa)bbb-cccc[ optional-freetext]"
    def self.format data, options=nil
      unless data.blank?
        res = '('
        num = 0
        data.chars.each do |s|

          if num == 10
            # we already have 10 digits, the remaining amount is plain text. Separate it with a space
            res << ' '
            res << s unless s.blank?
            num += 1
          elsif num > 10
            # handle the plain text
            res << s
            num += 1
          elsif s.to_i.to_s == s
            # the character is a digit
            res << s
            num += 1

            res << ')' if num == 3
            res << '-' if num == 6
          elsif !s.index(/[[[:punct:]]\s]/)
            # it wasn't whitespace or punctuation
            return nil
          end
          # we reject the items that aren't digits in while we are looking for the first 10
        end
        if num >= 10
          return res
        end
      end
      nil
    end

    def self.format_error_message data=nil
      "Check phone number is at least 10 digits and does not contain incorrect characters."
    end


  end
end
