//= require app/_fpa.js

// _fpa.template_config_* helper Spec
//
// Unit specs for the pure helpers behind _fpa.prepare_template_configs: parsing of "v<n>" versions,
// collecting the versioned embedded dependencies of a data item (embedded_item and embedded_items,
// with a single definition of "is a versioned definition type"), building the dependency identity
// used in request grouping and pending-request keys, and reporting whether the state slots a record
// needs are present (and whether a v0 alias beside a live version is stale). It also covers
// promote_template_state_v0, the shared guard used by the emitted state scripts so that a form
// served for an older live state never replaces a newer v0 alias. States are compared by live_order,
// a monotonic number: the slot token is only an identity (a hash when config libraries are used), so
// a newer state can have a numerically smaller token than an older one.
// Behaviour of the full request flow is covered by _fpa_prepare_template_configs_spec.js.

describe('_fpa.template_config helpers', function () {
  beforeEach(function () {
    _fpa.state.template_config = {};
  });

  describe('promote_template_state_v0', function () {
    it('assigns v0 when the target has no v0 yet', function () {
      var target = { v5: { vdef_version: 'v5', live_order: 50 } };

      expect(_fpa.promote_template_state_v0(target, target.v5, 50)).toBe(true);
      expect(target.v0).toBe(target.v5);
    });

    it('replaces a v0 with an older or equal live order', function () {
      var target = { v0: { vdef_version: 'v4', live_order: 40 }, v4: {}, v5: { vdef_version: 'v5', live_order: 50 } };

      expect(_fpa.promote_template_state_v0(target, target.v5, 50)).toBe(true);
      expect(target.v0).toBe(target.v5);

      var same_order = { v0: { vdef_version: 'v5', live_order: 50 } };
      var replacement = { vdef_version: 'v5', live_order: 50 };
      expect(_fpa.promote_template_state_v0(same_order, replacement, 50)).toBe(true);
      expect(same_order.v0).toBe(replacement);
    });

    it('never replaces a newer v0 with an older live order', function () {
      var newer = { vdef_version: 'v7', live_order: 70 };
      var target = { v0: newer };

      expect(_fpa.promote_template_state_v0(target, { vdef_version: 'v5', live_order: 50 }, 50)).toBe(false);
      expect(target.v0).toBe(newer);
    });

    it('replaces a v0 with a newer live order even when its composite token is numerically smaller', function () {
      var older = { vdef_version: 'v1000000900000', live_order: 50 };
      var newer = { vdef_version: 'v1000000100000', live_order: 60 };
      var target = { v0: older };

      expect(_fpa.promote_template_state_v0(target, newer, 60)).toBe(true);
      expect(target.v0).toBe(newer);
    });

    it('refuses an older live order even when its composite token is numerically larger', function () {
      var newer = { vdef_version: 'v1000000100000', live_order: 60 };
      var target = { v0: newer };

      expect(_fpa.promote_template_state_v0(target, { vdef_version: 'v1000000900000', live_order: 50 }, 50)).toBe(false);
      expect(target.v0).toBe(newer);
    });

    it('compares orders beyond 32 bits exactly', function () {
      var target = { v0: { live_order: 1700000000000001 } };

      expect(_fpa.promote_template_state_v0(target, {}, 1700000000000000)).toBe(false);
      expect(_fpa.promote_template_state_v0(target, {}, 1700000000000002)).toBe(true);
    });

    it('treats a v0 without a live order as installable, as for labels and show_if', function () {
      var target = { v0: { some: 'labels' } };
      var value = { other: 'labels' };

      expect(_fpa.promote_template_state_v0(target, value, 30)).toBe(true);
      expect(target.v0).toBe(value);
    });

    it('promotes when the new state has no live order', function () {
      var target = { v0: { live_order: 70 } };
      var value = { live_order: null };

      expect(_fpa.promote_template_state_v0(target, value, null)).toBe(true);
      expect(target.v0).toBe(value);
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

    it('flags a v0 alias with an older live order than the live version as stale, but never for historical versions', function () {
      _fpa.state.template_config = {
        dynamic_model__a_things: { v0: { vdef_version: 'v2', live_order: 20 }, v5: { live_order: 50 } }
      };

      var live = { id: 1, item_type: 'dynamic_model__a_things' };
      expect(_fpa.template_config_slot_status(live, 'x', 'v5')).toEqual({ present: true, v0_stale: true });

      var historical = { id: 1, item_type: 'dynamic_model__a_things', def_version: 'v5' };
      expect(_fpa.template_config_slot_status(historical, 'x', 'v5')).toEqual({ present: true, v0_stale: false });
    });

    it('compares live orders, not tokens, when flagging a stale v0 alias', function () {
      _fpa.state.template_config = {
        dynamic_model__a_things: {
          v0: { vdef_version: 'v1000000900000', live_order: 20 },
          v1000000100000: { live_order: 50 }
        }
      };
      var live = { id: 1, item_type: 'dynamic_model__a_things' };
      expect(_fpa.template_config_slot_status(live, 'x', 'v1000000100000').v0_stale).toBe(true);

      _fpa.state.template_config.dynamic_model__a_things.v0 = { vdef_version: 'v1000000100000', live_order: 50 };
      _fpa.state.template_config.dynamic_model__a_things.v1000000900000 = { live_order: 20 };
      expect(_fpa.template_config_slot_status(live, 'x', 'v1000000900000').v0_stale).toBe(false);
    });

    describe('for a record that identifies its option type', function () {
      var record = function () {
        return { id: 1, item_type: 'dynamic_model__a_thing', option_type: 'other' };
      };

      it('is absent, reporting option_slot_missing, when only another option type or the base slot is present', function () {
        _fpa.state.template_config = {
          dynamic_model__a_thing: { v5: {}, v0: { live_order: 50 } },
          dynamic_model__a_thing_default: { v5: {} }
        };

        expect(_fpa.template_config_slot_status(record(), 'dynamic_model__a_things', 'v5'))
          .toEqual({ present: false, v0_stale: false, option_slot_missing: true });
      });

      it('is present when its own option type slot is present, ignoring the base slot', function () {
        _fpa.state.template_config = {
          dynamic_model__a_thing: { v0: { live_order: 50 } },
          dynamic_model__a_thing_other: { v5: { live_order: 50 }, v0: { live_order: 40 } }
        };

        expect(_fpa.template_config_slot_status(record(), 'dynamic_model__a_things', 'v5'))
          .toEqual({ present: true, v0_stale: true });
      });

      it('is simply absent when no container has the version', function () {
        _fpa.state.template_config = { dynamic_model__a_thing: { v4: {} } };

        expect(_fpa.template_config_slot_status(record(), 'dynamic_model__a_things', 'v5'))
          .toEqual({ present: false, v0_stale: false });
      });

      it('names the option slot as the underscored item type and option type', function () {
        expect(_fpa.template_config_option_slot_name({ item_type: 'activity_log__phone', option_type: 'Step-One' }))
          .toBe('activity_log__phone_step_one');
        expect(_fpa.template_config_option_slot_name({ item_type: 'activity_log__phone' })).toBeNull();
        expect(_fpa.template_config_option_slot_name({ option_type: 'other' })).toBeNull();
      });
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

    it('reports option_slot_missing when an embedded item has only another option type slot', function () {
      _fpa.state.template_config = {
        dynamic_model__a_things: { v1: {} },
        dynamic_model__b_thing: { v9: {} }
      };
      var item = root();
      item.embedded_item = { item_type: 'dynamic_model__b_thing', option_type: 'other', vdef_version: 'v9' };

      var status = _fpa.template_config_slots_status(item, 'x', 'v1', _fpa.template_config_dependencies(item));

      expect(status).toEqual({ present: false, v0_stale: false, option_slot_missing: true });
    });

    it('is present when root and embedded slots exist, carrying a stale v0 flag from an embedded item', function () {
      _fpa.state.template_config = {
        dynamic_model__a_things: { v1: {} },
        dynamic_model__b_things: { v0: { vdef_version: 'v2', live_order: 20 }, v9: { live_order: 90 } }
      };
      var item = root();
      item.embedded_item = { item_type: 'dynamic_model__b_things', vdef_version: 'v9' };

      var status = _fpa.template_config_slots_status(item, 'x', 'v1', _fpa.template_config_dependencies(item));

      expect(status).toEqual({ present: true, v0_stale: true });
    });
  });
});
