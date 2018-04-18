_fpa.show_if = {
  forms: {}
};

_fpa.show_if.methods = {

  show_items: function(block, data) {
    if(!block || !data) return;
    var item_key = data.item_type;
    if(!item_key) return;

    var obj = _fpa.show_if.forms[item_key];
    if(obj) {
      for(var show_field in obj) {
        if(obj.hasOwnProperty(show_field)) {
          _fpa.show_if.methods.show_item(block, data, item_key, show_field);
        }
      }
    }

  },

  show_item: function(block, data, form_name, field_name) {
    var obj = _fpa.show_if.forms[form_name];
    if(obj) {
      var field_def = obj[field_name];
      for(var cond_field in field_def) {
        if(field_def.hasOwnProperty(cond_field)) {
          // Expect field data
          var exp_field_value = data[cond_field];
          // to have value
          var exp_value = field_def[cond_field];

          // generate the class names for the field to be conditionally hidden
          var show_field_class = '.' + form_name.hyphenate() + '-' + field_name;
          var sels = ['.list-group-item.caption-before' + show_field_class, '.list-group-item.result-field-container' + show_field_class, '.list-group-item.edit-field-container' + show_field_class];
          var sel = sels.join(', ');
          var els = block.find(sel);

          var cond_success = (exp_field_value == exp_value);

          if(cond_success) {
            els.show();
          }
          else {
            els.hide();
          }
        }
      }
    }
  }
};
