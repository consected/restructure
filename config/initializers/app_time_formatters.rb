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

  def time_without_zone?
    year == 2000 && month == 1 && day == 1 && zone == 'UTC'
  end
end
