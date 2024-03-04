require 'rails_helper'

RSpec.describe Formatter::DateTime, type: :model do
  include ModelSupport
  include PlayerContactSupport

  it 'generates a date time string from Date and Time objects' do
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

    # Handle hash with specified timezone
    date = Date.parse('2015-03-08')
    time = Time.parse('13:56:04 GMT')
    zone = 'London'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)

    expect(res).to eq '2015-03-08 13:56:04 UTC'

    # Handle hash with specified timezone close to midnight
    # We retain the previous date, since the intent is to re-zone the time, but keep the date
    # that was originally specified by a user.
    date = Date.parse('2015-03-07')
    time = Time.parse('20:56:04 EST')
    zone = 'Eastern Time (US & Canada)'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true, keep_date: true)

    expect(res).to eq '2015-03-07 01:56:04 UTC'

    # Handle hash with specified timezone
    date = Date.parse('2015-03-29')
    time = Time.parse('14:56:04 +01:00')
    zone = 'London'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)

    expect(res).to eq '2015-03-29 13:56:04 UTC'

    # Handle daylight savings in other timezones
    date = '2015-03-29'
    time = '14:56:04'
    zone = 'London'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)

    expect(res).to eq '2015-03-29 13:56:04 UTC'

    # Handle other timezones
    date = '2015-03-28'
    time = '14:56:04'
    zone = 'London'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)

    expect(res).to eq '2015-03-28 14:56:04 UTC'

    # Handle daylight savings in other timezones, close to midnight
    date = '2015-03-29'
    time = '00:56:04'
    zone = 'London'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)

    expect(res).to eq '2015-03-29 00:56:04 UTC'

    # Handle other timezones, close to midnight
    date = '2015-03-28'
    time = '00:56:04'
    zone = 'London'

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)

    expect(res).to eq '2015-03-28 00:56:04 UTC'

    # If a current user is specified and no current timezone, use the user's preference
    create_user
    date = '2015-03-28'
    time = '14:56:04'
    zone = nil

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true, current_user: @user)

    expect(res).to eq '2015-03-28 18:56:04 UTC'

    # If we have date and time objects as they'd appear from the database, with UTC times, but
    # we want to use the user's timezone preference, specify zone :user.
    # This will take the zone from the user preference and replace what is on the time object
    # This is used by notifications to adjust the time to a timezone either specified in a separate field,
    # or specific to a messaging user, where the date time is returned from the database with UTC, even though
    # we really wanted date time without timezone.
    date = Date.parse('2015-03-08')
    time = Time.parse('2001-01-01 13:56:04 UTC')
    zone = :user

    res = Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true, current_user: @user, keep_date: true)

    expect(res).to eq '2015-03-08 17:56:04 UTC'

    # alternatively to simple show a Date Time as it should appear in the user's preferred timezone

    datetime = Time.parse('2015-03-08 13:56:04 UTC')
    zone = :user

    res = Formatter::DateTime.format(datetime, current_user: @user, current_timezone: zone)

    expect(res).to eq '03/08/2015 9:56 am'
  end

  it 'uses database dates and times correctly' do
    seed_database
    create_user
    create_master
    create_item

    ca = @player_contact.created_at
    date = ca
    time = ca
    zone = ca.time_zone.name

    expect(Formatter::DateTime.format({ date: date, time: time, zone: zone }, iso: true, utc: true)).to eq ca.utc.to_s
  end
end
