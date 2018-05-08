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
      var cond_success = true;
      for(var cond_field in field_def) {
        if(field_def.hasOwnProperty(cond_field)) {
          // Expect field data
          var exp_field_value = data[cond_field];
          // to have value
          var exp_value = field_def[cond_field];

          // generate the class names for the field to be conditionally hidden
          var show_field_class = '.' + form_name.hyphenate() + '-' + field_name;
          var sels = ['.list-group-item.caption-before' + show_field_class,
                      '.list-group-item.dialog-before' + show_field_class,
                      '.list-group-item.result-field-container' + show_field_class,
                      '.list-group-item.result-notes-container' + show_field_class,
                      '.list-group-item.edit-field-container' + show_field_class];
          var sel = sels.join(', ');
          var els = block.find(sel);

          cond_success = cond_success && (exp_field_value == exp_value);
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
  },


  // show_creatables: function(block, data) {
  //   if(!block || !data) return;
  //   var item_key = data.item_type;
  //   if(!item_key) return;
  //
  //   var obj = _fpa.show_if.forms[item_key];
  //   if(obj) {
  //     for(var show_field in obj) {
  //       if(obj.hasOwnProperty(show_field)) {
  //         _fpa.show_if.methods.show_creatable(block, data, item_key, show_field);
  //       }
  //     }
  //   }
  //
  // },
  //
  // show_creatable: function(block, data, al_name, type_name) {
  //   var obj = _fpa.show_if.forms[al_name];
  //   if(obj) {
  //     var field_def = obj[type_name];
  //     var cond_success = true;
  //     for(var cond_field in field_def) {
  //       if(field_def.hasOwnProperty(cond_field)) {
  //         // Expect field data
  //         var exp_field_value = data[cond_field];
  //         // to have value
  //         var exp_value = field_def[cond_field];
  //
  //         // generate the class names for the field to be conditionally hidden
  //         var show_field_class = '.' + al_name.hyphenate() + '-' + type_name;
  //         var sels = ['.action-buttons .add-item-button' + show_field_class];
  //         var sel = sels.join(', ');
  //         var els = block.find(sel);
  //
  //         cond_success = cond_success && (exp_field_value == exp_value);
  //       }
  //     }
  //     if(cond_success) {
  //       els.show();
  //     }
  //     else {
  //       els.hide();
  //     }
  //   }
  // }
};
