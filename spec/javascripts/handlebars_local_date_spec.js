//= require app/_fpa_utils.js
//= require app/handlebars-helpers.js

// Purpose: verify the local_date Handlebars helper (used for DOB/DOD in master record banners)
// never shifts date-only values such as birth_date to a different day, whatever the browser timezone,
// while timestamps with an explicit offset still show the day they represent in UTC.
// The browser timezone is simulated with luxon's defaultZone, using a zone east of UTC (BST) where the bug occurs.
describe('local_date helper', function () {
  var originalDefaultZone;
  var template = Handlebars.compile("{{local_date value '-'}}");

  beforeEach(function () {
    originalDefaultZone = luxon.Settings.defaultZone;
    _fpa.state.current_user_preference = {
      date_format: 'mm/dd/yyyy',
      date_time_format: 'mm/dd/yyyy hh:mm am/pm',
      time_format: 'hh:mm am/pm',
      timezone_iana: 'America/New_York',
      timezone: 'Eastern Time (US & Canada)'
    };
    luxon.Settings.defaultZone = 'Europe/London';
  });

  afterEach(function () {
    luxon.Settings.defaultZone = originalDefaultZone;
  });

  it('shows a date-only birth_date on the same day it was stored', function () {
    expect(template({ value: '1980-05-03' })).toEqual('05/03/1980');
  });

  it('does not shift a date-only value on a day boundary', function () {
    expect(template({ value: '1980-01-01' })).toEqual('01/01/1980');
    expect(template({ value: '2000-12-31' })).toEqual('12/31/2000');
  });

  it('keeps the UTC day for a timestamp with an explicit offset', function () {
    expect(template({ value: '2024-01-15T23:30:00Z' })).toEqual('01/15/2024');
  });

  it('shows the stored day for a timestamp without an offset', function () {
    expect(template({ value: '1980-05-03T00:00:00' })).toEqual('05/03/1980');
  });

  it('returns the unknown placeholder for empty values', function () {
    expect(template({ value: '' })).toEqual('-');
    expect(template({ value: null })).toEqual('-');
  });
});
