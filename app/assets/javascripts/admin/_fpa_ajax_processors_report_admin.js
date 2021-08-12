class ReportSearchAttr {
  constructor() {
    this.search_attr_def = '';
  }

  add_new_item(name) {
    this.search_attr_def += name + ': ';
  }

  add_type_entry(type) {
    this.search_attr_def += '\n  ' + type + ': ';
  }

  add_option_raw_entry(entry) {
    this.search_attr_def += "\n    " + entry
  }

  add_option_entry(key, val) {
    this.add_option_raw_entry(key + ': ' + val.trim());
  }

  add_key_val_options(key, yaml) {
    this.add_option_entry(key, '');
    var ds = yaml.split('\n');
    for (var id in ds) {
      this.search_attr_def += '\n      ' + ds[id];
    }
  }

  add_array_options(key, list) {
    var ds = list.split('\n');
    var listyaml = '';
    for (var id in ds) {
      listyaml += '\n      - ' + ds[id];
    }
    this.add_option_entry(key, listyaml);
  }

}

_fpa.postprocessors_report_admin = {

  setup_search_attrs: function (block) {
    _fpa.postprocessors_report_admin.setup_search_attrs_type(block);
  },

  //
  // Handle the search attribute type selection being changed,
  // to show the appropriate entry fields
  setup_search_attrs_type: function (block) {
    var ra_config_selections = $('#search_attrs_config_selections')[0].CodeMirror;
    var ra_conditions = $('#search_attrs_conditions')[0].CodeMirror;
    $('#search_attrs_type').change(function () {
      var search_attr_type = $(this).val();

      $('#search_attrs_filter').val('all');

      if (search_attr_type == 'config_selector') {
        $('.report-attr-config-selections').collapse('show');
      }
      else {
        $('.report-attr-config-selections').collapse('hide');
        if (ra_config_selections) ra_config_selections.setValue('');
      }

      if (['accuracy_score', 'general_selection', 'protocol', 'sub_process', 'protocol_event', 'item_flag_name', 'user'].indexOf(search_attr_type) >= 0) {
        $('.report-attr-conditions').collapse('show');
      }
      else {
        $('.report-attr-conditions').collapse('hide');
        if (ra_conditions) ra_conditions.setValue('');
      }


      var not_gs = (search_attr_type !== 'general_selection' ? 'hide' : 'show');
      $('.report-attr-checks').collapse(not_gs);
    });

  },

  //
  // Handle the search attribute Add button being clicked,
  // processing the entry fields and formulating the appropriate YAML config
  setup_search_attrs_add: function (block) {
    $('#search_attrs_add').click(function (ev) {
      ev.preventDefault();

      var ra_config_selections = $('#search_attrs_config_selections')[0].CodeMirror;
      var ra_conditions = $('#search_attrs_conditions')[0].CodeMirror;
      var name = $('#search_attrs_name').val();

      if (!name) {
        $.scrollTo('#search_attr_definer');
        $('#search_attrs_name').fadeOut().fadeIn();
        return;
      }

      name = name.underscore();
      var type = $('#search_attrs_type').val();
      var filter = $('#search_attrs_filter').val();
      var no_disabled = $('#search_no_disabled').is(':checked');
      var hidden_field = $('#search_hidden_field').is(':checked');
      var multi = $('#search_attrs_multi').val();
      var label = $('#search_attrs_label').val();
      var defval = $('#search_attrs_default').val();
      if (ra_config_selections) {
        var selections = ra_config_selections.getValue();
      }
      if (ra_conditions) {
        var conditions_yaml = ra_conditions.getValue();
      }
      $('#search_attr_instruction').removeClass('hidden');
      $('#search_attr_insert_name').html(":" + name);

      var rsa = new ReportSearchAttr()

      // Set up the YAML
      rsa.add_new_item(name);
      rsa.add_type_entry(type);

      if (multi) rsa.add_option_entry("multiple", multi);
      if (label) rsa.add_option_entry("label", label);
      if (hidden_field) rsa.add_option_entry("hidden", 'true');
      if (selections) rsa.add_key_val_options("selections", selections);
      if (conditions_yaml) rsa.add_key_val_options('conditions', conditions_yaml);

      if (filter === 'all')
        rsa.add_option_entry('all', 'true');
      else
        rsa.add_option_raw_entry(filter);

      if (defval) {
        if (multi === 'single') rsa.add_option_entry("default", defval);
        else rsa.add_array_options("default", defval)
      }
      else if (no_disabled) rsa.add_option_entry("disabled", 'false');

      // Update the YAML editor 
      var $attel = $('#report_search_attrs');
      var attel = $attel[0];
      attel.CodeMirror.save();
      var v = $attel.val();
      if (v) v = v + "\n\n";
      v = v + rsa.search_attr_def
      v = v.trim();
      $attel.val(v);
      attel.CodeMirror.setValue($attel.val());
      attel.CodeMirror.refresh();

    });
  },

  setup_search_attr_list: function (block) {
    var $item_list = block.find('#search_attr_item_list');
    var $attel = $('#report_search_attrs');

    var items = jsyaml.load($attel.val())

    for (var item in items) {
      if (!items.hasOwnProperty(item)) continue;
      var li = `<li>${item}</li>`
      $item_list.append(li)
    };


  },

  handle_admin_report_config: function (block) {

    _fpa.form_utils.setup_textarea_editor(block)

    $('.report-attr-checks').collapse('hide');
    $('#search_no_disabled').val('1').attr('checked', true);

    _fpa.postprocessors_report_admin.setup_search_attrs_type(block);
    _fpa.postprocessors_report_admin.setup_search_attrs_add(block);
    _fpa.postprocessors_report_admin.setup_search_attr_list(block);

  }
};
$.extend(_fpa.postprocessors, _fpa.postprocessors_report_admin);
