//= require app/_fpa.js

// These specs verify that CSRF AJAX responses use form-error handling without
// changing the existing handling for other forbidden responses.

describe('_fpa AJAX error handling', function () {
  var ajaxSelector = "form[data-remote='true'], a, btn";
  var originalRemotesSetup;
  var $form;

  beforeEach(function () {
    originalRemotesSetup = _fpa.state.remotes_setup;
    _fpa.state.remotes_setup = false;
    $form = $('<form data-remote="true" class="ajax-running"></form>').appendTo('body');

    spyOn(_fpa.form_utils, 'set_field_errors');
    spyOn(_fpa, 'flash_notice');
    spyOn(_fpa.postprocessors, 'after_error');

    _fpa.handle_remotes();
  });

  afterEach(function () {
    $(document).off('click ajax:before ajax:beforeSend ajax:success ajax:error', ajaxSelector);
    $form.remove();
    _fpa.state.remotes_setup = originalRemotesSetup;
  });

  it('uses the form-error path for a forbidden AJAX response', function () {
    var responseJson = { message: ['The authenticity token is invalid.'] };
    var xhr = {
      status: 403,
      responseJSON: responseJson,
      responseText: JSON.stringify(responseJson),
      getResponseHeader: function (header) {
        return header === 'X-ReStructure-Error' ? 'invalid-authenticity-token' : null;
      }
    };

    $form.trigger('ajax:error', [xhr, 'error', 'Forbidden']);

    expect(_fpa.form_utils.set_field_errors).toHaveBeenCalledWith(jasmine.anything(), responseJson);
    expect(_fpa.flash_notice).toHaveBeenCalledWith(jasmine.stringMatching('Could not complete action:'), 'warning');
  });

  it('uses the forbidden message for a generic forbidden AJAX response', function () {
    var xhr = {
      status: 403,
      responseText: ''
    };

    $form.trigger('ajax:error', [xhr, 'error', 'Forbidden']);

    expect(_fpa.form_utils.set_field_errors).not.toHaveBeenCalled();
    expect(_fpa.flash_notice).toHaveBeenCalledWith(
      'Forbidden access to the requested resource. Please refresh the page and try again.',
      'danger'
    );
  });
});
