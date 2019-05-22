module Formatter
  module Email

    # Ensure an email is nil if blank
    def self.format data, options=nil
      unless data.blank?
        return data
      end
      nil
    end

    def self.format_error_message data=nil
      "Check email address is a valid format."
    end



  end
end
