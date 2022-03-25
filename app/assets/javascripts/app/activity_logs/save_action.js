// Implement save_acton handling for activity logs
// Simply call:
//   _fpa.activity_logs.save_action.handle(block, data)
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

    for (const key in this.save_action) {
      if (!this[key]) throw `save_action is not valid: ${key}`;

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
    _fpa.send_ajax_request("/masters.json?master[id]=" + this.master_id + "&commit=search", {
      try_app_callback: function (el, data) {
        _fpa.hide_modal(1);
      }
    });
  }


  create_next_creatable() {
    var sel = '.activity-logs-generic-block[data-sub-id="' + this.master_id + '"][data-sub-item="' + this.obj_data.item_types + '"] a.add-item-button[data-extra-log-type]';
    var res = $(sel).not('[disabled]').first().click();
  }

  show_panel() {
    var tab = $('.master-panel[data-master-id="' + this.master_id + '"] a[data-panel-tab="' + this.save_action.show_panel + '"]').click();
    window.setTimeout(function () {
      $(tab.attr('data-target')).collapse('show');
    }, 500);
  }

  hide_panel() {
    var tab2 = $('.master-panel[data-master-id="' + this.master_id + '"] a[data-panel-tab="' + this.save_action.hide_panel + '"]');
    window.setTimeout(function () {
      $(tab2.attr('data-target')).collapse('hide');
    }, 500);
  }


  refresh_panel() {
    var tab3 = $('.master-panel[data-master-id="' + this.master_id + '"] a[data-panel-tab="' + this.save_action.refresh_panel + '"]');
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

}
