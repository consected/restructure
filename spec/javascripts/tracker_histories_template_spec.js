//= require app/_fpa_utils.js
//= require app/handlebars-helpers.js

// Tracker history template rendering specs.
// Ensures protocol_name values keep their original casing in tracker history rows.
describe('tracker_histories template rendering', function () {
  it('does not capitalize protocol_name values', function () {
    var templateSource = [
      "{{#filter this 'protocol_name,event_name,notes'}}",
      "{{#if this}}",
      "{{#is @key 'in' 'notes,protocol_name'}}",
      "[{{@key}}={{this}}]",
      "{{else}}",
      "[{{@key}}={{pretty_string this return_string=\"true\" capitalize=\"true\"}}]",
      "{{/is}}",
      "{{/if}}",
      "{{/filter}}"
    ].join('');

    var template = Handlebars.compile(templateSource);

    var result = template({
      protocol_name: 'PRESS',
      event_name: 'follow up',
      notes: 'keep as typed'
    });

    expect(result).toContain('[protocol_name=PRESS]');
    expect(result).not.toContain('[protocol_name=Press]');
  });
});
