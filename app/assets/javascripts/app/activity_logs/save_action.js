// Implement save_acton handling for activity logs
// Simply call:
//   _fpa.activity_logs.save_action.handle(block, data)
//
// To add a new action to be handled, simply add a method matching the name
_fpa.activity_logs.save_action = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  static handle(block, data) {
    var handler = new _fpa.activity_logs.save_action(block, data)
    handler.handle()
  }

  handle() {
    var data = this.data;

    if (!data._control) return;

    this.obj_data = _fpa.activity_logs.get_object_data(data);
    this.lookup_save_action();

    if (typeof this.save_action != 'object') return;

    this.master_id = this.obj_data.master_id;

    for (const [key, value] of Object.entries(this.save_action)) {
      if (!this[key]) throw `save_action is not valid: ${key}`;

      this.action_value = value
      this[key]();
    }
  }

  lookup_save_action() {
    var obj_data = this.obj_data
    var data = this.data

    if (obj_data._created) {
      var dc = obj_data._control;
      if (!dc) dc = data._control;
      if (dc && dc.save_action)
        this.save_action = dc.save_action.on_create;
    }
    else if (obj_data._updated) {
      var dc = obj_data._control;
      if (!dc) dc = data._control;
      if (dc && dc.save_action)
        this.save_action = dc.save_action.on_update;
    }
  }

  go_to_master() {
    var master_id = this.master_id;

    _fpa.send_ajax_request("/masters.json?master[id]=" + master_id + "&commit=search", {
      try_app_callback: function (el, data) {
        _fpa.hide_modal(1);


        // After the initial callback, set a post callback on the actual target in the master
        // search results list. This appears to need some delay to work, so may not be fully reliable.
        window.setTimeout(function () {
          var $target = $(`[data-sub-for-root="master_id"][data-sub-id="${master_id}"]`)
          $target[0].app_post_callback = function (el, data) {
            _fpa.utils.scrollTo($target, 200, -100)
          }
        }, 300)

      },

    });
  }

  redirect_to_url() {
    window.location.href = this.action_value
  }

  create_next_creatable() {
    var sel = '.activity-logs-generic-block[data-sub-id="' + this.master_id + '"][data-sub-item="' + this.obj_data.item_types + '"] a.add-item-button[data-extra-log-type]';
    var res = $(sel).not('[disabled]').first().click();
  }

  // Find the nav tab anchor for the given panel value within this master panel.
  // Primary lookup uses data-panel-tab:
  //   - Single-resource contains.resources panels: data-panel-tab = resource name
  //     (e.g. 'activity_log__play_ipa_assignments'), consistent with standard AL tabs.
  //   - Multi-resource contains.resources panels: data-panel-tab = panel_name
  //     (e.g. 'play-ipa-tracker').
  // Fallback uses data-alt-click-id to support legacy panel_name-based save_action configs
  // and old click-target links that reference the resource-hyphenated tab id.
  find_panel_tab() {
    var master_scope = '.master-panel[data-master-id="' + this.master_id + '"] ';
    var tab = $(master_scope + 'a[data-panel-tab="' + this.action_value + '"]');
    if (!tab.length) {
      tab = $(master_scope + 'a[data-alt-click-id="tab-' + this.action_value.replace(/__/g, '--').replace(/_/g, '-') + '"]');
    }
    return tab;
  }

  show_panel() {
    var tab = this.find_panel_tab().click();
    window.setTimeout(function () {
      $(tab.attr('data-target')).collapse('show');
    }, 500);
  }

  hide_panel() {
    var tab2 = this.find_panel_tab();
    window.setTimeout(function () {
      $(tab2.attr('data-target')).collapse('hide');
    }, 500);
  }


  refresh_panel() {
    var tab3 = this.find_panel_tab();
    var exp = tab3.attr('aria-expanded') == 'true';
    tab3.click();

    if (exp) {
      window.setTimeout(function () {
        $(tab3.attr('data-target')).collapse('show');
      }, 500);
    }
    else {
      window.setTimeout(function () {
        $(tab3.attr('data-target')).collapse('hide');
      }, 500);
    }

  }

  expand_reference() {
    if (!this.block) return;

    // We have to look up the block by id in the timeout callback, since the block may have
    // reloaded and not appear as the original version in the dom
    var block_id = this.block.prop('id');
    var action_value = this.action_value;

    window.setTimeout(function () {
      var block = block = $(`#${block_id}`);
      $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');

      if (action_value === 'next') {
        var ev_link = block.parent().next('.in-item-model-references').find('.mr-expander')
      }
      else {
        var ev_link = block.parent().parent().find(`.in-item-model-references[data-mr-name="${action_value}"]`).find('.mr-expander')
      }

      ev_link.click();
      window.setTimeout(function () {
        _fpa.utils.scrollTo(ev_link, 100, -100)
      }, 500)

    }, 1000)
  }

}
