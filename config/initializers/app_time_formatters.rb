# frozen_string_literal: true

class ActiveSupport::TimeWithZone
  # Override string formmatting when the special date 2000:01:01 is in the date
  # portion of the time, and the time is UTC. This is Rails making a TimeWithZone from
  # Postgres "time without timezone" type. We just want the simple time back in most cases
  # and this saves us a lot of unnecessary UI processing.
  def as_json(_options = {})
    if time_without_zone?
      strftime('%H:%M:%S')
    else
      xmlschema(ActiveSupport::JSON::Encoding.time_precision)
    end
  end

  def to_s(format = :default)
    if format == :db
      utc.to_s(format)
    elsif time_without_zone?
      strftime('%H:%M:%S')
    elsif formatter = ::Time::DATE_FORMATS[format]
      formatter.respond_to?(:call) ? formatter.call(self).to_s : strftime(formatter)
    else
      "#{time.strftime('%Y-%m-%d %H:%M:%S')} #{formatted_offset(false, 'UTC')}" # mimicking Ruby Time#to_s format
    end
  end

  def time_without_zone?
    year == 2000 && month == 1 && day == 1 && zone == 'UTC'
  end
end
