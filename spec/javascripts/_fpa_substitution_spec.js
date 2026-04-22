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