_fpa.postprocessors_activity_logs = {};
_fpa.preprocessors_activity_logs = {};
_fpa.activity_logs.generate_postprocessors = function (item_type_name, option_type_config) {

  var item_type_name_plural = '';
  var l = item_type_name.length;
  if (item_type_name[l - 1] == 'y') {
    item_type_name_plural = item_type_name.substring(0, l - 1) + 'ies';
  }
  else {
    item_type_name_plural = item_type_name + 's';
  }

  _fpa.postprocessors_activity_logs['activity_log__' + item_type_name_plural + '_main_result_template'] = function (block, data) {
    _fpa.activity_logs.show_main_block(block, data);
  };
  _fpa.preprocessors_activity_logs['activity_log__' + item_type_name_plural + '_main_result_template'] = function (block, data) {
    _fpa.preprocessors.activity_log_show_log_block(block, data);
  };
  _fpa.postprocessors_activity_logs['activity_log__' + item_type_name + '_primary_result_template'] = function (block, data) {
    _fpa.activity_logs.show_log_block(block, data);
  };
  _fpa.postprocessors_activity_logs['activity_log__' + item_type_name + '_blank_log_result_template'] = function (block, data) {
    _fpa.activity_logs.show_log_block(block, data);
  };

  if (option_type_config) {
    for (k in option_type_config) {
      if (option_type_config.hasOwnProperty(k)) {
        _fpa.postprocessors_activity_logs['activity_log__' + item_type_name + '_' + option_type_config[k].name + '_result_template'] = function (block, data) {
          _fpa.activity_logs.show_log_block(block, data);
        };
        _fpa.preprocessors_activity_logs['activity_log__' + item_type_name + '_' + option_type_config[k].name + '_result_template'] = function (block, data) {
          _fpa.preprocessors.activity_log_show_log_block(block, data);
        };
      }
    }
  }

  _fpa.postprocessors_activity_logs['open_activity_log__' + item_type_name] = function (link, block, href) {
    var master_id = link.attr('data-master-id');
    _fpa.send_ajax_request('/masters/' + master_id + '/activity_log/' + item_type_name_plural, {
      try_app_callback: function () {
        // if($(href).length === 0) {
        //   var n = item_type_name.replace(/_/g, '-');
        //   href = href.replace(n, n + '-blank-log');
        // }

        // handling the success of the ajax call, but since we are relying on a subscription to get fired that this has no control over,
        // just put in a delay to allow the templates time to render.
        // this will probably be sufficient in most cases.

        window.setTimeout(function () {
          var target_block = _fpa.utils.jump_to_linked_item(href);
          _fpa.form_utils.format_block(target_block.parents('.activity-log-list'));
          _fpa.activity_logs.unselect_all(target_block, master_id)
        }, 1000)
      }
    });
  },
    _fpa.postprocessors_activity_logs['sub_list_' + item_type_name + '_result_template'] = function (block, data) {
      var el = null;
      for (el in data) {
        break;
      }
      if (data[el] && data[el].rec_type) {
        if (item_type_name != data[el].item_type + "_" + data[el].rec_type) {
          block.hide();
        }
      }
      _fpa.form_utils.format_block(block);
    }


  $.extend(_fpa.postprocessors, _fpa.postprocessors_activity_logs);
  $.extend(_fpa.preprocessors, _fpa.preprocessors_activity_logs);

}

_fpa.postprocessors.activity_log_edit_form = function (block, data) {
  _fpa.activity_logs.show_only_one(block, data)
}


_fpa.preprocessors.activity_log_edit_form = function (block, data) {
  $('.activity-log-list .new-block').each(function () {
    $(this).hide().html('');
  });
  block.show();

}


_fpa.preprocessors.activity_log_show_log_block = function (block, data) {
  // _fpa.preprocessors.dynamic_block_references(block, data)
  // {

  //   var ds;
  //   if (data.multiple_results) {
  //     ds = data[data.multiple_results]
  //   }
  //   else {
  //     for (var e in data) {
  //       if (data.hasOwnProperty(e) && e != '_control') {
  //         ds = [data[e]];
  //         break;
  //       }
  //     }
  //   }

  //   /* Decide whether to show a model reference as embedded or in a list */
  //   for (var i = 0; i < ds.length; i++) {
  //     var d = ds[i];
  //     var no_creatable_references;
  //     if (d.creatable_model_references) {
  //       no_creatable_references = true;
  //       var cr0 = null;
  //       for (var p in d.creatable_model_references) {
  //         if (d.creatable_model_references.hasOwnProperty(p) && d.creatable_model_references[p]) {
  //           for (var p1 in d.creatable_model_references[p]) {
  //             if (d.creatable_model_references[p].hasOwnProperty(p1)) {
  //               no_creatable_references = d.creatable_model_references[p][p1] != 'many';
  //             }
  //           }
  //         }
  //       }
  //     }

  //     d._show_embedded_as_single_item = (d.model_references && d.model_references.length == 1 && no_creatable_references);
  //   }
  // }


}
