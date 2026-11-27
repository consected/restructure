// Purpose: verify substitutions, config-string escaping, retained conditional-tag safety, and titleization.
//= require app/_fpa_form_utils.js
//= require app/_fpa_substitution.js
describe('substitutions', function () {

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


  it("substitutes and format simple attributes in caption_before blocks", function () {

    var t = '<html><body><div><div class="caption-before"><p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase}}.</p></div><div>--</div><div class="caption-before">Done!</div></div></body></html>'
    var expected_text = '<div><div class="caption-before cb_subs_done"><p>This is some content.</p><p>Related to master_id 1234. This is a name: TEST NAME BOB.</p></div><div>--</div><div class="caption-before cb_subs_done">Done!</div></div>'
    var use_data = { master_id: 1234, name: 'test name bob' };

    var $t = $(t);
    _fpa.form_utils.caption_before_substitutions($t, use_data)
    var res = $t[0].outerHTML;
    expect(res).toEqual(expected_text)
  });

  it("substitutes and formats more complex expressions", function () {
    const text = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase::3}}. Split {{piped::split_pipe::1}}. Is data {{hash.key2}}. Is array {{array::2}} or {{array.1.key}} or {{array.3}}. JSON {{json.json_parse.jkey3.1}}. Array 0 {{array.0}}. Date Time {{date_time::date_time_show_zone}}</p>'
    const use_data = {
      master_id: 5541,
      name: 'test name bob',
      piped: 'data 1|data 2|data 3',
      hash: { key1: 123, key2: 456, key3: 789 },
      array: ['55', { key: '66' }, '77', '88'],
      json: '{"jkey1": 22, "jkey2": "abc", "jkey3": [1230,4560]}',
      date_time: '1989-12-10T02:43:01Z'
    };

    const expected_text = '<p>This is some content.</p><p>Related to master_id 5541. This is a name: TEST. Split data 2. Is data 456. Is array 77 or 66 or 88. JSON 4560. Array 0 55. Date Time 12/09/1989 9:43 pm Eastern Time (US & Canada)</p>'
    const res = _fpa.substitution.substitute(text, use_data);
    expect(res).toEqual(expected_text)

  });

  it("substitutes {{now}} with the current date and time and standard formatters", function () {
    // Fixed clock avoids flakiness around midnight
    const original_now = luxon.Settings.now;
    const original_state_now = _fpa.state.now;
    luxon.Settings.now = () => Date.UTC(2025, 6, 5, 2, 6, 7);
    _fpa.state.now = '2025-07-05T02:06:07.000Z';
    try {
      const res = _fpa.substitution.substitute('{{now::date}}|{{now::date_time}}|{{now}}', { master_id: 1 });
      const parts = res.split('|');

      expect(parts[0]).toEqual('07/05/2025');
      expect(parts[1]).toEqual('07/05/2025 2:06 am');
      expect(parts[2]).not.toEqual('(?)');
    } finally {
      luxon.Settings.now = original_now;
      _fpa.state.now = original_state_now;
    }
  });

  it("does not override a supplied now attribute", function () {
    const res = _fpa.substitution.substitute('{{now::date}}', { now: '1989-12-10T12:00:00Z' });
    expect(res).toEqual('12/10/1989');
  });

  it("automatically titleizes name tags without explicit formatters", function () {
    expect(_fpa.substitution.substitute('Hi {{first_name}}', { first_name: 'jane smith' }))
      .toBe('Hi Jane Smith');
  });

  it("parses a YAML encoded string with yaml_parse for hash and array access", function () {
    const text = '<p>YAML hash {{yaml.yaml_parse.ykey3.1}}. YAML top-level array {{yaml_array.yaml_parse.0}}</p>'
    const use_data = {
      yaml: "ykey1: 22\nykey2: abc\nykey3:\n  - 1230\n  - 4560\n",
      yaml_array: "- first\n- second\n"
    };

    const expected_text = '<p>YAML hash 4560. YAML top-level array first</p>'
    const res = _fpa.substitution.substitute(text, use_data);
    expect(res).toEqual(expected_text)

  });

  it("substitutes conditionally", function () {

    var t = '<html><body><div><div class="caption-before"><p>{{#if id}}This is some content.{{else}}no id{{/if}}</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase}}.</p></div><div>--</div><div class="caption-before">Done!</div></div></body></html>'
    var expected_text = '<div><div class="caption-before cb_subs_done"><p>This is some content.</p><p>Related to master_id 1234. This is a name: TEST NAME BOB.</p></div><div>--</div><div class="caption-before cb_subs_done">Done!</div></div>'
    var use_data = { id: 1, master_id: 1234, name: 'test name bob' };
    var $t = $(t);

    _fpa.form_utils.caption_before_substitutions($t, use_data)
    var res = $t[0].outerHTML;
    expect(res).toEqual(expected_text)
  });

  it("substitutes conditionally with else", function () {

    var t = '<html><body><div><div class="caption-before"><p>{{#if id}}This is some content.{{else}}no id{{/if}}</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase}}.</p></div><div>--</div><div class="caption-before">Done!</div></div></body></html>'
    var expected_text = '<div><div class="caption-before cb_subs_done"><p>no id</p><p>Related to master_id 1234. This is a name: TEST NAME BOB.</p></div><div>--</div><div class="caption-before cb_subs_done">Done!</div></div>'
    var use_data = { id: null, master_id: 1234, name: 'test name bob' };
    var $t = $(t);

    _fpa.form_utils.caption_before_substitutions($t, use_data)
    var res = $t[0].outerHTML;
    expect(res).toEqual(expected_text)
  });

  it("substitutes conditionally with current user roles", function () {

    var t = '<html><body><div><div class="caption-before"><p>{{#if current_user_roles.role_1}}has role 1{{else}}no role{{/if}}</p></div></div></body></html>'
    var expected_text = '<div><div class="caption-before cb_subs_done"><p>has role 1</p></div></div>'
    var use_data = { id: null, master_id: 1234, name: 'test name bob' };
    var $t = $(t);
    _fpa.state.current_user_roles = ['role 2', 'role 1']

    _fpa.form_utils.caption_before_substitutions($t, use_data)
    var res = $t[0].outerHTML;
    expect(res).toEqual(expected_text)

  });

  it("substitutes conditionally with current user roles", function () {

    var t = '<html><body><div><div class="caption-before"><p>{{#if current_user_roles.role_1}}has role 1{{else}}no role{{/if}}</p></div></div></body></html>'
    var expected_text = '<div><div class="caption-before cb_subs_done"><p>no role</p></div></div>'
    var use_data = { id: null, master_id: 1234, name: 'test name bob' };
    var $t = $(t);

    _fpa.state.current_user_roles = ['role 2', 'role 3']

    _fpa.form_utils.caption_before_substitutions($t, use_data)
    var res = $t[0].outerHTML;
    expect(res).toEqual(expected_text)
  });

  it("supports arbitrary else-if conditions", function () {
    const text = '{{#if v1}}one{{else if v2}}two{{else if v3}}three{{else if v4}}four{{else if v5}}five{{else}}none{{/if}}';

    let res = _fpa.substitution.substitute(text, { v1: false, v2: false, v3: true, v4: true, v5: true });
    expect(res).toEqual('three');

    res = _fpa.substitution.substitute(text, { v1: false, v2: false, v3: false, v4: false, v5: true });
    expect(res).toEqual('five');

    res = _fpa.substitution.substitute(text, { v1: false, v2: false, v3: false, v4: false, v5: false });
    expect(res).toEqual('none');
  });

  it("handles a single if string with at least five else-if clauses", function () {
    const text = '{{#if a}}A{{else if b}}B{{else if c}}C{{else if d}}D{{else if e}}E{{else if f}}F{{else}}none{{/if}}';

    let res = _fpa.substitution.substitute(text, { a: true, b: false, c: false, d: false, e: false, f: true });
    expect(res).toEqual('A');

    res = _fpa.substitution.substitute(text, { a: false, b: false, c: false, d: false, e: false, f: true });
    expect(res).toEqual('F');

    res = _fpa.substitution.substitute(text, { a: false, b: false, c: false, d: false, e: false, f: false });
    expect(res).toEqual('none');
  });

  it("supports arbitrary else-is conditions", function () {
    const text = '{{#is score \'==\' 1}}one{{else is score \'==\' 2}}two{{else is score \'==\' 3}}three{{else is score \'==\' 4}}four{{else is score \'==\' 5}}five{{else}}none{{/is}}';

    let res = _fpa.substitution.substitute(text, { score: 4 });
    expect(res).toEqual('four');

    res = _fpa.substitution.substitute(text, { score: 5 });
    expect(res).toEqual('five');

    res = _fpa.substitution.substitute(text, { score: 99 });
    expect(res).toEqual('none');
  });
});

describe('admin configuration substitutions', function () {
  beforeEach(function () {
    _fpa.state.current_user = { id: 17, email: 'current@example.test' };
    _fpa.state.current_user_preference = { date_format: 'mm/dd/yyyy' };
    _fpa.state.current_user_roles = [];
    _fpa.state.masters = {};
    _fpa.state.common_constants = {
      base_url: 'https://example.test',
      environment_name: 'test',
      admin_email: 'admin@example.test',
      default_logo: '/images/logo.png',
      user_session_timeout: 30,
      allow_users_to_register: true
    };
  });

  it('prepares current-user preference and non-sensitive common constants without overriding data', function () {
    const itemPreference = { date_format: 'dd/mm/yyyy' };
    const data = new _fpa.substitution('', {
      user_preference: itemPreference,
      base_url: 'https://record.example.test'
    }).get_data();

    expect(data.current_user_preference).toEqual({ date_format: 'mm/dd/yyyy' });
    expect(data.user_preference).toBe(itemPreference);
    expect(data.current_user_id).toBe(17);
    expect(data.current_user_email).toBe('current@example.test');
    expect(data.base_url).toBe('https://record.example.test');
    expect(data.environment_name).toBe('test');
    expect(data.admin_email).toBe('admin@example.test');
    expect(data.default_logo).toBe('/images/logo.png');
    expect(data.user_session_timeout).toBe(30);
    expect(data.allow_users_to_register).toBe(true);
  });

  it('renders formatted, dotted, and this-prefixed values using ReStructure syntax', function () {
    const render = _fpa.substitution.compile_config_string(
      '{{name::uppercase}}|{{address.city}}|{{this.id}}',
      { missing: 'blank', escape_values: true }
    );

    expect(render({ name: 'sample', address: { city: 'Boston' }, id: 21 }))
      .toBe('SAMPLE|Boston|21');
  });

  it('supports formatter and ignore_missing substitutions used by configured captions', function () {
    const render = _fpa.substitution.compile_config_string(
      '{{select_project::ignore_missing}} {{select_test_type}}',
      { missing: 'blank', escape_values: true }
    );

    expect(render({ select_test_type: 'physical' })).toBe(' physical');
  });

  it('decodes ERB-escaped quotes in conditional config strings', function () {
    const sources = [
      "{{#is select_test_type &#39;==&#39; &#39;blood&#39;}}Blood{{else}}Other{{/is}}",
      "{{#is select_test_type &#x27;==&#x27; &#x27;blood&#x27;}}Blood{{else}}Other{{/is}}",
      "{{#is select_test_type &quot;==&quot; &quot;blood&quot;}}Blood{{else}}Other{{/is}}",
      "{{#is select_test_type &#39;==&#39; &#39;blood&#39;}}Blood{{else is select_test_type &#39;==&#39; &#39;urine&#39;}}Urine{{else}}Other{{/is}}"
    ];

    sources.forEach(function (source) {
      const render = _fpa.substitution.compile_config_string(source);
      expect(render({ select_test_type: 'blood' })).toBe('Blood');
      expect(render({ select_test_type: 'urine' })).toBe(source.indexOf('else is') >= 0 ? 'Urine' : 'Other');
    });
  });

  it('keeps escaped quotes safe in conditional tags that are not consumed', function () {
    const sources = [
      '{{else is &quot;onmouseover=alert(1) x=&quot;}}',
      '{{#is status &quot;==&quot; &quot;x onmouseover=alert(1) y&quot;}}',
      '{{#is status &quot;==&quot; &quot;a&quot;}}{{#is name &quot;==&quot; &quot;z onmouseover=alert(2) q&quot;}}X{{/is}}{{/is}}',
      '{{#is field &quot;x&quot;}}Y{{/is}}'
    ];

    sources.forEach(function (source) {
      const output = _fpa.substitution.compile_config_string(source)({ status: 'a', name: 'n', field: 'x' });
      const $element = $('<div data-human-name="' + output + '"></div>');

      expect(output).not.toContain('"');
      expect($element[0].attributes.length).toBe(1);
      expect($element[0].hasAttribute('onmouseover')).toBe(false);
    });
  });

  it('still evaluates well-formed escaped-quote is conditions', function () {
    const render = _fpa.substitution.compile_config_string(
      '{{#is status &quot;==&quot; &quot;ready&quot;}}Ready{{else}}Other{{/is}}'
    );

    expect(render({ status: 'ready' })).toBe('Ready');
    expect(render({ status: 'pending' })).toBe('Other');
  });

  it('preserves glyphicon markup in captions with escaped-quote conditions', function () {
    const render = _fpa.substitution.compile_config_string(
      '{{#is status &quot;==&quot; &quot;ready&quot;}}{{glyphicon_star}}{{/is}}'
    );

    expect(render({ status: 'ready' })).toBe('<span class="glyphicon glyphicon-star"></span>');
  });

  it('preserves escaped quote entities in literal config text', function () {
    const source = 'Notes &quot;A&quot; and it&#39;s saved';
    const render = _fpa.substitution.compile_config_string(source);

    expect(render({})).toBe(source);
  });

  it('does not let escaped quotes in literal config text create HTML attributes', function () {
    const source = 'Notes &quot;A&quot; onmouseover=&quot;alert(1)';
    const render = _fpa.substitution.compile_config_string(source);
    const $element = $('<div data-human-name="' + render({}) + '"></div>');

    expect($element[0].hasAttribute('onmouseover')).toBe(false);
  });

  it('does not auto-titleize config tags but still applies explicit formatters', function () {
    expect(_fpa.substitution.compile_config_string('{{name}}')({ name: 'my_container' }))
      .toBe('my_container');
    expect(_fpa.substitution.compile_config_string('{{first_name::uppercase}}')({ first_name: 'jane smith' }))
      .toBe('JANE SMITH');
  });

  it('renders empty or blank config strings as empty strings', function () {
    expect(_fpa.substitution.compile_config_string('')({})).toBe('');
    expect(_fpa.substitution.compile_config_string('  \n\t ')({})).toBe('');
    expect(_fpa.substitution.compile_config_string(null)({})).toBe('');
    expect(_fpa.substitution.compile_config_string(undefined)({})).toBe('');
  });

  it('returns literal config strings without running substitutions', function () {
    const substitute_spy = spyOn(_fpa.substitution, 'substitute').and.callThrough();
    const render = _fpa.substitution.compile_config_string('Edit item');

    expect(render({ id: 21 })).toBe('Edit item');
    expect(substitute_spy).not.toHaveBeenCalled();
  });

  it('does not compute the current time for config strings that do not use now', function () {
    const original_state_now = _fpa.state.now;
    _fpa.state.now = '2025-01-01T10:00:00.000Z';
    const now_spy = spyOn(_fpa.utils.DateTime, 'now').and.callThrough();
    const render = _fpa.substitution.compile_config_string('/addresses/{{this.id}}/edit');

    try {
      expect(render({ id: 21 })).toBe('/addresses/21/edit');
      expect(now_spy).not.toHaveBeenCalled();
    } finally {
      _fpa.state.now = original_state_now;
    }
  });

  it('uses the state now value and refreshes it when AJAX completes', function () {
    const original_now = luxon.Settings.now;
    const original_state_now = _fpa.state.now;
    const initial_now = '2025-01-01T10:00:00.000Z';

    try {
      _fpa.state.now = initial_now;
      luxon.Settings.now = () => Date.UTC(2030, 0, 1, 0, 0, 0);
      const render = _fpa.substitution.compile_config_string('{{now}}');
      expect(render({})).toBe(initial_now);

      luxon.Settings.now = () => Date.UTC(2025, 0, 1, 10, 1, 2);
      _fpa.setup_ajax_state_updates();
      $(document).trigger('ajaxComplete');
      expect(_fpa.state.now).toBe('2025-01-01T10:01:02.000Z');
      expect(render({})).toBe(_fpa.state.now);
    } finally {
      luxon.Settings.now = original_now;
      _fpa.state.now = original_state_now;
    }
  });

  it('updates current user roles when the roles array is replaced', function () {
    const original_roles = _fpa.state.current_user_roles;
    const first_role = { id_underscore: function () { return 'role_one'; } };
    const second_role = { id_underscore: function () { return 'role_two'; } };

    try {
      _fpa.state.current_user_roles = [first_role];
      const first_data = new _fpa.substitution('', {}).get_data();
      expect(first_data.current_user_roles.role_one).toBe(first_role);

      _fpa.state.current_user_roles = [second_role];
      const second_data = new _fpa.substitution('', {}).get_data();
      expect(second_data.current_user_roles.role_two).toBe(second_role);
      expect(second_data.current_user_roles.role_one).toBeUndefined();
    } finally {
      _fpa.state.current_user_roles = original_roles;
    }
  });

  it('preserves application helpers and template registries in the Jasmine compiler build', function () {
    expect(Handlebars.helpers.format_with).toEqual(jasmine.any(Function));
    expect(Handlebars.compile('{{format_with "uppercase" "sample"}}')({})).toBe('SAMPLE');
    expect(_fpa.templates).toBe(Handlebars.templates);
    expect(_fpa.partials).toBe(Handlebars.partials);
  });

  it('formats the shared now value in a compiled config string', function () {
    const render = _fpa.substitution.compile_config_string('{{now::date}}');

    expect(render({ now: '2025-07-05T02:06:07Z' })).toBe('07/05/2025');
  });

  it('supports conditional substitutions and leaves missing config tags blank', function () {
    const render = _fpa.substitution.compile_config_string(
      '{{#if master_id}}/masters/{{master_id}}{{/if}}/{{missing}}',
      { missing: 'blank', escape_values: true }
    );

    expect(render({ master_id: 7 })).toBe('/masters/7/');
  });

  it('HTML-escapes substituted values but preserves deliberate glyphicon markup', function () {
    const render = _fpa.substitution.compile_config_string(
      '{{value}} {{glyphicon_pencil}}',
      { missing: 'blank', escape_values: true }
    );

    expect(render({ value: '<b>&</b>' }))
      .toBe('&lt;b&gt;&amp;&lt;/b&gt; <span class="glyphicon glyphicon-pencil"></span>');

    spyOn(_fpa.utils, 'embedded_report').and.returnValue('<table></table>');
    expect(_fpa.substitution.compile_config_string('{{embedded_report_sample_report}}')({}))
      .toBe('<table></table>');
  });

  it('does not treat dollar sequences in substituted values as replacement patterns', function () {
    const render = _fpa.substitution.compile_config_string('Item: {{data}}');

    expect(render({ data: 'Budget $<5k' })).toBe('Item: Budget $&lt;5k');
    expect(render({ data: "Tom $'s" })).toBe('Item: Tom $&#x27;s');
    expect(render({ data: 'Pay $$5' })).toBe('Item: Pay $$5');
    expect(_fpa.substitution.substitute('Pay {{amount}}', { amount: '$$5' })).toBe('Pay $$5');
  });

  it('preserves dollar sequences literally in conditional blocks', function () {
    const if_source = '{{#if flag}}Cost $& and $$ and $\' here{{/if}}';
    expect(_fpa.substitution.substitute(if_source, { flag: true })).toBe("Cost $& and $$ and $' here");

    const is_source = "{{#is status '==' 'ok'}}Price $$5 $&{{else}}Other $`{{/is}}";
    expect(_fpa.substitution.substitute(is_source, { status: 'ok' })).toBe('Price $$5 $&');
    expect(_fpa.substitution.substitute(is_source, { status: 'no' })).toBe('Other $`');
  });

  it('supports the built-in edit URL and address-country conditions', function () {
    const href = _fpa.substitution.compile_config_string(
      '{{#if master_id}}/masters/{{master_id}}{{/if}}/dynamic_model/test_recs/{{this.id}}/edit'
    );
    expect(href({ master_id: 7, id: 21 })).toBe('/masters/7/dynamic_model/test_recs/21/edit');

    const addressIsUsSource = "{{#is country '==' 'us'}}true{{else is country '==' ''}}true{{else is country '==' null}}true{{else}}false{{/is}}";
    const addressIsUs = _fpa.substitution.compile_config_string(addressIsUsSource);
    const addressCountries = [
      ['us', 'true'],
      ['', 'true'],
      [null, 'true'],
      ['gb', 'false']
    ];

    addressCountries.forEach(function (country_and_expected) {
      const country = country_and_expected[0];
      const expected = country_and_expected[1];
      const data = { country: country };
      expect(addressIsUs(data)).toBe(expected);
      expect(Handlebars.helpers.template.call({}, addressIsUsSource, data)).toBe(expected);
    });
  });

  it('keeps template and compile_template helpers compatible with precompiled templates', function () {
    const context = { name: '<Taylor>', source: '{{name}}' };
    const templateResult = Handlebars.compile('{{{template source}}}')(context);
    const compiled = Handlebars.helpers.compile_template.call(context, '{{name::uppercase}}');
    const runResult = Handlebars.compile('{{{run_template compiled}}}')({
      name: '<Taylor>',
      compiled: compiled
    });

    expect(templateResult).toBe('&lt;Taylor&gt;');
    expect(runResult).toBe('&lt;TAYLOR&gt;');
  });
});

// Purpose: verify that substitution context layering (without copying the record) keeps record values,
// defaults, inherited-member handling and non-object contexts behaving as before.
describe('substitution context layering', function () {
  beforeEach(function () {
    _fpa.state.current_user = { id: 17, email: 'current@example.test' };
    _fpa.state.current_user_preference = { date_format: 'mm/dd/yyyy' };
    _fpa.state.current_user_roles = [];
    _fpa.state.masters = {};
    _fpa.state.common_constants = { base_url: 'https://example.test', environment_name: 'test' };
  });

  it('does not mutate the supplied record or the saved master', function () {
    _fpa.state.masters[901] = { name: 'master name' };
    const record = { master_id: 901, base_url: 'https://record.example.test', name: 'record name' };
    const keysBefore = Object.keys(record);

    const res = _fpa.substitution.substitute('{{master.name}} {{name}} {{base_url}}', record);

    expect(res).toBe('Master Name Record Name https://record.example.test');
    expect(Object.keys(record)).toEqual(keysBefore);
    expect(record.master).toBeUndefined();
    expect(record.current_user_id).toBeUndefined();
    expect(_fpa.state.masters[901]).toEqual({ name: 'master name' });
  });

  it('lets record values win over constants and current-user keys while still filling falsy defaults', function () {
    const record = {
      base_url: 'https://record.example.test',
      current_user_preference: { date_format: 'record format' },
      now: '1989-12-10T12:00:00Z',
      user_preference: null
    };

    const data = new _fpa.substitution('', record).get_data();
    expect(data.base_url).toBe('https://record.example.test');
    expect(data.current_user_preference).toEqual({ date_format: 'record format' });
    expect(data.now).toBe('1989-12-10T12:00:00Z');
    expect(data.user_preference).toBe(_fpa.state.current_user_preference);
    expect(data.environment_name).toBe('test');

    const res = _fpa.substitution.substitute('{{now::date}}|{{user_preference.date_format::uppercase}}', record);
    expect(res).toBe('12/10/1989|MM/DD/YYYY');
  });

  it('does not resolve inherited Object.prototype members as substitution tags', function () {
    expect(_fpa.substitution.substitute('[{{constructor}}][{{toString}}]', {})).toBe('[(?)][(?)]');
    expect(_fpa.substitution.compile_config_string('[{{constructor}}][{{hasOwnProperty}}]')({})).toBe('[][]');
    expect(_fpa.substitution.compile_config_string('[{{constructor}}]')({ id: 1 })).toBe('[]');
  });

  it('does not throw for non-object substitution contexts', function () {
    expect(function () { _fpa.substitution.substitute('Hi {{missing}}', 'text'); }).not.toThrow();
    expect(_fpa.substitution.substitute('Hi {{missing}}', null)).toBe('Hi (?)');
    expect(_fpa.substitution.compile_config_string('{{missing}}|{{base_url}}')(null))
      .toBe('|https://example.test');
  });
});
