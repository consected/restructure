require 'rails_helper'

RSpec.describe Formatter::DateTime, type: :model do

  it "generates a date time string from Date and Time objects" do

    # Day before daylight savings time starts. Standard time is UTC -5 hours
    date = Date.parse('2015-03-07')
    time = Time.parse('14:56:04 EST')

    res = Formatter::DateTime.format [date, time], iso: true, utc: true

    expect(res).to eq '2015-03-07 19:56:04 UTC'

    # Day after daylight savings time starts. Daylight savings time is UTC -4 hours
    date = Date.parse('2015-03-08')
    time = Time.parse('14:56:04 EDT')

    res = Formatter::DateTime.format [date, time], iso: true, utc: true

    expect(res).to eq '2015-03-08 18:56:04 UTC'


    # Handle time without timezone
    date = Date.parse('2015-03-07')
    time = Time.parse('14:56:04 UTC')

    res = Formatter::DateTime.format [date, time], iso: true, utc: true

    expect(res).to eq '2015-03-07 14:56:04 UTC'

  end

end
