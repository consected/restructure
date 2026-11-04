//= require app/_fpa.js

// _fpa.prepare_template_configs Spec
//
// Verifies that loaded state slots gate template-config downloads, current v0
// aliases do not mask missing historical versions, equivalent records share a
// representative config fetch, and callers wait for shared in-flight requests.

describe('_fpa.prepare_template_configs', function () {
  beforeEach(function () {
    _fpa.state.template_config = {};
    _fpa.state.template_config_requests = {};
    spyOn(_fpa, 'compile_templates');
  });

  it('fetches template configs again when the same record id has a new vdef_version', function () {
    var requestedUrls = [];
    spyOn($, 'ajax').and.callFake(function (url, options) {
      requestedUrls.push(url);
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
    });

    var initialData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        vdef_version: 'v20'
      }],
      master_id: 99
    };

    var updatedData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        vdef_version: 'v21'
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(initialData).then(function () {
      return _fpa.prepare_template_configs(updatedData);
    }).then(function () {
      expect($.ajax.calls.count()).toBe(2);
      expect(requestedUrls[0]).toMatch(/\/template_config\?v=/);
      expect(requestedUrls[1]).not.toBe(requestedUrls[0]);
      expect(_fpa.compile_templates.calls.count()).toBe(2);
    });
  });

  it('does not fetch when the record definition version is already present in state', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
    });

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v20: { def_version: null }
    };

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{ id: 42, vdef_version: 'v20' }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect($.ajax).not.toHaveBeenCalled();
    });
  });

  it('fetches the root config when its embedded item version is missing from state', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('');
    });

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v20: { def_version: null }
    };

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        vdef_version: 'v20',
        embedded_item: {
          id: 43,
          item_type: 'dynamic_model__test_embedded_rec',
          model_data_type: 'dynamic_model',
          resource_name: 'dynamic_model__test_embedded_recs',
          vdef_version: 'v8'
        }
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect($.ajax).toHaveBeenCalled();
      expect($.ajax.calls.argsFor(0)[0]).toMatch(/\/template_config\?v=/);
    });
  });

  it('does not use the v0 alias when a live record reports a real version token', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
    });

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v0: { def_version: null }
    };

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        def_version: null,
        vdef_version: 'v20'
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect($.ajax).toHaveBeenCalled();
    });
  });

  it('uses the v0 slot when the record has no version token', function () {
    spyOn($, 'ajax');

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v0: { def_version: null }
    };

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{ id: 42 }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect($.ajax).not.toHaveBeenCalled();
    });
  });

  it('falls back to v0 for a missing live token but not a historical version', function () {
    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v0: { caption: 'Current configuration' }
    };
    var helper = Handlebars.helpers.fpa_state_item;

    var helper_options = { hash: {} };
    var liveResult = helper.call(
      { def_version: null }, 'template_config', 'activity_log__player_contact_phone_primary', 'v21', helper_options
    );
    var historicalResult = helper.call(
      { def_version: 20 }, 'template_config', 'activity_log__player_contact_phone_primary', 'v20', helper_options
    );

    expect(liveResult).toEqual({ caption: 'Current configuration' });
    expect(historicalResult).toBeUndefined();
  });

  it('does not use the v0 alias to satisfy a missing historical version', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
    });

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v0: { def_version: null }
    };

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        def_version: 20,
        vdef_version: 'v20'
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect($.ajax).toHaveBeenCalled();
    });
  });

  it('waits for an existing in-flight request for the same record and version', function () {
    var ajaxOptions;
    spyOn($, 'ajax').and.callFake(function (url, options) {
      ajaxOptions = options;
    });

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{ id: 42, vdef_version: 'v20' }],
      master_id: 99
    };
    var firstResolved = false;
    var secondResolved = false;
    var firstRequest = _fpa.prepare_template_configs(pageData).then(function () {
      firstResolved = true;
    });
    var secondRequest = _fpa.prepare_template_configs(pageData).then(function () {
      secondResolved = true;
    });

    return Promise.resolve().then(function () {
      expect($.ajax.calls.count()).toBe(1);
      expect(firstResolved).toBe(false);
      expect(secondResolved).toBe(false);
      ajaxOptions.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
      return Promise.all([firstRequest, secondRequest]);
    }).then(function () {
      expect(firstResolved).toBe(true);
      expect(secondResolved).toBe(true);
    });
  });

  it('requests one representative record when ids share the same config version', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
    });

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        vdef_version: 'v20'
      }, {
        id: 43,
        vdef_version: 'v20'
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect($.ajax.calls.count()).toBe(1);
      expect($.ajax.calls.argsFor(0)[0]).toMatch(/\/template_config\?v=/);
    });
  });

  it('keeps representatives for distinct embedded config versions', function () {
    var requestedUrl;
    spyOn($, 'ajax').and.callFake(function (url, options) {
      requestedUrl = url;
      options.success('');
    });

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42,
        vdef_version: 'v20',
        embedded_item: {
          id: 142,
          item_type: 'dynamic_model__test_embedded_rec',
          model_data_type: 'dynamic_model',
          vdef_version: 'v8'
        }
      }, {
        id: 43,
        vdef_version: 'v20',
        embedded_item: {
          id: 143,
          item_type: 'dynamic_model__test_embedded_rec',
          model_data_type: 'dynamic_model',
          vdef_version: 'v9'
        }
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      expect(requestedUrl).toMatch(/\/42,43\/template_config\?v=/);
    });
  });

  it('does not add a trailing slash to the in-flight key when vdef_version is missing', function () {
    var ajaxOptions;
    spyOn($, 'ajax').and.callFake(function (url, options) {
      ajaxOptions = options;
    });

    var unversionedData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42
      }],
      master_id: 99
    };

    var request = _fpa.prepare_template_configs(unversionedData);
    expect(_fpa.state.template_config_requests['activity_log/player_contact_phone_primaries/42']).toBeDefined();
    expect(_fpa.state.template_config_requests['activity_log/player_contact_phone_primaries/42/']).toBeUndefined();
    ajaxOptions.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary"></script>');

    return request.then(function () {
      expect(Object.keys(_fpa.state.template_config_requests)).toEqual([]);
    });
  });

  // Edge case 2: the single-result path used to mutate data[type].vdef_version
  // to the literal 'v' when missing, producing cache key 'type/id/v' while the
  // multi-result path produced 'type/id'. The same unversioned record could
  // therefore be fetched twice if it appeared through both shapes during a
  // page lifecycle. The cache key for an unversioned record must be identical
  // across both paths.
  it('uses the same cache key in single- and multi-result paths for unversioned records', function () {
    var ajaxOptions;
    spyOn($, 'ajax').and.callFake(function (url, options) {
      ajaxOptions = options;
    });

    // Single-result shape: data[type] is an object, not an array, and there
    // is no `multiple_results` key. master_id is on the record itself.
    // Use a versioned-style type (activity_log__...) so the function does
    // not bail via _fpa.non_versioned_template_types.
    var singleResultData = {
      activity_log__player_contact_phone_primaries: { id: 42, master_id: 99 }
    };

    var singleRequest = _fpa.prepare_template_configs(singleResultData);
    var multiResultData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{ id: 42 }],
      master_id: 99
    };
    var multiRequest = _fpa.prepare_template_configs(multiResultData);

    expect($.ajax.calls.count()).toBe(1);
    return Promise.resolve().then(function () {
      // The single- and multi-result forms must share the same in-flight key.
      var keys = Object.keys(_fpa.state.template_config_requests);
      expect(keys.length).toBe(1);
      var key = keys[0];
      expect(key.endsWith('/42')).toBe(true);
      expect(key.endsWith('/42/v')).toBe(false);
      expect(singleResultData.activity_log__player_contact_phone_primaries.vdef_version).toBeUndefined();
      ajaxOptions.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary"></script>');
      return Promise.all([singleRequest, multiRequest]);
    }).then(function () {
      expect(Object.keys(_fpa.state.template_config_requests)).toEqual([]);
    });
  });

  it('preserves an explicit vdef_version on the single-result path', function () {
    var ajaxOptions;
    spyOn($, 'ajax').and.callFake(function (url, options) {
      ajaxOptions = options;
    });

    var singleVersionedData = {
      activity_log__player_contact_phone_primaries: { id: 42, vdef_version: 'v20', master_id: 99 }
    };

    var request = _fpa.prepare_template_configs(singleVersionedData);
    var keys = Object.keys(_fpa.state.template_config_requests);
      expect(keys.length).toBe(1);
      expect(keys[0].endsWith('/42/v20')).toBe(true);
    ajaxOptions.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');

    return request.then(function () {
      expect(Object.keys(_fpa.state.template_config_requests)).toEqual([]);
    });
  });

  // Edge case 1: when an AJAX template-config request fails, the error handler
  // must clear the cache entries that were optimistically set to true so the
  // next call can retry. Previously this used `for ... in` over an Array,
  // which iterates numeric indices, leaving the real cache entries marked
  // true forever and silently blocking retries until a full page reload.
  it('clears cache entries on AJAX failure so a subsequent call retries', function () {
    var ajaxCalls = 0;
    spyOn($, 'ajax').and.callFake(function (url, options) {
      ajaxCalls += 1;
      if (ajaxCalls === 1) {
        options.error({ status: 500 });
      } else {
        options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
      }
    });

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{ id: 42, vdef_version: 'v20' }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(pageData).then(function () {
      // A failed request must release its in-flight key so a later call retries.
      expect(_fpa.state.template_config_requests['activity_log/player_contact_phone_primaries/42/v20']).toBeUndefined();

      return _fpa.prepare_template_configs(pageData);
    }).then(function () {
      // Retry must have occurred.
      expect(ajaxCalls).toBe(2);
      expect(Object.keys(_fpa.state.template_config_requests)).toEqual([]);
    });
  });
});