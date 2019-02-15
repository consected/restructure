module ESignature
  class TimeFormatting

    # @return [String] with a human readable millisecond precision UTC time based
    def self.printable_time time
      time.utc.strftime('%d %B %Y - %H:%M:%S.%L UTC')
    end

    # @return [Integer] millisecond timestamp
    def self.ms_timestamp time
      (time.to_f * 1000).to_i
    end


  end
end
