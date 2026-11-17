/**
 * Purpose: verify the secure viewer shows a filestore filename as literal text
 * in its header, whichever link supplied it, so a stored filename cannot inject markup.
 * Issue: #1492 (review follow-up).
 */
describe('SecureView file name rendering for Issue #1492', function () {
  var hostileName = '<img src=x data-xss-probe="sv" onerror="window.__sv_xss=1">.pdf';
  var sv;
  var $block;
  var $file_name;

  beforeEach(function () {
    delete window.__sv_xss;

    sv = new SecureView();
    spyOn(sv, 'get_info');
    spyOn(sv, 'show_first_page');
    spyOn(sv, 'set_controls');
    spyOn(sv, 'setup_search');
    spyOn(sv, 'close');

    $file_name = $('<span class="secure-view-file-name"></span>').appendTo('body');
    $block = $('<div class="sv-test-block"></div>').appendTo('body');
  });

  afterEach(function () {
    $block.remove();
    $file_name.remove();
    $('body').removeClass('fixed-overlay');
    delete window.__sv_xss;
  });

  it('shows a filename taken from the title attribute (icon links) as text', function (done) {
    var $link = $('<a class="browse-icon" href="/nfs_store/downloads/1"></a>')
      .attr('title', hostileName)
      .appendTo($block);

    sv.setup_links($block, 'a.browse-icon', { attr_for_filename: 'title', link_type: 'icon' });
    $link.trigger('click');

    expect($file_name.find('img').length).toBe(0);
    expect($file_name.text()).toBe(hostileName);
    window.setTimeout(function () {
      expect(window.__sv_xss).toBeUndefined();
      done();
    }, 50);
  });

  it('shows a filename taken from the link text as text', function () {
    $('<a class="browse-filename" href="/nfs_store/downloads/1"></a>')
      .text(hostileName)
      .appendTo($block);

    sv.setup_links($block, 'a.browse-filename', {});
    $block.find('a').trigger('click');

    expect($file_name.find('img').length).toBe(0);
    expect($file_name.text()).toBe(hostileName);
  });
});
