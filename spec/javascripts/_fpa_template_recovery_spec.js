//= require app/_fpa.js

// Template recovery specs for issue #1400.
// A missing compiled multi-bundle must trigger one token-gated fragment rebuild without
// allowing the page-loading guard to finish between the failed request and its retry.

describe('_fpa template recovery', function () {
  var ajaxDeferred;
  var templateDeferred;

  beforeEach(function () {
    _fpa.state.template_version = 'current-template-token';
    _fpa.status = _fpa.status || {};
    _fpa.status.pending_template_retrieves = 0;
    _fpa.status.template_rebuild_attempted = false;
    ajaxDeferred = $.Deferred();
    templateDeferred = $.Deferred();
    spyOn($, 'ajax').and.returnValue(ajaxDeferred.promise());
    spyOn($, 'get').and.returnValue(templateDeferred.promise());
    spyOn(_fpa.cache, 'clean');
  });

  it('requests one fragment rebuild when a compiled bundle cannot be loaded', function () {
    spyOn(_fpa, 'load_template_version');

    _fpa.retrieve_requested_handlebars_templates('/missing.js', 'test', 'masters_search_results_template');
    ajaxDeferred.reject({}, 'error', 'Not Found');

    expect(_fpa.load_template_version).toHaveBeenCalledWith('current-template-token', 'test', true);
    expect(_fpa.status.template_rebuild_attempted).toBe(true);
  });

  it('does not start a second rebuild after the retry bundle also fails', function () {
    _fpa.status.template_rebuild_attempted = true;
    spyOn(_fpa, 'load_template_version');

    _fpa.retrieve_requested_handlebars_templates('/still-missing.js', 'test', 'masters_search_results_template');
    ajaxDeferred.reject({}, 'error', 'Not Found');

    expect(_fpa.load_template_version).not.toHaveBeenCalled();
  });

  it('requests rebuild=true and keeps template loading pending until the fragment response arrives', function () {
    _fpa.load_template_version('current-template-token', 'test', true);

    expect($.get).toHaveBeenCalledWith({
      url: '/pages/current-template-token/template?rebuild=true',
      cache: false
    });
    expect(_fpa.status.pending_template_retrieves).toBe(1);
  });

  it('requests one rebuild when the outer template response fails', function () {
    _fpa.load_template_version('current-template-token', 'test');
    templateDeferred.reject({}, 'error', 'Internal Server Error');

    expect($.get.calls.argsFor(1)[0]).toEqual({
      url: '/pages/current-template-token/template?rebuild=true',
      cache: false
    });
    expect(_fpa.status.template_rebuild_attempted).toBe(true);
  });

  // Issue #1543: when templates fail to compile, the rebuild request on an unauthenticated page
  // is redirected to the sign-in page. Appending that full document duplicated the whole page
  // and re-ran the app scripts.
  describe('full page response instead of a template fragment', function () {
    var fullPage = '<!DOCTYPE html><html><head><script src="/assets/application.js"></script></head>' +
      '<body><div class="login-block"></div></body></html>';

    beforeEach(function () {
      $('#template-fragment-test').remove();
      $('body').append('<div id="template-fragment-test"></div>');
      spyOn(_fpa, 'one_time_setup');
      spyOn(console, 'error');
      jasmine.clock().install();
    });

    afterEach(function () {
      jasmine.clock().uninstall();
      $('#template-fragment-test').remove();
    });

    it('does not append a full HTML document to the page', function () {
      var bodyAppend = spyOn($.fn, 'append').and.callThrough();

      _fpa.load_template_version('current-template-token', 'test', true);
      templateDeferred.resolve(fullPage);

      expect(bodyAppend).not.toHaveBeenCalled();
      expect(console.error).toHaveBeenCalled();
    });

    it('still completes template loading so the page is not left waiting', function () {
      _fpa.load_template_version('current-template-token', 'test', true);
      templateDeferred.resolve(fullPage);
      jasmine.clock().tick(50);

      expect(_fpa.status.loaded_templates).toBe(true);
      expect(_fpa.one_time_setup).toHaveBeenCalled();
    });

    it('appends a genuine template fragment', function () {
      var bodyAppend = spyOn($.fn, 'append').and.callThrough();

      _fpa.load_template_version('current-template-token', 'test', true);
      templateDeferred.resolve('<div class="template-fragment-test-content"></div>');

      expect(bodyAppend).toHaveBeenCalled();
      expect(console.error).not.toHaveBeenCalled();
    });
  });
});