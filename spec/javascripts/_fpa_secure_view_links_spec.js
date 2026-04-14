/**
 * Tests for _fpa.form_utils.setup_secure_view_links
 *
 * Issue: #1040 - Reports don't handle secure viewer with Redcap files
 *
 * The secure viewer should recognize both NFS store download links
 * (URLs containing /nfs_store/downloads) and Redcap file download links
 * (URLs containing /redcap/project_user_requests/ with /download_field_file/).
 *
 * Links matching either pattern should receive the appropriate class
 * so the secure viewer can handle them.
 */
describe('setup_secure_view_links', function () {

  var $block;

  beforeEach(function () {
    // Set up _fpa.state.user_can to simulate a user with file viewing permissions
    _fpa.state = _fpa.state || {};
    _fpa.state.user_can = { view_files_as_image: true };

    // Mock _fpa.secure_view.setup_links to avoid full secure viewer initialization
    _fpa.secure_view = _fpa.secure_view || {};
    _fpa.secure_view.setup_links = function () {};
  });

  afterEach(function () {
    if ($block) {
      $block.remove();
      $block = null;
    }
  });

  it('adds use-secure-view class to NFS store download links', function () {
    $block = $('<div>' +
      '<a href="/nfs_store/downloads/123?retrieve=abc">file.pdf</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    expect($block.find('a').hasClass('use-secure-view')).toBe(true);
  });

  it('does not add use-secure-view class to NFS links inside nfs-store-container-block', function () {
    $block = $('<div>' +
      '<div class="nfs-store-container-block">' +
      '<a href="/nfs_store/downloads/123">file.pdf</a>' +
      '</div>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    expect($block.find('a').hasClass('use-secure-view')).toBe(false);
  });

  it('adds redcap-file-use-secure-view class to Redcap download_field_file links', function () {
    $block = $('<div>' +
      '<a href="/redcap/project_user_requests/dynamic_model__press_bp_measurement_rcs/download_field_file/uploaded_bp_form/33">bp_form.pdf</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    expect($block.find('a').hasClass('redcap-file-use-secure-view')).toBe(true);
  });

  it('adds redcap-file-use-secure-view class to various Redcap file URL patterns', function () {
    $block = $('<div>' +
      '<a id="link1" href="/redcap/project_user_requests/dynamic_model__some_model/download_field_file/some_field/1">file1.pdf</a>' +
      '<a id="link2" href="/redcap/project_user_requests/dynamic_model__another_model_rcs/download_field_file/another_field/999">file2.png</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    expect($block.find('#link1').hasClass('redcap-file-use-secure-view')).toBe(true);
    expect($block.find('#link2').hasClass('redcap-file-use-secure-view')).toBe(true);
  });

  it('does not add secure view classes to unrelated links', function () {
    $block = $('<div>' +
      '<a href="/masters/123">Master Record</a>' +
      '<a href="https://example.com/file.pdf">External Link</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    var links = $block.find('a');
    links.each(function () {
      expect($(this).hasClass('use-secure-view')).toBe(false);
      expect($(this).hasClass('redcap-file-use-secure-view')).toBe(false);
    });
  });

  it('handles a block with both NFS and Redcap links', function () {
    $block = $('<div>' +
      '<a id="nfs-link" href="/nfs_store/downloads/456?retrieve=def">nfs_file.pdf</a>' +
      '<a id="rc-link" href="/redcap/project_user_requests/dynamic_model__test_rcs/download_field_file/doc_field/77">rc_file.pdf</a>' +
      '<a id="plain-link" href="/masters/1">Master</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    expect($block.find('#nfs-link').hasClass('use-secure-view')).toBe(true);
    expect($block.find('#rc-link').hasClass('redcap-file-use-secure-view')).toBe(true);
    expect($block.find('#plain-link').hasClass('use-secure-view')).toBe(false);
    expect($block.find('#plain-link').hasClass('redcap-file-use-secure-view')).toBe(false);
  });

  it('does not re-process a block already marked as setup', function () {
    $block = $('<div class="use-secure-view-on-links-setup">' +
      '<a href="/redcap/project_user_requests/dynamic_model__test/download_field_file/field/1">file.pdf</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    // Should not add class since block is already setup
    expect($block.find('a').hasClass('redcap-file-use-secure-view')).toBe(false);
  });

  it('does not add duplicate class to links that already have redcap-file-use-secure-view', function () {
    $block = $('<div>' +
      '<a class="redcap-file-use-secure-view" href="/redcap/project_user_requests/dynamic_model__test/download_field_file/field/1">file.pdf</a>' +
      '</div>');
    $('body').append($block);

    _fpa.form_utils.setup_secure_view_links($block);

    // The class should still be there (not doubled)
    var classes = $block.find('a').attr('class').split(/\s+/);
    var count = classes.filter(function (c) { return c === 'redcap-file-use-secure-view'; }).length;
    expect(count).toBe(1);
  });
});
