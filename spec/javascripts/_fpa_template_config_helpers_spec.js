//= require app/_fpa.js

// _fpa.template_config_* helper Spec
//
// Unit specs for the pure helpers behind _fpa.prepare_template_configs: parsing of "v<n>" versions,
// collecting the versioned embedded dependencies of a data item (embedded_item and embedded_items,
// with a single definition of "is a versioned definition type"), building the dependency identity
// used in request grouping and pending-request keys, and reporting whether the state slots a record
// needs are present (and whether a v0 alias beside a live version is stale).
// Behaviour of the full request flow is covered by _fpa_prepare_template_configs_spec.js.

describe('_fpa.template_config helpers', function () {
  beforeEach(function () {
    _fpa.state.template_config = {};
  });

  describe('template_config_version_number', function () {
    it('parses v<n> versions and returns 0 for anything else', function () {
      expect(_fpa.template_config_version_number('v12')).toBe(12);
      expect(_fpa.template_config_version_number('v0')).toBe(0);
      expect(_fpa.template_config_version_number('12')).toBe(0);
      expect(_fpa.template_config_version_number('v')).toBe(0);
      expect(_fpa.template_config_version_number('v1a')).toBe(0);
      expect(_fpa.template_config_version_number(undefined)).toBe(0);
      expect(_fpa.template_config_version_number(null)).toBe(0);
    });
  });

  describe('template_config_dependencies', function () {
    it('returns an empty list when there are no embedded items', function () {
      expect(_fpa.template_config_dependencies({ id: 1 })).toEqual([]);
    });

    it('collects embedded_item then embedded_items with their type and version', function () {
      var single = { item_type: 'dynamic_model__a_things', vdef_version: 'v3' };
      var first = { resource_name: 'activity_log__b_things__step_one', vdef_version: 'v5' };
      var second = { name_with_option_type: 'external_identifier__c_things' };
      var dependencies = _fpa.template_config_dependencies({
        embedded_item: single,
        embedded_items: [first, second]
      });

      expect(dependencies).toEqual([
        { item: single, type: 'dynamic_model__a_things', version: 'v3' },
        { item: first, type: 'activity_log__b_things__step_one', version: 'v5' },
        { item: second, type: 'external_identifier__c_things', version: 'v0' }
      ]);
    });

    it('ignores embedded items that are not versioned definition types', function () {
      var dependencies = _fpa.template_config_dependencies({
        embedded_items: [
          { item_type: 'player_infos', vdef_version: 'v2' },
          { model_data_type: 'external_identifier', item_type: 'anything' },
          { model_data_type: 'other', resource_name: 'dynamic_model__x_things' }
        ]
      });

      expect(dependencies.map(function (d) { return d.type; })).toEqual(['anything', 'dynamic_model__x_things']);
    });

    it('falls back through item_type, resource_name, name_with_option_type then model_data_type', function () {
      var type_of = function (item) {
        return _fpa.template_config_dependencies({ embedded_item: item })[0].type;
      };

      expect(type_of({ item_type: 'dynamic_model__i', resource_name: 'dynamic_model__r' })).toBe('dynamic_model__i');
      expect(type_of({ resource_name: 'dynamic_model__r', name_with_option_type: 'dynamic_model__n' })).toBe('dynamic_model__r');
      expect(type_of({ name_with_option_type: 'dynamic_model__n', model_data_type: 'dynamic_model' })).toBe('dynamic_model__n');
      expect(type_of({ model_data_type: 'activity_log' })).toBe('activity_log');
    });
  });

  describe('template_config_dependency_groups', function () {
    it('returns a sorted list of JSON identities with option type and version', function () {
      var dependencies = _fpa.template_config_dependencies({
        embedded_items: [
          { item_type: 'dynamic_model__b', option_type: 'opt', vdef_version: 'v9' },
          { item_type: 'dynamic_model__a', name_with_option_type: 'dynamic_model__a__named' }
        ]
      });

      expect(_fpa.template_config_dependency_groups(dependencies)).toEqual([
        JSON.stringify(['dynamic_model__a', 'dynamic_model__a__named', 'v0']),
        JSON.stringify(['dynamic_model__b', 'opt', 'v9'])
      ]);
    });

    it('differs when only an embedded item version differs', function () {
      var groups_for = function (version) {
        return _fpa.template_config_dependency_groups(_fpa.template_config_dependencies({
          embedded_item: { item_type: 'dynamic_model__a', vdef_version: version }
        }));
      };

      expect(groups_for('v8')).not.toEqual(groups_for('v9'));
    });

    it('is empty without dependencies', function () {
      expect(_fpa.template_config_dependency_groups([])).toEqual([]);
    });
  });

  describe('template_config_slot_status', function () {
    it('is absent when no template config exists for the version', function () {
      expect(_fpa.template_config_slot_status({ id: 1, item_type: 'dynamic_model__a_things' }, 'x', 'v1'))
        .toEqual({ present: false, v0_stale: false });
    });

    it('is present when the version exists under the plural or singular type name', function () {
      _fpa.state.template_config = { dynamic_model__a_thing: { v1: {} } };

      expect(_fpa.template_config_slot_status({ id: 1, item_type: 'dynamic_model__a_things' }, 'x', 'v1').present).toBe(true);
    });

    it('flags a v0 alias older than the live version as stale, but never for historical versions', function () {
      _fpa.state.template_config = { dynamic_model__a_things: { v0: { vdef_version: 'v2' }, v5: {} } };

      var live = { id: 1, item_type: 'dynamic_model__a_things' };
      expect(_fpa.template_config_slot_status(live, 'x', 'v5')).toEqual({ present: true, v0_stale: true });

      var historical = { id: 1, item_type: 'dynamic_model__a_things', def_version: 'v5' };
      expect(_fpa.template_config_slot_status(historical, 'x', 'v5')).toEqual({ present: true, v0_stale: false });
    });
  });

  describe('template_config_slots_status', function () {
    var root = function () {
      return { id: 1, item_type: 'dynamic_model__a_things', vdef_version: 'v1' };
    };

    it('is absent when the root slot is missing', function () {
      var status = _fpa.template_config_slots_status(root(), 'x', 'v1', []);

      expect(status).toEqual({ present: false, v0_stale: false });
    });

    it('is absent when a versioned embedded item slot is missing', function () {
      _fpa.state.template_config = { dynamic_model__a_things: { v1: {} } };
      var item = root();
      item.embedded_item = { item_type: 'dynamic_model__b_things', vdef_version: 'v9' };

      var status = _fpa.template_config_slots_status(item, 'x', 'v1', _fpa.template_config_dependencies(item));

      expect(status.present).toBe(false);
    });

    it('is present when root and embedded slots exist, carrying a stale v0 flag from an embedded item', function () {
      _fpa.state.template_config = {
        dynamic_model__a_things: { v1: {} },
        dynamic_model__b_things: { v0: { vdef_version: 'v2' }, v9: {} }
      };
      var item = root();
      item.embedded_item = { item_type: 'dynamic_model__b_things', vdef_version: 'v9' };

      var status = _fpa.template_config_slots_status(item, 'x', 'v1', _fpa.template_config_dependencies(item));

      expect(status).toEqual({ present: true, v0_stale: true });
    });
  });
});
