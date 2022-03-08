_fpa.activity_logs = {

  // when the sub list parent item (e.g. a phone number) is selected style appropriately
  selected_parent: function (block, attrs) {

    $('.activity-log-list .alr-new-block.has-records').addClass('hidden');

    // Find the item sub list (for example, phone numbers in the phone log)
    var items = document.querySelectorAll('.activity-log-sub-list .sub-list-item .list-group');
    // Only if it is visible go and mark the selected items through the sub list and activity log record list
    if ($(items).is(':visible')) {
      for (var item, i = 0; item = items[i]; i++) {
        var el = item.parentNode;
        if (item.getAttribute('data-item-id') == attrs.item_id) {
          el.classList.add('item-highlight');
          el.classList.add('selected-item');
          el.classList.remove('linked-item-highlight');
        }
        else {
          el.classList.remove('item-highlight');
          el.classList.remove('selected-item');
          el.classList.remove('linked-item-highlight');
        }
      }

      $('#activity-logs-master-' + attrs.master_id + '- [data-item-id]').removeClass('item-highlight selected-item');
      $('#activity-logs-master-' + attrs.master_id + '- [data-item-id="' + attrs.item_id + '"]').addClass('item-highlight selected-item');
    }
  },
  unselect_all: function (block, master_id) {
    _fpa.activity_logs.selected_parent(block, { master_id: master_id })
  },

  show_main_block: function (block, data) {

    _fpa.form_utils.format_block(block);
    _fpa.activity_logs.selected_parent(block, { item_id: data.item_id, rec_type: data.rec_type, item_data: data.item_data, master_id: data.master_id });

    _fpa.activity_logs.handle_creatables(block, data);


  },

  show_log_block: function (block, data) {
    _fpa.form_utils.format_block(block);

    $('.activity-log-list .alr-new-block').addClass('hidden');


    var d = data;
    var d0;
    for (var e in data) {
      if (data.hasOwnProperty(e) && e != '_control') {
        d0 = data[e];
        break;
      }
    }

    if (typeof d0 === 'object' && d0.hasOwnProperty('master_id')) {
      // assume if the length is only a single item that it is really the object we are looking for
      d = d0;
    }

    _fpa.activity_logs.handle_creatables(block, data);

    block.parents('.activity-log-list').find('.common-template-item').not('[data-sub-id=' + d.id + ']').each(function () {
      if ($(this).hasClass('prevent-edit')) {
        $(this).find('a.edit-entity').remove();
        $(this).find('.new-block').remove();
        $(this).find('a.add-item-button').remove();
      }
    });


    $('.activity-log-list .new-block').addClass('has-records');
    _fpa.activity_logs.selected_parent(block, { item_id: d.item_id, rec_type: d.rec_type, item_data: d.item_data, master_id: d.master_id });

    window.setTimeout(function () {
      _fpa.activity_logs.handle_save_action(block, data);
    }, 100);

    // Refresh the sub list items, if they are not hidden
    var itype = block.parents('.activity-logs-item-block').first().find('.activity-log-sub-list').attr('data-sub-list');

    if (d._updated && itype) {
      var url = '/masters/' + d.master_id + '/' + itype + '.js';
      _fpa.send_ajax_request(url);
    }
    _fpa.postprocessors.info_update_handler(block, d);
  },

  get_object_data: function (data) {
    data.item_types = data.multiple_results;

    if (!data.item_types) {
      if (!data.item_type) {
        for (var p in data) {
          if (data.hasOwnProperty(p)) {
            var r = data[p].item_type;
            if (r) {
              data = data[p];
              break;
            }
          }
        }
      }
      data.item_types = _fpa.utils.pluralize(data.item_type);
    }
    return data;
  },

  handle_creatables: function (block, data) {
    if (data._control) {
      var control = data._control;
    }
    else {
      var control = data;
    }
    obj_data = _fpa.activity_logs.get_object_data(data);

    if (control && control.creatables) {
      for (var i in control.creatables) {
        if (control.creatables.hasOwnProperty(i)) {
          var c = control.creatables[i];
          var sel = '.activity-logs-generic-block[data-sub-id="' + obj_data.master_id + '"][data-sub-item="' + obj_data.item_types + '"] a.add-item-button[data-extra-log-type="' + i + '"]';
          var ael = $(sel);
          var huc = ael.hasClass('hide-unless-creatable');
          if (!c) {
            if (huc)
              ael.hide();

            ael.attr('disabled', true);
          }
          else {
            if (huc)
              ael.show();

            ael.attr('disabled', false);
          }
        }
      }
    }
  },

  handle_save_action: function (block, data) {

    var save_action;
    if (data._control) {
      obj_data = _fpa.activity_logs.get_object_data(data);

      if (obj_data._created) {
        var dc = obj_data._control;
        if (!dc) dc = data._control;
        if (dc && dc.save_action)
          save_action = dc.save_action.on_create;
      }
      else if (obj_data._updated) {
        var dc = obj_data._control;
        if (!dc) dc = data._control;
        if (dc && dc.save_action)
          save_action = dc.save_action.on_update;
      }


      if (typeof save_action == 'object') {
        if (save_action.go_to_master) {
          _fpa.send_ajax_request("/masters.json?master[id]=" + obj_data.master_id + "&commit=search", {
            try_app_callback: function (el, data) {
              _fpa.hide_modal(1);
            }
          });

        }

        if (save_action.create_next_creatable) {
          var sel = '.activity-logs-generic-block[data-sub-id="' + obj_data.master_id + '"][data-sub-item="' + obj_data.item_types + '"] a.add-item-button[data-extra-log-type]';
          var res = $(sel).not('[disabled]').first().click();
        }
        if (save_action.show_panel) {
          var tab = $('.master-panel[data-master-id="' + obj_data.master_id + '"] a[data-panel-tab="' + save_action.show_panel + '"]').click();
          window.setTimeout(function () {
            $(tab.attr('data-target')).collapse('show');
          }, 500);
        }
        if (save_action.hide_panel) {
          var tab2 = $('.master-panel[data-master-id="' + obj_data.master_id + '"] a[data-panel-tab="' + save_action.hide_panel + '"]');
          window.setTimeout(function () {
            $(tab2.attr('data-target')).collapse('hide');
          }, 500);
        }
        if (save_action.refresh_panel) {
          var tab3 = $('.master-panel[data-master-id="' + obj_data.master_id + '"] a[data-panel-tab="' + save_action.refresh_panel + '"]');
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
    }
  }

};
