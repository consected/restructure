//= require app/_fpa.js

// _fpa.initialize_app Spec - Admin Non-Blocking Template Load (issue #1181)
//
// Verifies that when the page is an admin page (indicated by
// _fpa.state.is_admin_page === true) the main template AJAX fetch does not
// block the page with the "loading..." splash guard. The admin page should
// be presented to the user immediately and templates loaded asynchronously
// in the background.
//
// Conversely, when not on an admin page, the splash guard must remain in
// place until templates are loaded (existing behaviour preserved).

describe('_fpa.initialize_app admin non-blocking template load', function () {
  var originalState;
  var ajaxDeferred;

  beforeEach(function () {
    originalState = _fpa.state;
    _fpa.state = {
      caption_before: {},
      dialog_before: {},
      template_config: {},
      template_config_versions: {},
      controller_name: 'admin',
      action_name: 'index',
      template_version: 'v1',
      rails_env: 'test',
      current_user: { id: 1, app_type_id: 1 },
      current_admin: { id: 1 }
    };
    _fpa.status = _fpa.status || {};
    _fpa.status.one_time_setup_run = false;
    _fpa.status.loaded_templates = false;
    _fpa.status.html_ready = false;
    _fpa.status.pending_template_retrieves = 0;

    $('body').removeClass('status-compiling status-compiled initial-compiling status-failed-compilation');
    $('body').addClass('initial-compiling');

    // Stub helpers that initialize_app calls so the test is hermetic.
    spyOn(_fpa.loaded, 'preload');
    spyOn(_fpa, 'handle_remotes');
    spyOn(_fpa, 'one_time_setup').and.callThrough();

    // Stub the AJAX get used in load_template_version so it does not actually
    // resolve unless we explicitly resolve the deferred in the test. This lets
    // us check what happens BEFORE templates have been loaded.
    ajaxDeferred = $.Deferred();
    spyOn($, 'get').and.returnValue(ajaxDeferred.promise());
  });

  afterEach(function () {
    _fpa.state = originalState;
    $('body').removeClass('status-compiling status-compiled initial-compiling status-failed-compilation');
  });

  describe('when is_admin_page is true', function () {
    beforeEach(function () {
      _fpa.state.is_admin_page = true;
    });

    it('marks templates as loaded immediately so the splash guard can be removed without waiting for the AJAX response', function () {
      _fpa.initialize_app();

      expect(_fpa.status.loaded_templates).toBe(true);
    });

    it('still initiates the background template load AJAX request', function () {
      _fpa.initialize_app();

      expect($.get).toHaveBeenCalled();
    });
  });

  describe('when is_admin_page is falsy (regular user page)', function () {
    beforeEach(function () {
      _fpa.state.is_admin_page = false;
    });

    it('does NOT mark templates as loaded before the AJAX response completes', function () {
      _fpa.initialize_app();

      expect(_fpa.status.loaded_templates).toBe(false);
    });

    it('initiates the template load AJAX request', function () {
      _fpa.initialize_app();

      expect($.get).toHaveBeenCalled();
    });
  });
});
