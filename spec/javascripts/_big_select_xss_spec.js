/**
 * Purpose: verify $.big_select renders item keys safely, and renders labels as text
 * when the escape_labels option is set (used for stored filenames in the markdown
 * image chooser), while leaving labels as HTML by default for configured content.
 * Issue: #1492 (review follow-up).
 */
describe('$.big_select escaping for Issue #1492', function () {
  var hostileLabel = '<img src=x data-xss-probe="bs" onerror="window.__bs_xss=1">.png';
  var $wrapper;
  var $field;
  var $target;

  var open_big_select = function (hash, options) {
    $.big_select($field, $target, { big_select_default: hash }, null, null, options);
    $field.trigger('focus');
  };

  beforeEach(function () {
    delete window.__bs_xss;
    spyOn(_fpa.utils, 'scrollTo');

    $wrapper = $('<span class="big-select-wrapper" id="bsw-1492"></span>').appendTo('body');
    $field = $('<input type="text" class="use-big-select" id="bs-field-1492" readonly>').appendTo($wrapper);
    $('<input type="text" id="bs-field-1492---overlay">').appendTo($wrapper);
    $target = $('<div id="bs-target-1492"></div>').appendTo('body');
  });

  afterEach(function () {
    $wrapper.remove();
    $target.remove();
    delete window.__bs_xss;
  });

  it('renders labels as text when escape_labels is set', function (done) {
    open_big_select({ '/files/1': hostileLabel }, { hide_key: true, hide_popover: true, escape_labels: true });

    expect($target.find('.big-select-item img').length).toBe(0);
    expect($target.find('.bsi--head').first().text()).toBe(hostileLabel);
    window.setTimeout(function () {
      expect(window.__bs_xss).toBeUndefined();
      done();
    }, 50);
  });

  it('renders group titles as text when escape_labels is set', function () {
    open_big_select({ '<b data-xss-probe="group">g</b>': { '/files/1': 'one.png' } },
      { hide_key: true, hide_popover: true, escape_labels: true });

    expect($target.find('.big-select-group-head b').length).toBe(0);
    expect($target.find('.big-select-group-head a').text()).toContain('<b data-xss-probe="group">g</b>');
  });

  it('keeps HTML in labels by default for configured content', function () {
    open_big_select({ one: '<b class="kept">bold</b> label' }, { hide_popover: true });

    expect($target.find('.big-select-item .kept').length).toBe(1);
  });

  it('keeps a key containing quotes inside its attribute and selects it exactly', function () {
    var key = '/files/a"b" data-xss-marker="y"';
    open_big_select({ [key]: 'label' }, { hide_key: true, hide_popover: true, escape_labels: true });

    var $item = $target.find('.big-select-item').first();
    expect($item.attr('data-bsi-key')).toBe(key);
    expect($item.attr('data-xss-marker')).toBeUndefined();

    $item.trigger('click');
    expect($field.val()).toBe(key);
  });
});
