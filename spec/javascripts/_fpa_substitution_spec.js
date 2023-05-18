//= require app/_fpa_form_utils.js
//= require app/_fpa_substitution.js
describe('substitutions', function () {


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
    const text = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase::3}}. Split {{piped::split_pipe::1}}. Is data {{hash.key2}}. Is array {{array::2}} or {{array.1.key}} or {{array.3}}. JSON {{json.json_parse.jkey3.1}}. Array 0 {{array.0}}</p>'
    const use_data = {
      master_id: 5541,
      name: 'test name bob',
      piped: 'data 1|data 2|data 3',
      hash: { key1: 123, key2: 456, key3: 789 },
      array: ['55', { key: '66' }, '77', '88'],
      json: '{"jkey1": 22, "jkey2": "abc", "jkey3": [1230,4560]}'
    };

    const expected_text = '<p>This is some content.</p><p>Related to master_id 5541. This is a name: TEST. Split data 2. Is data 456. Is array 77 or 66 or 88. JSON 4560. Array 0 55</p>'
    const res = _fpa.substitution.substitute(text, use_data);
    expect(res).toEqual(expected_text)

  });
});