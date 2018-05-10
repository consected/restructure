_fpa.show_if = {
  forms: {}
};

_fpa.show_if.methods = {

  show_items: function(block, data) {
    if(!block || !data) return;
    var item_key = data.item_type;
    var form_key = data.full_option_type;
    if(!form_key && data.option_type) form_key = item_key + '_' + data.option_type;
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

    var cond_types = ['all', 'any', 'not_all', 'not_any'];
    var obj = _fpa.show_if.forms[form_key];

    if(obj) {
      var field_def_init = obj[field_name];
      var field_def = field_def_init;

      for(var cond_type in field_def_init) {
        // if the field definition specifies a condition type, use it
        if( field_def_init.hasOwnProperty(cond_type) && cond_types.indexOf(cond_type) >= 0) {
          field_def = field_def_init[cond_type];
        }
        else {
          cond_type = 'all';
        }

        var cond_success = true;
        for(var cond_field in field_def) {
          if(field_def.hasOwnProperty(cond_field)) {
            // Expect field data
            var exp_field_value = data[cond_field];
            // to have value
            var exp_value = field_def[cond_field];

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

            if(cond_type == 'all') {
              cond_success = cond_success && (exp_field_value == exp_value);
            }
            else if(cond_type == 'not_all') {
              if(exp_field_value != exp_value) {
                cond_success = true;
                break;
              }
              cond_success = false;
            }
            else if(cond_type == 'any') {
              cond_success = (exp_field_value == exp_value);
              if(cond_success) break;
            }
            else if(cond_type == 'not_any') {
              if(exp_field_value == exp_value) {
                cond_success = false;
                break;
              }
            }
          }
        }
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
    }
  }

};
