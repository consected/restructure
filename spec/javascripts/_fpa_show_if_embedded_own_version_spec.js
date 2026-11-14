//= require app/_fpa_show_if.js
// Covers issue 1481 validation: an embedded item (such as a dynamic model embedded in an activity log) must have
// its show_if definition looked up under ITS OWN definition version slot, never under the parent's version slot,
// even when the parent block carries a data-vdef-version attribute from the parent's form or wrapper.
// The parent and embedded item deliberately have different version tokens. The data carries matching
// def_version and vdef_version values so the same specs run before and after the lazy template config phases.
describe('show_if embedded item own definition version', function () {
  var parent_defs, embedded_defs, wrong_slot_defs, original_forms, original_roles;

  function build_block(attrs, inner_html) {
    var block = $('<div class="common-template-item"></div>');
    block.attr(attrs);
    block.html(inner_html || '');
    return block;
  }

  function parent_data(embedded) {
    return {
      item_type: 'parent_type',
      full_option_type: 'parent_type_default',
      def_version: 500,
      vdef_version: 'v500',
      embedded_item: embedded
    };
  }

  function embedded_data() {
    return {
      item_type: 'embedded_type',
      full_option_type: 'embedded_type',
      def_version: 77,
      vdef_version: 'v77'
    };
  }

  beforeEach(function () {
    original_forms = _fpa.show_if.forms;
    original_roles = _fpa.state.current_user_roles;
    _fpa.state.current_user_roles = [];

    parent_defs = { parent_field: {} };
    embedded_defs = { embedded_field: { embedded_trigger: 'own' } };
    wrong_slot_defs = { embedded_field: { embedded_trigger: 'parent token' } };

    _fpa.show_if.forms = {
      parent_type_default: { v500: parent_defs },
      embedded_type: { v77: embedded_defs, v500: wrong_slot_defs }
    };

    spyOn(_fpa.show_if.methods, 'do_show_items');
    spyOn(_fpa.show_if.methods, 'handle_post_show_if');
  });

  afterEach(function () {
    _fpa.show_if.forms = original_forms;
    _fpa.state.current_user_roles = original_roles;
  });

  it('uses the embedded item version slot when the parent form block carries the parent version', function () {
    var block = build_block(
      { 'data-item-class': 'parent_type', 'data-def-version': '500' },
      '<form data-vdef-version="v500"></form>'
    );
    var data = parent_data(embedded_data());

    _fpa.show_if.methods.show_items(block, data);

    var calls = _fpa.show_if.methods.do_show_items.calls.allArgs();
    var embedded_call = calls.find(function (args) { return args[2] === 'embedded_type'; });

    expect(embedded_call).toBeDefined();
    expect(embedded_call[4]).toBe(embedded_defs);
    expect(embedded_call[4]).not.toBe(wrong_slot_defs);
  });

  it('uses the embedded item version slot when the parent wrapper itself carries the parent version', function () {
    var block = build_block({ 'data-item-class': 'parent_type', 'data-vdef-version': 'v500' });
    var data = parent_data(embedded_data());

    _fpa.show_if.methods.show_items(block, data);

    var calls = _fpa.show_if.methods.do_show_items.calls.allArgs();
    var embedded_call = calls.find(function (args) { return args[2] === 'embedded_type'; });

    expect(embedded_call).toBeDefined();
    expect(embedded_call[4]).toBe(embedded_defs);
  });

  it('still uses the parent version slot for the parent item', function () {
    var block = build_block(
      { 'data-item-class': 'parent_type', 'data-def-version': '500' },
      '<form data-vdef-version="v500"></form>'
    );
    var data = parent_data(embedded_data());

    _fpa.show_if.methods.show_items(block, data);

    var calls = _fpa.show_if.methods.do_show_items.calls.allArgs();
    var parent_call = calls.find(function (args) { return args[2] === 'parent_type'; });

    expect(parent_call).toBeDefined();
    expect(parent_call[4]).toBe(parent_defs);
  });
});
