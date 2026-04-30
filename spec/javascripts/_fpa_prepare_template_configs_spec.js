//= require app/_fpa.js

// _fpa.prepare_template_configs Spec
//
// Verifies that template-config downloads are not incorrectly memoized across
// different definition versions of the same record instance, while still keeping
// different instances distinct even when they share the same definition version.
// This protects the versioned activity log flow described in issue #1078.

describe('_fpa.prepare_template_configs', function () {
  beforeEach(function () {
    _fpa.state.template_config_versions = {};
    $('body').append('<script id="master-main-template"></script>');
    spyOn(_fpa, 'compile_templates');
  });

  afterEach(function () {
    $('#master-main-template').remove();
  });

  it('fetches template configs again when the same record id has a new vdef_version', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
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
      expect($.ajax.calls.argsFor(1)[0]).toBe('/masters/99/activity_log/player_contact_phone_primaries/42/template_config');
      expect(_fpa.compile_templates.calls.count()).toBe(2);
    });
  });

  it('keeps different record ids distinct when they share the same vdef_version', function () {
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
      expect($.ajax.calls.argsFor(0)[0]).toBe('/masters/99/activity_log/player_contact_phone_primaries/42,43/template_config');
      expect(_fpa.state.template_config_versions['activity_log/player_contact_phone_primaries/42/v20']).toBe(true);
      expect(_fpa.state.template_config_versions['activity_log/player_contact_phone_primaries/43/v20']).toBe(true);
    });
  });

  it('does not add a trailing slash to cache key when vdef_version is missing', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary"></script>');
    });

    var unversionedData = {
      multiple_results: 'activity_log__player_contact_phone_primaries',
      activity_log__player_contact_phone_primaries: [{
        id: 42
      }],
      master_id: 99
    };

    return _fpa.prepare_template_configs(unversionedData).then(function () {
      expect(_fpa.state.template_config_versions['activity_log/player_contact_phone_primaries/42']).toBe(true);
      expect(_fpa.state.template_config_versions['activity_log/player_contact_phone_primaries/42/']).toBeUndefined();
    });
  });

  // Edge case 2: the single-result path used to mutate data[type].vdef_version
  // to the literal 'v' when missing, producing cache key 'type/id/v' while the
  // multi-result path produced 'type/id'. The same unversioned record could
  // therefore be fetched twice if it appeared through both shapes during a
  // page lifecycle. The cache key for an unversioned record must be identical
  // across both paths.
  it('uses the same cache key in single- and multi-result paths for unversioned records', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary"></script>');
    });

    // Single-result shape: data[type] is an object, not an array, and there
    // is no `multiple_results` key. master_id is on the record itself.
    // Use a versioned-style type (activity_log__...) so the function does
    // not bail via _fpa.non_versioned_template_types.
    var singleResultData = {
      activity_log__player_contact_phone_primaries: { id: 42, master_id: 99 }
    };

    return _fpa.prepare_template_configs(singleResultData).then(function () {
      // Find the cache key that was created so we can assert on its shape
      // independently of any pluralization quirks in url_data_type.
      var keys = Object.keys(_fpa.state.template_config_versions);
      expect(keys.length).toBe(1);
      var key = keys[0];
      // Must NOT default to a placeholder version that would produce a stale
      // cache key the multi-result path would never collide with.
      expect(key.endsWith('/42')).toBe(true);
      expect(key.endsWith('/42/v')).toBe(false);
      expect(_fpa.state.template_config_versions[key]).toBe(true);
      // Confirm the single-result path no longer mutates the source data.
      expect(singleResultData.activity_log__player_contact_phone_primaries.vdef_version).toBeUndefined();
    });
  });

  it('preserves an explicit vdef_version on the single-result path', function () {
    spyOn($, 'ajax').and.callFake(function (url, options) {
      options.success('<script id="fpa_state_config--activity_log__player_contact_phone_primary--v20"></script>');
    });

    var singleVersionedData = {
      activity_log__player_contact_phone_primaries: { id: 42, vdef_version: 'v20', master_id: 99 }
    };

    return _fpa.prepare_template_configs(singleVersionedData).then(function () {
      var keys = Object.keys(_fpa.state.template_config_versions);
      expect(keys.length).toBe(1);
      expect(keys[0].endsWith('/42/v20')).toBe(true);
      expect(_fpa.state.template_config_versions[keys[0]]).toBe(true);
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
      // After failure, the real cache key must be cleared (set to false),
      // not left as true. And junk numeric keys must NOT be present.
      expect(_fpa.state.template_config_versions['activity_log/player_contact_phone_primaries/42/v20']).toBe(false);
      expect(_fpa.state.template_config_versions['0']).toBeUndefined();

      return _fpa.prepare_template_configs(pageData);
    }).then(function () {
      // Retry must have occurred.
      expect(ajaxCalls).toBe(2);
      expect(_fpa.state.template_config_versions['activity_log/player_contact_phone_primaries/42/v20']).toBe(true);
    });
  });
});