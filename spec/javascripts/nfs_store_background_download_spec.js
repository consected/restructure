/**
 * Purpose: verify the filestore browser submits native downloads for small selections
 * and shows a notice instead of submitting when the server queues a background archive.
 */
describe('NFS store background downloads', function () {
  var containerId = 'background-download-spec';
  var $outer;
  var $form;
  var $reportOuter;
  var previousPreventTransition;

  beforeEach(function () {
    previousPreventTransition = $('body').hasClass('prevent-page-transition');
    $outer = $('<div class="container-browser-outer" data-container-id="' + containerId + '">' +
      '<form method="post" action="/nfs_store/downloads" target="download_files">' +
      '<input type="hidden" name="authenticity_token" value="test-token">' +
      '<div id="container-browser-' + containerId + '" class="container-browser" ' +
      'data-can-submit-download="true"><div class="container-entry">' +
      '<input type="checkbox" class="container-file-selector" checked ' +
      'value="{&quot;id&quot;:1,&quot;container_id&quot;:1,&quot;retrieval_type&quot;:&quot;stored_file&quot;}">' +
      '</div></div>' +
      '<input type="submit" name="commit" value="Download" id="container-browse-download-in-form-' + containerId + '">' +
      '<button type="submit" id="container-browse-download-' + containerId + '" ' +
      'class="container-browse-download" data-target-browser="#container-browser-' + containerId + '"></button>' +
      '</form></div>');
    $form = $outer.find('form');
    $('body').append($outer);
    spyOn(_fpa.form_utils, 'set_auth_tokens').and.callFake(function () {});
    spyOn(_fpa, 'flash_notice');
    _nfs_store.fs_browser($outer);
  });

  afterEach(function () {
    $(document).off('click', '.refresh-container-list[data-container-id="' + containerId + '"]');
    $('body').toggleClass('prevent-page-transition', previousPreventTransition);
    $outer.remove();
    if ($reportOuter) $reportOuter.remove();
    $('#itemselection-for-report').remove();
    $reportOuter = null;
  });

  function ajax_response(response) {
    spyOn($, 'ajax').and.callFake(function () {
      return {
        done: function (callback) {
          callback(response);
          return { fail: function () {} };
        }
      };
    });
  }

  it('submits the normal download form when the server returns the download action', function () {
    ajax_response({ action: 'download' });
    spyOn($form[0], 'submit');
    var defaultSubmitEvents = 0;
    $form.on('submit', function (e) {
      defaultSubmitEvents++;
      e.preventDefault();
    });

    $outer.find('.container-browse-download').trigger('click');

    expect($.ajax).toHaveBeenCalled();
    expect($form[0].submit).toHaveBeenCalled();
    expect(defaultSubmitEvents).toBe(0);
    expect(_fpa.flash_notice).not.toHaveBeenCalled();
    expect($form.find('input[type="hidden"][name="commit"]').length).toBe(0);
    expect($form.find('input[name="check_only"]').length).toBe(0);
  });

  it('shows the server message and does not submit the form for a background action', function () {
    ajax_response({ action: 'background', message: 'Your files are being prepared.' });
    spyOn($form[0], 'submit');

    $outer.find('.container-browse-download').trigger('click');

    expect(_fpa.flash_notice).toHaveBeenCalledWith('Your files are being prepared.');
    expect($form[0].submit).not.toHaveBeenCalled();
    expect($form.find('input[type="hidden"][name="commit"]').length).toBe(0);
    expect($form.find('input[name="check_only"]').length).toBe(0);
  });

  it('removes temporary fields after an unexpected JSON response', function () {
    ajax_response({ unexpected: true });
    spyOn($form[0], 'submit');

    $outer.find('.container-browse-download').trigger('click');

    expect(_fpa.flash_notice).toHaveBeenCalledWith('The download request could not be processed.', 'danger');
    expect($form.find('input[type="hidden"][name="commit"]').length).toBe(0);
    expect($form.find('input[name="check_only"]').length).toBe(0);
  });

  it('removes temporary fields after the check request fails', function () {
    spyOn($, 'ajax').and.returnValue({
      done: function () {
        return {
          fail: function (callback) {
            callback();
          }
        };
      }
    });
    spyOn($form[0], 'submit');

    $outer.find('.container-browse-download').trigger('click');

    expect(_fpa.flash_notice).toHaveBeenCalledWith(
      'The download request could not be processed. Please try again.', 'danger'
    );
    expect($form.find('input[type="hidden"][name="commit"]').length).toBe(0);
    expect($form.find('input[name="check_only"]').length).toBe(0);
  });

  it('submits a blocked-symlink download normally without showing an AJAX error', function () {
    spyOn($, 'ajax').and.callFake(function () {
      return {
        done: function () {
          return {
            fail: function (callback) {
              callback({ status: 409, responseJSON: { blocked: true, reason: 'symbolic_link' } });
            }
          };
        }
      };
    });
    spyOn($form[0], 'submit');

    $outer.find('.container-browse-download').trigger('click');

    expect($.ajax.calls.mostRecent().args[0].global).toBe(false);
    expect($form[0].submit).toHaveBeenCalled();
    expect(_fpa.flash_notice).not.toHaveBeenCalled();
    expect($form.find('input[type="hidden"][name="commit"]').length).toBe(0);
    expect($form.find('input[name="check_only"]').length).toBe(0);
  });

  it('sends only one check while duplicate browser handlers are in flight', function () {
    var resolveRequest;
    spyOn($, 'ajax').and.callFake(function () {
      return {
        done: function (callback) {
          resolveRequest = callback;
          return { fail: function () {} };
        }
      };
    });
    _nfs_store.fs_browser($outer);

    $outer.find('.container-browse-download').trigger('click');

    expect($.ajax.calls.count()).toBe(1);
    resolveRequest({ action: 'background', message: 'Your files are being prepared.' });
  });

  it('submits report downloads in the current window and serializes selected items once', function () {
    $reportOuter = $('<div class="report-container" data-report-id="42">' +
      '<div class="report-results-table-block"><table class="report-table">' +
      '<thead><tr><th data-col-type="select items: download files">' +
      '<p>select items: download files</p></th></tr></thead>' +
      '<tbody><tr><td data-col-type="select items: download files">' +
      '[{"field_name":"selected[]","value":{"id":1,"container_id":1,"retrieval_type":"stored_file","init_value":true}}]' +
      '</td></tr></tbody></table></div></div>');
    $('body').append($reportOuter);
    _fpa.reports.results_select_items_for_form($reportOuter);
    var $reportForm = $('#itemselection-for-report');
    var submittedTarget = 'not-submitted';
    spyOn(_fpa.form_utils, 'set_json_array_param').and.callThrough();
    spyOn($, 'ajax').and.callFake(function () {
      return {
        done: function (callback) {
          callback({ action: 'download' });
          return { fail: function () {} };
        }
      };
    });
    spyOn($reportForm[0], 'submit').and.callFake(function () {
      submittedTarget = $(this).attr('target');
    });

    $reportForm.trigger('submit');

    expect($reportForm[0].submit).toHaveBeenCalled();
    expect($.ajax.calls.mostRecent().args[0].global).toBe(false);
    expect(submittedTarget).toBeUndefined();
    expect(_fpa.form_utils.set_json_array_param.calls.count()).toBe(1);
  });
});
