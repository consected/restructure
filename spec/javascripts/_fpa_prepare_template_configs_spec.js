//= require app/_fpa.js

// _fpa.prepare_template_configs Spec
//
// Verifies that loaded state slots gate template-config downloads, current v0
// aliases do not mask missing historical versions, equivalent records share a
// representative config fetch, callers wait for shared in-flight requests, and
// session-scoped request URLs include a stable per-session salt. Pending requests are
// keyed by root record, version and embedded item versions, so a request for one embedded
// version never satisfies another. A live slot installed by a form beside an older v0
// alias triggers a single reconciling fetch.

describe('_fpa.prepare_template_configs', function () {
  beforeEach(function () {
    _fpa.state.template_config = {};
    _fpa.state.template_config_requests = {};
    _fpa.state.template_config_v0_attempts = {};
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

  describe('single record responses', function () {
    var requestedUrls;

    beforeEach(function () {
      requestedUrls = [];
      spyOn($, 'ajax').and.callFake(function (url, options) {
        requestedUrls.push(url);
        options.success('');
      });
    });

    it('requests the plural route for a single record keyed by its singular name', function () {
      var data = {
        activity_log__player_contact_phone: {
          id: 42,
          item_type: 'activity_log__player_contact_phone',
          vdef_version: 'v20',
          master_id: 99
        }
      };

      return _fpa.prepare_template_configs(data).then(function () {
        expect(requestedUrls.length).toBe(1);
        expect(requestedUrls[0]).toMatch(/^\/masters\/99\/activity_log\/player_contact_phones\/42\/template_config\?/);
      });
    });

    it('does not request a template config for a single master response', function () {
      return _fpa.prepare_template_configs({ master: { id: 99 }, master_id: 99 }).then(function () {
        expect($.ajax).not.toHaveBeenCalled();
      });
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

  it('does not let a request for one embedded version satisfy a pending request for another', function () {
    var ajaxCalls = [];
    spyOn($, 'ajax').and.callFake(function (url, options) {
      ajaxCalls.push({ url: url, options: options });
    });

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v20: { def_version: null }
    };
    var pageDataWithEmbedded = function (embeddedVersion) {
      return {
        multiple_results: 'activity_log__player_contact_phone_primaries',
        activity_log__player_contact_phone_primaries: [{
          id: 42,
          vdef_version: 'v20',
          embedded_item: {
            id: 142,
            item_type: 'dynamic_model__test_embedded_rec',
            model_data_type: 'dynamic_model',
            vdef_version: embeddedVersion
          }
        }],
        master_id: 99
      };
    };
    var resolved = { v8: false, v9: false };
    var requestV8 = _fpa.prepare_template_configs(pageDataWithEmbedded('v8')).then(function () {
      resolved.v8 = true;
    });
    var requestV9 = _fpa.prepare_template_configs(pageDataWithEmbedded('v9')).then(function () {
      resolved.v9 = true;
    });

    return Promise.resolve().then(function () {
      expect(ajaxCalls.length).toBe(2);
      expect(ajaxCalls[1].url).not.toBe(ajaxCalls[0].url);
      expect(Object.keys(_fpa.state.template_config_requests).length).toBe(2);

      _fpa.state.template_config.dynamic_model__test_embedded_rec = { v8: {} };
      ajaxCalls[0].options.success('');
      return requestV8;
    }).then(function () {
      expect(resolved.v8).toBe(true);
      expect(resolved.v9).toBe(false);

      _fpa.state.template_config.dynamic_model__test_embedded_rec.v9 = {};
      ajaxCalls[1].options.success('');
      return requestV9;
    }).then(function () {
      expect(resolved.v9).toBe(true);
      expect(Object.keys(_fpa.state.template_config_requests)).toEqual([]);
    });
  });

  it('still shares one in-flight request for the same root and the same embedded versions', function () {
    spyOn($, 'ajax');

    _fpa.state.template_config.activity_log__player_contact_phone_primary = {
      v20: { def_version: null }
    };
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
      }],
      master_id: 99
    };

    _fpa.prepare_template_configs(pageData);
    _fpa.prepare_template_configs(pageData);

    return Promise.resolve().then(function () {
      expect($.ajax.calls.count()).toBe(1);
    });
  });

  describe('v0 alias reconciliation', function () {
    var pageDataForVersion = function (version, extra) {
      return {
        multiple_results: 'activity_log__player_contact_phone_primaries',
        activity_log__player_contact_phone_primaries: [Object.assign({ id: 42, vdef_version: version }, extra)],
        master_id: 99
      };
    };

    beforeEach(function () {
      _fpa.state.template_config_v0_attempts = {};
    });

    it('fetches when a form installed the live slot but the v0 alias is on an older token', function () {
      spyOn($, 'ajax').and.callFake(function (url, options) {
        options.success('');
      });
      var slot = {
        v8: { vdef_version: 'v8' },
        v9: { vdef_version: 'v9' },
        v0: { vdef_version: 'v8' }
      };
      _fpa.state.template_config.activity_log__player_contact_phone_primary = slot;

      return _fpa.prepare_template_configs(pageDataForVersion('v9')).then(function () {
        expect($.ajax.calls.count()).toBe(1);
        expect($.ajax.calls.argsFor(0)[0]).toMatch(/\/template_config\?v=/);
      });
    });

    it('does not fetch when the v0 alias is on the requested or a newer token', function () {
      spyOn($, 'ajax');
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v9: { vdef_version: 'v9' },
        v0: { vdef_version: 'v9' }
      };

      return _fpa.prepare_template_configs(pageDataForVersion('v9')).then(function () {
        _fpa.state.template_config.activity_log__player_contact_phone_primary.v0 = { vdef_version: 'v12' };
        return _fpa.prepare_template_configs(pageDataForVersion('v9'));
      }).then(function () {
        expect($.ajax).not.toHaveBeenCalled();
      });
    });

    it('does not fetch when the v0 alias carries no token', function () {
      spyOn($, 'ajax');
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v9: { vdef_version: 'v9' },
        v0: { def_version: null }
      };

      return _fpa.prepare_template_configs(pageDataForVersion('v9')).then(function () {
        expect($.ajax).not.toHaveBeenCalled();
      });
    });

    it('does not reconcile v0 for a historical record version', function () {
      spyOn($, 'ajax');
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v9: { vdef_version: 'v9', def_version: 9 },
        v0: { vdef_version: 'v8' }
      };

      return _fpa.prepare_template_configs(pageDataForVersion('v9', { def_version: 9 })).then(function () {
        expect($.ajax).not.toHaveBeenCalled();
      });
    });

    it('fetches when the stale v0 alias belongs to an embedded item', function () {
      spyOn($, 'ajax').and.callFake(function (url, options) {
        options.success('');
      });
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v20: { vdef_version: 'v20' },
        v0: { vdef_version: 'v20' }
      };
      _fpa.state.template_config.dynamic_model__test_embedded_rec = {
        v9: { vdef_version: 'v9' },
        v0: { vdef_version: 'v8' }
      };
      var pageData = pageDataForVersion('v20', {
        embedded_item: {
          id: 142,
          item_type: 'dynamic_model__test_embedded_rec',
          model_data_type: 'dynamic_model',
          vdef_version: 'v9'
        }
      });

      return _fpa.prepare_template_configs(pageData).then(function () {
        expect($.ajax.calls.count()).toBe(1);
      });
    });

    it('reconciles only once when the server still answers with an older token', function () {
      spyOn($, 'ajax').and.callFake(function (url, options) {
        options.success('');
      });
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v9: { vdef_version: 'v9' },
        v0: { vdef_version: 'v8' }
      };

      return _fpa.prepare_template_configs(pageDataForVersion('v9')).then(function () {
        return _fpa.prepare_template_configs(pageDataForVersion('v9'));
      }).then(function () {
        expect($.ajax.calls.count()).toBe(1);
      });
    });

    it('retries the reconciliation after a failed request', function () {
      spyOn($, 'ajax').and.callFake(function (url, options) {
        options.error({});
      });
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v9: { vdef_version: 'v9' },
        v0: { vdef_version: 'v8' }
      };

      return _fpa.prepare_template_configs(pageDataForVersion('v9')).then(function () {
        return _fpa.prepare_template_configs(pageDataForVersion('v9'));
      }).then(function () {
        expect($.ajax.calls.count()).toBe(2);
      });
    });

    it('stops fetching once the response has promoted v0 to the requested token', function () {
      spyOn($, 'ajax').and.callFake(function (url, options) {
        _fpa.state.template_config.activity_log__player_contact_phone_primary.v0 = { vdef_version: 'v9' };
        options.success('');
      });
      _fpa.state.template_config.activity_log__player_contact_phone_primary = {
        v9: { vdef_version: 'v9' },
        v0: { vdef_version: 'v8' }
      };

      return _fpa.prepare_template_configs(pageDataForVersion('v9')).then(function () {
        _fpa.state.template_config_v0_attempts = {};
        return _fpa.prepare_template_configs(pageDataForVersion('v9'));
      }).then(function () {
        expect($.ajax.calls.count()).toBe(1);
      });
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

  // The template_config response is cached by the browser for a short time, so its URL must
  // change whenever the signed-in session or access context changes.
  describe('session scoped request URL', function () {
    var previousUser, previousAdmin, previousRoles, previousSalt;

    var pageData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{ id: 42, vdef_version: 'v20' }],
      master_id: 99
    };

    var requestUrl = function () {
      var requestedUrl;
      _fpa.state.template_config = {};
      _fpa.state.template_config_requests = {};
      $.ajax.and.callFake(function (url, options) {
        requestedUrl = url;
        options.success('');
      });

      return _fpa.prepare_template_configs(pageData).then(function () {
        return requestedUrl;
      });
    };

    beforeEach(function () {
      previousUser = _fpa.state.current_user;
      previousAdmin = _fpa.state.current_admin;
      previousRoles = _fpa.state.current_user_roles;
      previousSalt = _fpa.state.template_config_salt;
      _fpa.state.current_user = { id: 7, current_sign_in_at: '2026-11-04T10:00:00Z', app_type_id: 3 };
      _fpa.state.current_user_roles = ['role_a'];
      _fpa.state.current_admin = undefined;
      _fpa.state.template_config_salt = 'session123';
      spyOn($, 'ajax');
    });

    afterEach(function () {
      _fpa.state.current_user = previousUser;
      _fpa.state.current_admin = previousAdmin;
      _fpa.state.current_user_roles = previousRoles;
      _fpa.state.template_config_salt = previousSalt;
    });

    it('uses the same URL while the session is unchanged, so the browser cache still applies', function () {
      return requestUrl().then(function (first) {
        return requestUrl().then(function (second) {
          expect(first).toMatch(/[?&]s=session123\.[0-9a-z]+/);
          expect(second).toBe(first);
        });
      });
    });

    it('uses a different URL when the per-session salt changes', function () {
      return requestUrl().then(function (first) {
        _fpa.state.template_config_salt = 'session456';
        return requestUrl().then(function (second) {
          expect(second).not.toBe(first);
        });
      });
    });

    it('falls back to the existing hash when no salt is available', function () {
      _fpa.state.template_config_salt = undefined;
      var unsaltedKey = _fpa.template_config_session_key();

      expect(unsaltedKey).toMatch(/^[0-9a-z]+$/);
      _fpa.state.template_config_salt = 'session123';
      expect(_fpa.template_config_session_key()).toBe('session123.' + unsaltedKey);
    });

    it('uses a different URL after a new sign in', function () {
      return requestUrl().then(function (first) {
        _fpa.state.current_user = { id: 7, current_sign_in_at: '2026-11-04T11:00:00Z', app_type_id: 3 };
        return requestUrl().then(function (second) {
          expect(second).not.toBe(first);
        });
      });
    });

    it('uses a different URL for another user', function () {
      return requestUrl().then(function (first) {
        _fpa.state.current_user = { id: 8, current_sign_in_at: '2026-11-04T10:00:00Z', app_type_id: 3 };
        return requestUrl().then(function (second) {
          expect(second).not.toBe(first);
        });
      });
    });

    it('uses a different URL after switching app type or roles', function () {
      return requestUrl().then(function (first) {
        _fpa.state.current_user = { id: 7, current_sign_in_at: '2026-11-04T10:00:00Z', app_type_id: 4 };
        return requestUrl().then(function (second) {
          expect(second).not.toBe(first);
          _fpa.state.current_user = { id: 7, current_sign_in_at: '2026-11-04T10:00:00Z', app_type_id: 3 };
          _fpa.state.current_user_roles = ['role_a', 'role_b'];
          return requestUrl().then(function (third) {
            expect(third).not.toBe(first);
          });
        });
      });
    });

    it('uses a different URL for an admin session', function () {
      return requestUrl().then(function (first) {
        _fpa.state.current_user = undefined;
        _fpa.state.current_admin = { id: 2, current_sign_in_at: '2026-11-04T10:00:00Z' };
        return requestUrl().then(function (second) {
          expect(second).not.toBe(first);
        });
      });
    });
  });
});