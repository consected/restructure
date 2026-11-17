/**
 * Purpose: verify filestore paths and filenames remain literal text in the move
 * modal and its action fields, preventing stored XSS from user-controlled names.
 * Issue: #1492.
 */
describe('NFS store browser XSS protection for Issue #1492', function () {
  var containerId = '1492';
  var hostilePath = '<img src=x onerror="window.__xss=1">';
  var $modal;
  var $outer;
  var previousXssValue;
  var bodyHadPreventTransition;

  beforeEach(function () {
    previousXssValue = window.__xss;
    delete window.__xss;
    bodyHadPreventTransition = $('body').hasClass('prevent-page-transition');

    $modal = $('<div id="primary-modal">' +
      '<div class="modal-title"></div>' +
      '<div class="modal-body"></div>' +
      '</div>');
    $('body').append($modal);

    $outer = $('<div class="container-browser-outer" data-container-id="' + containerId + '">' +
      '<div id="container-browser-' + containerId + '" class="container-browser" ' +
      'data-can-submit-download="true" data-can-submit-move-files="true"></div>' +
      '<a href="#" class="container-browse-move-files" ' +
      'data-target-browser="#container-browser-' + containerId + '">Move Files</a>' +
      '<a href="#" class="container-browse-rename-file" ' +
      'data-target-browser="#container-browser-' + containerId + '">Rename file</a>' +
      '<div class="container-browse-action-form hidden" id="container-browse-move-files-form-' + containerId + '">' +
      '<form onsubmit="return false" class="form-formatted">' +
      '<div class="browse-move-to-folders"></div>' +
      '<div class="form-group">' +
      '<input class="container-new-folder-name form-control" name="new_folder" value="">' +
      '</div>' +
      '<div class="form-group">' +
      '<p class="container-browser-move-from"></p>' +
      '<input class="container-browse-action-extra-params form-control" name="new_path" value="">' +
      '</div>' +
      '<div class="form-group">' +
      '<button class="container-browse-move-files-submit" ' +
      'data-target-browser="#container-browser-' + containerId + '">Move files</button>' +
      '</div>' +
      '</form>' +
      '</div>' +
      '<div class="container-browse-action-form hidden" id="container-browse-rename-file-form-' + containerId + '">' +
      '<form><input class="container-browse-action-extra-params" name="new_name" value=""></form>' +
      '</div>' +
      '<form><div class="extra_params"></div>' +
      '<button id="container-browse-move-files-in-form-' + containerId + '"></button></form>' +
      '</div>');

    var $folder = $('<li class="container-folder checked"></li>');
    $folder.append($('<input type="checkbox" checked>').attr('data-folder-path', hostilePath));
    var $folderItems = $('<ul class="container-folder-items"></ul>')
      .attr('data-folder-items', hostilePath)
      .attr('id', 'folder-' + containerId);
    var $file = $('<li class="container-entry"></li>');
    $file.append('<input type="checkbox" checked>');
    $file.append($('<a class="browse-filename"></a>').text('file & <name>.txt'));
    $folderItems.append($file);
    $outer.find('.container-browser').append($folder, $folderItems);
    $('body').append($outer);

    spyOn(_fpa, 'show_modal').and.callFake(function (message, title) {
      $modal.find('.modal-title').text(title);
      $modal.find('.modal-body').html(message);
    });
  });

  afterEach(function () {
    // fs_browser binds delegated handlers on document that outlive the fixture
    $(document)
      .off('click', '.refresh-container-list[data-container-id="' + containerId + '"]')
      .off('change', 'input[name="container-meta-controls-' + containerId + '"]');
    $('body').toggleClass('prevent-page-transition', bodyHadPreventTransition);
    $outer.remove();
    $modal.remove();
    if (previousXssValue === undefined) {
      delete window.__xss;
    } else {
      window.__xss = previousXssValue;
    }
  });

  it('renders a hostile folder path as text when opening Move Files', function (done) {
    _nfs_store.fs_browser($outer);

    $outer.find('.container-browse-move-files').trigger('click');

    expect($modal.find('.container-browser-move-from img').length).toBe(0);
    expect($modal.find('.container-browser-move-from').text()).toBe(hostilePath);
    window.setTimeout(function () {
      expect(window.__xss).toBeUndefined();
      done();
    }, 50);
  });

  it('checks child files when selecting a folder path containing double quotes', function () {
    var quotedPath = 'a"b"c';
    var $quotedFolder = $('<li class="container-folder"><input type="checkbox"></li>');
    var $quotedItems = $('<ul class="container-folder-items"><li class="container-entry">' +
      '<input type="checkbox"></li></ul>');
    $quotedFolder.find('input').attr('data-folder-path', quotedPath);
    $quotedItems.attr('data-folder-items', quotedPath);
    $outer.find('.container-browser').append($quotedFolder, $quotedItems);

    _nfs_store.fs_browser($outer);
    $quotedFolder.find('input').prop('checked', true).trigger('change');

    expect($quotedItems.find('input[type="checkbox"]').prop('checked')).toBe(true);
  });

  it('does not select a folder checkbox without a path when an entry has no parent folder', function () {
    var $orphanFolder = $('<li class="container-folder"><input type="checkbox"></li>');
    var $orphanEntry = $('<li class="container-entry"><input type="checkbox"></li>');
    $outer.find('.container-browser').append($orphanFolder, $orphanEntry);

    _nfs_store.fs_browser($outer);
    $orphanEntry.find('input').prop('checked', true).trigger('change');

    expect($orphanFolder.find('input').prop('checked')).toBe(false);
  });

  it('preserves a hostile folder path in the add-folder checkbox data attribute', function () {
    _nfs_store.fs_browser($outer);
    $outer.find('.container-browse-move-files').trigger('click');

    expect($modal.find('input.container-folder-add').first().attr('data-folder-path')).toBe(hostilePath);
  });

  it('preserves the exact new path in the hidden action input', function () {
    var newPath = 'a"b"c & <folder>';
    _nfs_store.fs_browser($outer);
    $outer.find('.container-browse-move-files').trigger('click');
    $modal.find('input[name="new_path"]').val(newPath);

    $modal.find('.container-browse-move-files-submit').trigger('click');

    expect($outer.find('.extra_params input[name="nfs_store_download[new_path]"]').val()).toBe(newPath);
  });

  it('binds a single keyup handler on the new folder name however many add-folder links are clicked', function () {
    var $childFolder = $('<li class="container-folder"></li>');
    var $childItems = $('<ul class="container-folder-items" data-folder-items="child" id="child-1492"></ul>');
    $outer.find('.container-folder-items').first().append($childFolder, $childItems);

    _nfs_store.fs_browser($outer);
    $outer.find('.container-browse-move-files').trigger('click');

    var $add_links = $modal.find('a.container-add');
    expect($add_links.length).toBe(2);
    $add_links.eq(0).trigger('click');
    $add_links.eq(1).trigger('click');

    var $cnfn = $modal.find('.container-new-folder-name');
    expect($._data($cnfn[0], 'events').keyup.length).toBe(1);

    $cnfn.val('sub').trigger('keyup');
    expect($modal.find('input[name="new_path"]').val()).toBe('child/sub');
  });

  it('prefills rename with the literal filename containing HTML entities', function () {
    var filename = 'file & <name>.txt';
    _nfs_store.fs_browser($outer);
    $outer.find('.container-browse-rename-file').trigger('click');

    expect($modal.find('input[name="new_name"]').val()).toBe(filename);
  });
});