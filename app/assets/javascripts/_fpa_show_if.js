_fpa.show_if = {
  forms: {}
};

_fpa.show_if.methods = {

  show_items: function(block, data) {
    if(!block || !data) return;

    if(data.embedded_item)
      _fpa.show_if.methods.show_items(block, data.embedded_item);

    var item_key = data.item_type;
    var form_key = data.full_option_type;
    if(!form_key && data.option_type && data.option_type != 'default') form_key = item_key + '_' + data.option_type;
    if(!form_key) form_key = item_key;
    if(!item_key) return;

    var obj = _fpa.show_if.forms[form_key];
    if(obj) {
      for(var show_field in obj) {
        if(obj.hasOwnProperty(show_field)) {
          _fpa.show_if.methods.show_item(block, data, item_key, show_field, form_key);
        }
      }
    }

  },

  show_item: function(block, data, form_name, field_name, form_key) {

    var obj = _fpa.show_if.forms[form_key];

    if(obj) {
      var field_def_init = obj[field_name];

      var cond_success = _fpa.show_if.methods.calc_conditions(field_def_init, data);

      // generate the class names for the field to be conditionally hidden
      var show_field_class = '.' + form_key.hyphenate() + '-' + field_name;
      var show_edit_field_class = '.' + form_name.hyphenate() + '-' + field_name;
      var sels = ['.list-group-item.caption-before' + show_field_class,
      '.list-group-item.dialog-before' + show_field_class,
      '.list-group-item.result-field-container' + show_field_class,
      '.list-group-item.result-notes-container' + show_field_class,
      '.list-group-item.edit-field-container' + show_edit_field_class];
      var sel = sels.join(', ');
      var els = block.find(sel);


      if(cond_success) {
        var prev_vis = els.is(':visible');
        els.show();
        if(!prev_vis) {
          var btn = els.find('.in-form-dialog-btn:visible')
          btn.click();
        }
      }
      else {
        els.hide();
      }

    }
  },

  calc_conditions: function(cond_def_init, data) {

    var cond_types = ['all', 'any', 'not_all', 'not_any'];
    var cond_success = true;

    for(var cond_type in cond_def_init) {
      var cond_def = cond_def_init;
      // if the field definition specifies a condition type, use it
      if( cond_def_init.hasOwnProperty(cond_type) && cond_types.indexOf(cond_type) >= 0) {
        cond_def = cond_def_init[cond_type];
      }
      else {
        cond_type = 'all';
      }

      for(var cond_field in cond_def) {
        if(cond_def.hasOwnProperty(cond_field)) {
          // Expect field data
          var exp_field_value = data[cond_field];
          // to have value
          var exp_value = cond_def[cond_field];
          if(typeof exp_value == 'string')
            exp_value = [exp_value];
          else if(typeof exp_value == 'boolean') {
            exp_value = [exp_value, (exp_value ? 'yes' : 'no')];
          }
          else if(typeof exp_value == 'number') {
            exp_value = [exp_value];
          }
          else if(typeof exp_value == 'object') {
            for(var i = 0; i < exp_value.length; i ++) {
              if(exp_value[i] === true) exp_value.push('yes');
              if(exp_value[i] === false) exp_value.push('no');
            }
          }

          if(cond_type == 'all') {
            cond_success = cond_success && (exp_value.includes(exp_field_value));
          }
          else if(cond_type == 'not_all') {
            if(!exp_value.includes(exp_field_value)) {
              cond_success = true;
              break;
            }
            cond_success = false;
          }
          else if(cond_type == 'any') {
            cond_success = (exp_value.includes(exp_field_value));
            if(cond_success) break;
          }
          else if(cond_type == 'not_any') {
            if(exp_value.includes(exp_field_value)) {
              cond_success = false;
              break;
            }
          }
        }
      }
    }

    return cond_success;

  }



};
