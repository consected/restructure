//= require app/_fpa_form_utils.js
//= require app/_fpa_tag_formatter.js
//= require app/_fpa_substitution.js

describe('_fpa.tag_formatter', function () {
  // Mock dependencies to avoid undefined variables
  beforeEach(function () {
    // Mock UserPreferences    
    _fpa.state.current_user_preference = {
      date_format: 'mm/dd/yyyy',
      date_time_format: 'mm/dd/yyyy hh:mm am/pm',
      time_format: 'hh:mm am/pm',
      timezone_iana: 'America/New_York',
      timezone: 'Eastern Time (US & Canada)'
    }

  });

  it("formats basic string operations correctly", function () {
    // Test capitalize
    var result = _fpa.tag_formatter.format_with('capitalize', 'test string', 'test string', 'string', {});
    expect(result).toEqual('Test string');

    // Test titleize
    result = _fpa.tag_formatter.format_with('titleize', 'test string value', 'test string value', 'name', {});
    expect(result).toEqual('Test String Value');

    // Test uppercase
    result = _fpa.tag_formatter.format_with('uppercase', 'test', 'test', 'name', {});
    expect(result).toEqual('TEST');

    // Test lowercase
    result = _fpa.tag_formatter.format_with('lowercase', 'TEST', 'TEST', 'name', {});
    expect(result).toEqual('test');
  });

  it("formats identifier-style operations correctly", function () {
    // Test underscore
    var result = _fpa.tag_formatter.format_with('underscore', 'Test String', 'Test String', 'name', {});
    expect(result).toEqual('test_string');

    // Test hyphenate
    result = _fpa.tag_formatter.format_with('hyphenate', 'Test_String', 'Test_String', 'name', {});
    expect(result).toEqual('Test-String');

    // Test id_hyphenate
    result = _fpa.tag_formatter.format_with('id_hyphenate', 'Test String', 'Test String', 'name', {});
    expect(result).toEqual('test-string');

    // Test id_underscore
    result = _fpa.tag_formatter.format_with('id_underscore', 'Test String', 'Test String', 'name', {});
    expect(result).toEqual('test_string');
  });

  it("extracts parts of strings correctly", function () {
    // Test initial
    var result = _fpa.tag_formatter.format_with('initial', 'test', 'test', 'name', {});
    expect(result).toEqual('T');

    // Test first (first character)
    result = _fpa.tag_formatter.format_with('first', 'test', 'test', 'name', {});
    expect(result).toEqual('t');

    // Test last (last element in array)
    result = _fpa.tag_formatter.format_with('last', ['a', 'b', 'c'], ['a', 'b', 'c'], 'items', {});
    expect(result).toEqual('c');
  });

  it("formats date and time values correctly", function () {
    // Test date formatting
    var result = _fpa.tag_formatter.format_with('date', '', '2025-08-19T00:00:00Z', 'birth_date', {});
    expect(result).toEqual('08/19/2025');

    // Test date_time formatting - expect it to show the time as set as if there was no timezone
    result = _fpa.tag_formatter.format_with('date_time', '', '2025-08-19T14:30:45Z', 'created_at', {});
    expect(result).toEqual('08/19/2025 2:30 pm');

    // Test date_time formatting - expect it to show the time as set as if there was no timezone
    result = _fpa.tag_formatter.format_with('date_time_with_zone', '', '2025-08-19T14:30:45-04:00', 'created_at', {});
    expect(result).toEqual('08/19/2025 2:30 pm');

    // Test date_time formatting - expect it to show the time as set as if there was no timezone
    result = _fpa.tag_formatter.format_with('date_time_show_zone', '', '1989-12-10T02:43:01Z', 'created_at', {});
    expect(result).toEqual('12/09/1989 9:43 pm Eastern Time (US & Canada)');

    // Test time formatting
    result = _fpa.tag_formatter.format_with('time', '', '2025-08-19T14:30:45Z', 'appointment_time', {});
    expect(result).toEqual('10:30 am');

    // Test time_sec formatting
    result = _fpa.tag_formatter.format_with('time_sec', '', '2025-08-19T14:30:45Z', 'precise_time', {});
    expect(result).toEqual('10:30:45 am');

    // Test time_ignore_zone formatting
    result = _fpa.tag_formatter.format_with('time_ignore_zone', '', '2025-08-19T14:30:45Z', 'precise_time', {});
    expect(result).toEqual('2:30 pm');

    // Test time_with_zone formatting
    result = _fpa.tag_formatter.format_with('time_with_zone', '', '2025-08-19T14:30:45Z', 'precise_time', {});
    expect(result).toEqual('10:30 am');

    // Test time_show_zone formatting
    result = _fpa.tag_formatter.format_with('time_show_zone', '', '2025-08-19T14:30:45Z', 'precise_time', {});
    expect(result).toEqual('10:30 am Eastern Time (US & Canada)');

    // Test redcap_date formatting
    result = _fpa.tag_formatter.format_with('redcap_date', '', '2025-08-19T14:30:45Z', 'export_date', {});
    expect(result).toEqual('2025-08-19');

    // Test dicom_date formatting
    result = _fpa.tag_formatter.format_with('dicom_date', '', '2025-08-19T14:30:45Z', 'scan_date', {});
    expect(result).toEqual('20250819');

    // Test dicom_datetime formatting
    result = _fpa.tag_formatter.format_with('dicom_datetime', '', '2025-08-19T14:30:45Z', 'scan_date', {});
    expect(result).toEqual('20250819143045+0000');

    // Test iso8601_datetime formatting
    result = _fpa.tag_formatter.format_with('iso8601_datetime', '', '2025-08-19T14:30:45Z', 'scan_date', {});
    expect(result).toEqual('2025-08-19T14:30:45Z');

    // Test age formatting
    var almost_10years_ago = new Date();
    almost_10years_ago.setFullYear(almost_10years_ago.getFullYear() - 10);
    almost_10years_ago.setDate(almost_10years_ago.getDate() + 1);
    result = _fpa.tag_formatter.format_with('age', '', almost_10years_ago, 'scan_date', {});
    expect(result).toEqual(9);
  });

  it("joins arrays with different separators correctly", function () {
    const testArray = ['apple', 'banana', 'cherry'];
    const testEmailParts = ['user.name', 'example.com']

    // Test join_with_space
    var result = _fpa.tag_formatter.format_with('join_with_space', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple banana cherry');

    // Test join_with_comma
    result = _fpa.tag_formatter.format_with('join_with_comma', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple, banana, cherry');

    // Test join_with_csv - simple array
    result = _fpa.tag_formatter.format_with('join_with_csv', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple,banana,cherry');

    // Test join_with_csv - array with commas and quotes
    const csvArray = ['John', 'Doe, Jr.', 'Manager'];
    result = _fpa.tag_formatter.format_with('join_with_csv', csvArray, csvArray, 'data', {});
    expect(result).toEqual('John,"Doe, Jr.",Manager');

    // Test join_with_semicolon
    result = _fpa.tag_formatter.format_with('join_with_semicolon', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple; banana; cherry');

    // Test join_with_pipe
    result = _fpa.tag_formatter.format_with('join_with_pipe', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple|banana|cherry');

    // Test join_with_dot
    result = _fpa.tag_formatter.format_with('join_with_dot', ['www', 'example', 'com'], ['www', 'example', 'com'], 'domain', {});
    expect(result).toEqual('www.example.com');

    // Test join_with_slash
    result = _fpa.tag_formatter.format_with('join_with_slash', ['home', 'user', 'docs'], ['home', 'user', 'docs'], 'path', {});
    expect(result).toEqual('home/user/docs');

    // Test join_with_newline
    result = _fpa.tag_formatter.format_with('join_with_newline', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple\nbanana\ncherry');

    // Test join_with_2newlines
    result = _fpa.tag_formatter.format_with('join_with_2newlines', testArray, testArray, 'fruits', {});
    expect(result).toEqual('apple\n\nbanana\n\ncherry');

    // Test join_with_at
    result = _fpa.tag_formatter.format_with('join_with_at', testEmailParts, testEmailParts, 'email_parts', {});
    expect(result).toEqual('user.name@example.com');
  });

  it("splits strings into arrays correctly", function () {
    // Test split_comma
    var result = _fpa.tag_formatter.format_with('split_comma', 'apple,banana,cherry', 'apple,banana,cherry', 'fruits', {});
    expect(result).toEqual(['apple', 'banana', 'cherry']);

    // Test split_csv - simple string
    result = _fpa.tag_formatter.format_with('split_csv', 'apple,banana,cherry', 'apple,banana,cherry', 'fruits', {});
    expect(result).toEqual(['apple', 'banana', 'cherry']);

    // Test split_csv - with quoted values
    result = _fpa.tag_formatter.format_with('split_csv', 'John,"Doe, Jr.",Manager', 'John,"Doe, Jr.",Manager', 'data', {});
    expect(result).toEqual(['John', 'Doe, Jr.', 'Manager']);

    // Test split_lines
    result = _fpa.tag_formatter.format_with('split_lines', 'apple\nbanana\ncherry', 'apple\nbanana\ncherry', 'notes', {});
    expect(result).toEqual(['apple', 'banana', 'cherry']);

    // Test split_semicolon
    result = _fpa.tag_formatter.format_with('split_semicolon', 'apple;banana;cherry', 'apple;banana;cherry', 'fruits', {});
    expect(result).toEqual(['apple', 'banana', 'cherry']);

    // Test split_pipe
    result = _fpa.tag_formatter.format_with('split_pipe', 'field1|field2|field3', 'field1|field2|field3', 'fields', {});
    expect(result).toEqual(['field1', 'field2', 'field3']);

    // Test split_dot
    result = _fpa.tag_formatter.format_with('split_dot', 'www.example.com', 'www.example.com', 'domain', {});
    expect(result).toEqual(['www', 'example', 'com']);

    // Test split_at
    result = _fpa.tag_formatter.format_with('split_at', 'user@example.com', 'user@example.com', 'email', {});
    expect(result).toEqual(['user', 'example.com']);

    // Test split_slash
    result = _fpa.tag_formatter.format_with('split_slash', 'home/user/docs', 'home/user/docs', 'path', {});
    expect(result).toEqual(['home', 'user', 'docs']);

    // Test split_space
    result = _fpa.tag_formatter.format_with('split_space', 'hello world test', 'hello world test', 'text', {});
    expect(result).toEqual(['hello', 'world', 'test']);
  });

  it("transforms arrays correctly", function () {
    const testArray = ['banana', 'apple', 'cherry', 'apple'];

    // Test compact
    var result = _fpa.tag_formatter.format_with('compact', ['apple', null, 'banana', '', 'cherry'],
      ['apple', null, 'banana', '', 'cherry'], 'fruits', {});
    expect(result).toEqual(['apple', 'banana', 'cherry']);

    // Test sort
    result = _fpa.tag_formatter.format_with('sort', testArray, testArray, 'fruits', {});
    expect(result).toEqual(['apple', 'apple', 'banana', 'cherry']);

    // Test sort_reverse
    result = _fpa.tag_formatter.format_with('sort_reverse', testArray, testArray, 'fruits', {});
    expect(result).toEqual(['cherry', 'banana', 'apple', 'apple']);

    // Test uniq
    result = _fpa.tag_formatter.format_with('uniq', testArray, testArray, 'fruits', {});
    expect(result).toEqual(['cherry', 'banana', 'apple']);
  });

  it("formats arrays as lists correctly", function () {
    const testArray = ['apple', 'banana', 'cherry'];

    // Test markdown_list
    var result = _fpa.tag_formatter.format_with('markdown_list', testArray, testArray, 'fruits', {});
    expect(result).toEqual('- apple\n- banana\n- cherry');

    // Test html_list
    result = _fpa.tag_formatter.format_with('html_list', testArray, testArray, 'fruits', {});
    expect(result).toEqual('<ul><li>apple</li>\n  <li>banana</li>\n  <li>cherry</li></ul>');
  });

  it("handles conversion between formats correctly", function () {
    // Test markup (markdown to HTML)
    var result = _fpa.tag_formatter.format_with('markup', '# Title', '# Title', 'content', {});
    expect(result).toEqual('<h1 id="title">Title</h1>\n');

    // Test json
    const obj = { name: 'John', age: 30 };
    result = _fpa.tag_formatter.format_with('json', obj, obj, 'user', {});
    expect(result).toEqual('{\n  "name": "John",\n  "age": 30\n}');

    // Test yaml
    result = _fpa.tag_formatter.format_with('yaml', obj, obj, 'user', {});
    expect(result).toEqual('name: John\nage: 30\n');
  });

  it("uses format_all to apply multiple formatters", function () {
    var result = _fpa.tag_formatter.format_all('test string', ['split_space', 'join_with_comma'], 'name', {});
    expect(result).toEqual('test, string');

    result = _fpa.tag_formatter.format_all(['apple', 'banana'], ['sort', 'join_with_comma'], 'fruits', {});
    expect(result).toEqual('apple, banana');

    result = _fpa.tag_formatter.format_all('test name', [], 'name', {});
    expect(result).toEqual('Test Name');
  });

  it("handles missing values gracefully", function () {
    var result = _fpa.tag_formatter.format_all(null, ['ignore_missing'], 'name', {});
    expect(result).toEqual('');

    result = _fpa.tag_formatter.format_all(null, [], 'name', {});
    expect(result).toBeUndefined();
  });

  it("returns value unchanged with no_html_tag", function () {
    var result = _fpa.tag_formatter.format_with('no_html_tag', '<p>HTML content</p>', '<p>HTML content</p>');
    expect(result).toEqual('<p>HTML content</p>');

    result = _fpa.tag_formatter.format_with('no_html_tag', 'plain text', 'plain text');
    expect(result).toEqual('plain text');
  });

  it("uses general_selection_label to retrieve labels", function () {
    const data = {
      _general_selections: {
        status: {
          'A': { name: 'Active' },
          'I': { name: 'Inactive' }
        }
      }
    };

    var result = _fpa.tag_formatter.format_with('general_selection_label', 'A', 'A', 'status', data);
    expect(result).toEqual('Active');
  });

  it("handles string manipulation correctly", function () {
    // Test strip
    var result = _fpa.tag_formatter.format_with('strip', '  hello world  ', '  hello world  ', 'text', {});
    expect(result).toEqual('hello world');

    // Test plaintext
    result = _fpa.tag_formatter.format_with('plaintext', 'Line 1\nLine 2', 'Line 1\nLine 2', 'text', {});
    expect(result).toEqual('Line 1<br>Line 2');
  });

  it("handles numeric indexing correctly", function () {
    const testString = 'Hello World';
    const testArray = ['first', 'second', 'third', 'fourth'];

    // Test numeric indexing for arrays
    var result = _fpa.tag_formatter.format_with('0', testArray, testArray, 'items', {});
    expect(result).toEqual('first');

    result = _fpa.tag_formatter.format_with('2', testArray, testArray, 'items', {});
    expect(result).toEqual('third');

    // Test numeric indexing for strings (slice)
    result = _fpa.tag_formatter.format_with('4', testString, testString, 'text', {});
    expect(result).toEqual('Hello');

    result = _fpa.tag_formatter.format_with('1', testString, testString, 'text', {});
    expect(result).toEqual('He');
  });

  it("parses JSON strings into objects with parse_json", function () {
    const jsonString = '{"key1":"value1","key2":["item1","item2"]}';
    const expectedObj = { key1: 'value1', key2: ['item1', 'item2'] };

    var result = _fpa.tag_formatter.format_with('parse_json', jsonString, jsonString, 'json_field', {});
    expect(result).toEqual(expectedObj);
  });

  it("parses YAML strings into objects with parse_yaml", function () {
    const yamlString = "key1: value1\nkey2:\n- item1\n- item2\n";
    const expectedObj = { key1: 'value1', key2: ['item1', 'item2'] };

    var result = _fpa.tag_formatter.format_with('parse_yaml', yamlString, yamlString, 'yaml_field', {});
    expect(result).toEqual(expectedObj);
  });

  it("chains parse_json with yaml to convert JSON string to YAML string", function () {
    const jsonString = '{"name":"Alice","age":30}';

    var parsed = _fpa.tag_formatter.format_with('parse_json', jsonString, jsonString, 'json_field', {});
    var yamlResult = _fpa.tag_formatter.format_with('yaml', parsed, parsed, 'json_field', {});
    expect(yamlResult).toContain('name: Alice');
    expect(yamlResult).toContain('age: 30');
  });

  it("chains parse_yaml with json to convert YAML string to JSON string", function () {
    const yamlString = "name: Alice\nage: 30\n";

    var parsed = _fpa.tag_formatter.format_with('parse_yaml', yamlString, yamlString, 'yaml_field', {});
    var jsonResult = _fpa.tag_formatter.format_with('json', parsed, parsed, 'yaml_field', {});
    const obj = JSON.parse(jsonResult);
    expect(obj.name).toEqual('Alice');
    expect(obj.age).toEqual(30);
  });

  it("returns null for invalid JSON in parse_json", function () {
    var result = _fpa.tag_formatter.format_with('parse_json', 'not valid json {{{', 'not valid json {{{', 'json_field', {});
    expect(result).toBeNull();
  });

  it("returns null for invalid YAML in parse_yaml", function () {
    var result = _fpa.tag_formatter.format_with('parse_yaml', ': invalid: [yaml', ': invalid: [yaml', 'yaml_field', {});
    expect(result).toBeNull();
  });
});
