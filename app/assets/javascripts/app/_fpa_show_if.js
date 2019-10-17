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

    window.setTimeout(function() {
      _fpa.form_utils.setup_e_signature(block, true);

      var els = $('.dialog-made-visible');
      if(!els.length) return;
      var wh = $(window).height();
      var rect = els.first().get(0).getBoundingClientRect();
      var not_visible = !(rect.top >= 0 && rect.top <= wh/2);
      if(not_visible) {
        $(document).scrollTo(els.first(), 200, {offset: -0.2 * wh});
      }
      els.removeClass('dialog-made-visible');

    }, 250);

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
      '.list-group-item.edit-field-container' + show_edit_field_class,
      '.list-group-item.caption-before' + show_edit_field_class];
      var sel = sels.join(', ');
      var els = block.find(sel);


      if(cond_success) {
        var prev_vis = els.is(':visible');
        els.show();
        if(!prev_vis) {
          var btn = els.find('.in-form-dialog-btn:visible');

          btn.click();

          els.filter('.dialog-before').first().addClass('dialog-made-visible');

        }
      }
      else {
        els.hide();
      }

    }
  },

  calc_conditions: function(cond_def_init, data) {

    // Valid condition types
    var cond_types = ['all', 'any', 'not_all', 'not_any'];
    var cond_success = true;

    // Iterate through each top level rule
    for(var cond_type in cond_def_init) {
      // Set the default in case a condition type was not specified and we have a field name instead
      var cond_def = cond_def_init;

      // Pick up a common yaml error
      if(cond_type == '<<') {
        console.log(cond_def_init);
        console.log(cond_type);
        throw "Bad definition."
      }

      // if the field definition specifies a condition type, use it
      // otherwise assume a condition type 'all'
      var is_cond_type = false;
      if( cond_def_init.hasOwnProperty(cond_type) && typeof(cond_def_init[cond_type]) == 'object' && !Array.isArray(cond_def_init[cond_type])) {
        // console.log(cond_type)
        for(var ci in cond_types) {
          var cv = cond_types[ci];
          if(cond_type.indexOf(cv) === 0) {
            cond_def = cond_def_init[cond_type];
            is_cond_type = true;
            break;
          }
        }
      }

      if(!is_cond_type) {
        cond_type = 'all';
      }

      // Now iterate through each of the fields in the definition
      for(var cond_field in cond_def) {
        if(cond_def.hasOwnProperty(cond_field)) {
          // Expect field data
          var exp_field_value = data[cond_field];
          if(typeof exp_field_value == 'number') exp_field_value = exp_field_value.toString();
          
          // to have value
          var exp_value = cond_def[cond_field];

          if(exp_value == null)
            exp_value = [exp_value];
          else if(typeof exp_value == 'string')
            exp_value = [exp_value];
          else if(typeof exp_value == 'boolean') {
            exp_value = [exp_value, (exp_value ? 'yes' : 'no')];
          }
          else if(typeof exp_value == 'number') {
            exp_value = [exp_value.toString()];
          }
          else if(typeof exp_value == 'object') {
            for(var i = 0; i < exp_value.length; i ++) {
              if(exp_value[i] === true) exp_value.push('yes');
              if(exp_value[i] === false) exp_value.push('no');
              if(typeof exp_value[i] == 'number') exp_value[i] = exp_value[i].toString();
            }
          }

          var matches = exp_value.includes(exp_field_value);
          if(cond_type.indexOf('all') === 0) {
            cond_success = cond_success && matches;
            if (!matches) break;
          }
          else if(cond_type.indexOf('not_all') === 0) {
            if(!matches) {
              cond_success = true;
              break;
            }
            cond_success = false;
          }
          else if(cond_type.indexOf('any') === 0) {
            // This checks that only if all are false does the cond_success get to be false,
            // since any success breaks out of the loop, having already set the result to true
            cond_success = matches;
            if(cond_success) break;
          }
          else if(cond_type.indexOf('not_any') === 0) {
            if(matches) {
              cond_success = false;
              break;
            }
          }
        }
      }
      if(!cond_success) break;
    }

    return cond_success;

  }



};
