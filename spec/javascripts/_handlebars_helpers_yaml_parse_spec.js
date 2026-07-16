//= require js-yaml/dist/js-yaml
//= require app/handlebars-helpers.js

// yaml_parse Handlebars helper spec (issue #1269).
//
// The yaml_parse helper parses a YAML text string into its represented Hash/Array,
// used to display name_starts_with_yaml_object fields (stored as plain YAML text in a
// text/varchar column) as a structured object view in search results.
//
// Tests verify:
// - A YAML string representing a Hash is parsed into an object with accessible keys.
// - A YAML string representing an Array is parsed into an iterable array.
// - Non-string input (already an object, null, undefined) is returned unchanged.
// - Malformed YAML text is returned unchanged (safe fallback) rather than raising.
describe('yaml_parse Handlebars helper', function () {
  it('parses a YAML hash string into an object usable with Handlebars property access', function () {
    var template = Handlebars.compile('{{#with (yaml_parse yaml_text)}}{{key1}}/{{key2}}{{/with}}');

    var result = template({ yaml_text: 'key1: value1\nkey2: 42\n' });

    expect(result).toEqual('value1/42');
  });

  it('parses a YAML array string into an iterable array', function () {
    var template = Handlebars.compile('{{#each (yaml_parse yaml_text)}}[{{this}}]{{/each}}');

    var result = template({ yaml_text: '- first\n- second\n' });

    expect(result).toEqual('[first][second]');
  });

  it('returns non-string input unchanged', function () {
    var template = Handlebars.compile('{{#with (yaml_parse obj)}}{{key1}}{{/with}}');

    var result = template({ obj: { key1: 'already an object' } });

    expect(result).toEqual('already an object');
  });

  it('returns null/undefined input unchanged without raising', function () {
    var template = Handlebars.compile('[{{yaml_parse missing}}]');

    var result = template({});

    expect(result).toEqual('[]');
  });

  it('returns malformed YAML text unchanged rather than raising', function () {
    var template = Handlebars.compile('{{yaml_parse yaml_text}}');
    var malformed = 'key1: [1, 2';

    var result = template({ yaml_text: malformed });

    expect(result).toEqual(malformed);
  });
});
