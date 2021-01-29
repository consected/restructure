_fpa.postprocessors_report_admin = {

  handle_admin_report_config: function (block) {

    var ra_config_selections = $('#search_attrs_config_selections')[0].CodeMirror;
    var ra_conditions = $('#search_attrs_conditions')[0].CodeMirror;
    _fpa.form_utils.setup_textarea_editor(block)

    $('.report-attr-checks').collapse('hide');
    $('#search_no_disabled').val('1').attr('checked', true);


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

    $('#search_attrs_add').click(function (ev) {
      ev.preventDefault();
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
        var c = ra_conditions.getValue();
      }
      $('#search_attr_instruction').removeClass('hidden');
      $('#search_attr_insert_name').html(":" + name);


      var search_attr_def = name + ': ';
      {
        search_attr_def += '\n  ' + type + ': ';
        if (filter === 'all') {
          search_attr_def += '\n    all: true';
        } else {
          search_attr_def += "\n    " + filter;
        }
        if (multi)
          search_attr_def += "\n    multiple: " + multi;
        if (label)
          search_attr_def += "\n    label: " + label;

        if (defval) {
          if (multi === 'single') {
            defval = defval.trim();
          } else {
            var ds = defval.split('\n');
            defval = '';
            for (var id in ds) {
              defval += '\n      - ' + ds[id];
            }
          }

          search_attr_def += "\n    default: " + defval;
        }
        else {
          if (no_disabled)
            search_attr_def += "\n    disabled: false";
        }


        if (hidden_field)
          search_attr_def += "\n    hidden: true";

        if (selections) {
          search_attr_def += "\n    selections: ";
          var ds = selections.split('\n');
          for (var id in ds) {
            search_attr_def += '\n      ' + ds[id];
          }
        }
        if (c) {
          search_attr_def += "\n    conditions: ";
          var ds = c.split('\n');
          for (var id in ds) {
            search_attr_def += '\n      ' + ds[id];
          }
        }


      }
      var $attel = $('#report_search_attrs');
      var attel = $attel[0];


      attel.CodeMirror.save();
      var v = $attel.val();
      $attel.val(v + "\n\n" + search_attr_def);
      attel.CodeMirror.setValue($attel.val());
      attel.CodeMirror.refresh();

    });
  }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_report_admin);
