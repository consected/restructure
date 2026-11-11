/**
 * Purpose: verify selected file values are submitted as one JSON array field,
 * without duplicate hidden inputs or submitted checkbox names.
 * Issue: #1551.
 */
describe('selected items form serialization for Issue #1551', function () {
  var $form;

  beforeEach(function () {
    $form = $('<form>' +
      '<input type="checkbox" class="file-selector" name="nfs_store_download[selected_items][]" ' +
      'value="{&quot;id&quot;: 12, &quot;retrieval_type&quot;: &quot;stored_file&quot;}" checked>' +
      '<input type="checkbox" class="file-selector" name="nfs_store_download[selected_items][]" ' +
      'value="{&quot;id&quot;: 13, &quot;retrieval_type&quot;: &quot;archived_file&quot;}" checked>' +
      '<input type="checkbox" class="file-selector" name="nfs_store_download[selected_items][]" ' +
      'value="{&quot;id&quot;: 14, &quot;retrieval_type&quot;: &quot;stored_file&quot;}">' +
      '</form>');
    $('body').append($form);
  });

  afterEach(function () {
    $form.remove();
  });

  it('stores the checked values in one JSON parameter and replaces it on repeated calls', function () {
    _fpa.form_utils.set_json_array_param(
      $form, '.file-selector', 'nfs_store_download[selected_items_json]', false
    );
    _fpa.form_utils.set_json_array_param(
      $form, '.file-selector', 'nfs_store_download[selected_items_json]', false
    );

    var $jsonFields = $form.find('input[name="nfs_store_download[selected_items_json]"]');
    expect($jsonFields.length).toBe(1);
    expect(JSON.parse($jsonFields.val())).toEqual([
      { id: 12, retrieval_type: 'stored_file' },
      { id: 13, retrieval_type: 'archived_file' }
    ]);
  });

  it('excludes disabled checked checkboxes and leaves their names untouched', function (done) {
    var $checkboxes = $form.find('.file-selector');
    $checkboxes.eq(1).prop('disabled', true);

    _fpa.form_utils.set_json_array_param(
      $form, '.file-selector', 'nfs_store_download[selected_items_json]', true
    );

    var jsonField = $form.find('input[name="nfs_store_download[selected_items_json]"]').val();
    expect(JSON.parse(jsonField)).toEqual([
      { id: 12, retrieval_type: 'stored_file' }
    ]);
    expect($checkboxes.eq(0).attr('name')).toBeUndefined();
    expect($checkboxes.eq(1).attr('name')).toBe('nfs_store_download[selected_items][]');

    window.setTimeout(function () {
      expect($checkboxes.eq(1).attr('name')).toBe('nfs_store_download[selected_items][]');
      done();
    }, 0);
  });

  it('replaces container selections when the checked files change', function () {
    var $checkboxes = $form.find('.file-selector').addClass('container-file-selector').removeAttr('name');
    var fieldName = 'nfs_store_download[selected_items_json]';

    _fpa.form_utils.set_json_array_param($form, '.container-file-selector', fieldName, false);
    $checkboxes.eq(0).prop('checked', false);
    $checkboxes.eq(2).prop('checked', true);
    _fpa.form_utils.set_json_array_param($form, '.container-file-selector', fieldName, false);

    var $jsonFields = $form.find('input[type="hidden"]').filter(function () {
      return $(this).attr('name') === fieldName;
    });
    expect($jsonFields.length).toBe(1);
    expect(JSON.parse($jsonFields.val())).toEqual([
      { id: 13, retrieval_type: 'archived_file' },
      { id: 14, retrieval_type: 'stored_file' }
    ]);
    expect($checkboxes.filter('[name]').length).toBe(0);
  });

  it('removes stale JSON when a checked value is invalid', function () {
    var fieldName = 'nfs_store_download[selected_items_json]';
    _fpa.form_utils.set_json_array_param($form, '.file-selector', fieldName, false);
    $form.find('.file-selector').first().val('{invalid json');

    expect(_fpa.form_utils.set_json_array_param($form, '.file-selector', fieldName, false)).toBe(false);
    expect($form.find('input[type="hidden"]').filter(function () {
      return $(this).attr('name') === fieldName;
    }).length).toBe(0);
  });

  it('temporarily removes configured checkbox names for the current submission', function (done) {
    var $checkboxes = $form.find('.file-selector');
    _fpa.form_utils.set_json_array_param(
      $form, '.file-selector', 'nfs_store_download[selected_items_json]', true
    );

    expect($checkboxes.eq(0).attr('name')).toBeUndefined();
    expect($form.find('input[name="nfs_store_download[selected_items_json]"]').length).toBe(1);
    window.setTimeout(function () {
      expect($checkboxes.eq(0).attr('name')).toBe('nfs_store_download[selected_items][]');
      done();
    }, 0);
  });

  it('uses only the new report selection and restores checkbox names after each call', function (done) {
    var $checkboxes = $form.find('.file-selector');
    var fieldName = 'nfs_store_download[selected_items_json]';
    var checkboxName = 'nfs_store_download[selected_items][]';

    _fpa.form_utils.set_json_array_param($form, '.file-selector', fieldName, true);
    expect($checkboxes.eq(0).attr('name')).toBeUndefined();
    expect($checkboxes.eq(1).attr('name')).toBeUndefined();
    expect($checkboxes.eq(2).attr('name')).toBe(checkboxName);

    window.setTimeout(function () {
      expect($checkboxes.filter('[name]').length).toBe(3);
      $checkboxes.eq(0).prop('checked', false);
      $checkboxes.eq(1).prop('checked', false);
      $checkboxes.eq(2).prop('checked', true);

      _fpa.form_utils.set_json_array_param($form, '.file-selector', fieldName, true);
      expect($form.find('input[name="nfs_store_download[selected_items_json]"]').length).toBe(1);
      expect(JSON.parse($form.find('input[name="nfs_store_download[selected_items_json]"]').val())).toEqual([
        { id: 14, retrieval_type: 'stored_file' }
      ]);
      expect($checkboxes.eq(0).attr('name')).toBe(checkboxName);
      expect($checkboxes.eq(1).attr('name')).toBe(checkboxName);
      expect($checkboxes.eq(2).attr('name')).toBeUndefined();

      window.setTimeout(function () {
        expect($checkboxes.filter('[name]').length).toBe(3);
        expect($checkboxes.eq(2).attr('name')).toBe(checkboxName);
        done();
      }, 0);
    }, 0);
  });
});
