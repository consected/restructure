_fpa.loaded.reports = function () {

  _fpa.postprocessors.reports_form($('.report-criteria'));
  $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');



  // If this an editable data form, automatically submit it if there are no criteria fields to enter
  if ($('#editable_data').length == 1 && $('.report-criteria-fields').length >= 1)
    $('input[type="submit"][value="table"]').click();
};

_fpa.reports = {

  window_scrolling: function () {
    $('html').on('wheel', function (e) {
      if (e.originalEvent.deltaY > 0 && $('.chosen-container-active').length == 0) {
        _fpa.reports.report_position_buttons('go-to-results');
        _fpa.reports.reset_window_scrolling();
      }
    });
  },
  reset_window_scrolling: function () {
    $('html').off('wheel');
  },
  report_position_buttons: function (to_loc) {
    var sb = $('.show-results-btn');
    var rf = $('.back-to-search-form-btn');
    if (sb.length == 0 && rf.length == 0) {
      return;
    }

    sb.not('.has-rsf-clicks').click(function (e) {
      e.preventDefault();
      _fpa.reports.report_position_buttons('go-to-results');
    }).addClass('has-rsf-clicks');
    rf.not('.has-rsf-clicks').click(function (e) {
      e.preventDefault();
      _fpa.reports.report_position_buttons('go-to-form');
    }).addClass('has-rsf-clicks');

    if (to_loc == 'go-to-results') {
      sb.hide();
      rf.show();
      _fpa.reports.reset_window_scrolling();
      $.scrollTo('.report-results-block', 200);
    }
    else if (to_loc == 'go-to-form') {
      sb.show();
      rf.hide();
      _fpa.reports.window_scrolling();
      $.scrollTo('#body-top', 200);
    }
    // window.location.hash = '';
  },
  results_subsearch: function (block) {
    block.find('td[data-col-type^="search_reports_"]').not('.attached_report_search').each(function () {
      var dct = $(this).attr('data-col-type');
      if (!$(this).hasClass('attached_report_search') && dct.match(/search_reports_[0-9]+_.+/)) {
        var dct_parts = dct.split('_', 4);

        var dct_field = dct_parts[3];
        var dct_report = dct_parts[2];
        var dct_search = $(this).html().trim();

        var url = "/reports/" + dct_report + ".json?&search_attrs[" + dct_field + "]=" + dct_search + "&commit=search";

        var new_l = $('<a href="' + url + '" data-remote="true" data-result-target="#modal_results_block" data-result-target-force="true" data-template="modal-pi-search-results-template" title="click to search">' + $(this).html() + '</a>');

        $(this).html(new_l);
        $(this).addClass('attached_report_search')
        new_l.click(function () {
          var h = '<div id="modal_results_block" class=""></div>';

          _fpa.show_modal(h, "Search results for " + dct_search, true);

        });
      }
    }).addClass('attached_report_search');
  },

  results_perform_action_link: function (block) {
    block.find('td[data-col-type^="perform action:"]').not('.attached_report_perform_action').each(function () {

      var dct = $(this).attr('data-col-type');

      var dct_parts = dct.split(':', 2);
      var dct_action = dct_parts[1];
      var orig_action = dct_parts[1];
      var dct_json = $(this).html();

      if (!dct_json || dct_json == '') return;

      var act_config = JSON.parse(dct_json);
      var base_url = act_config.perform_action;
      delete act_config.perform_action;

      if (act_config.label) {
        dct_action = act_config.label;
        delete act_config.label;
      }

      var params = {};
      for (var k in act_config) {
        if (act_config.hasOwnProperty(k)) {
          var v = act_config[k];
          if (base_url.indexOf('!' + k) >= 0) {
            base_url = base_url.replace('!' + k, v);
          }
          else {
            params[k] = v
          }
        }
      }

      var dctaus = 'report_' + orig_action.underscore();

      var pstring = $.param(params);

      var new_html = '<a href="' + base_url + '?' + pstring + '" target="report-perform-action" class="' + dctaus + '">' + dct_action + '</a>';

      $(this).html(new_html);

      if (orig_action.trim() == 'view file') {
        _fpa.secure_view.setup_links($(this), 'a.' + dctaus);
        $('a.' + dctaus).on('click', function (ev) {
          ev.preventDefault();
        });
      }



    }).addClass('attached_report_perform_action');

  },


  results_select_items_for_form: function (block) {

    var dct;
    var dct_parts;

    block.find('td[data-col-type^="chart:"]').not('.attached_report_chart').each(function () {

      var row = $(this).parent();
      var chart_dct = $(this).attr('data-col-type');

      // chart_dct_parts = chart_dct.split(':', 3);

      var chart_dct_json = $(this).html();

      if (!chart_dct_json || chart_dct_json == '') return;

      // Get values like "colval.xyz" for substitution
      var cols = chart_dct_json.match(/colval\.[a-zA-Z0-9_]+/g);

      if (cols) {
        for (var i = 0; i < cols.length; i++) {
          var c = cols[i];
          var cname = c.split('.')[1];
          var colval = row.find('td[data-col-type="' + cname + '"]').html();
          if (colval) {
            colval = colval.trim()
          } else {
            colval = null;
          }

          chart_dct_json = chart_dct_json.replace(c, colval);
        }
      }

      var chart_act_config = JSON.parse(chart_dct_json);

      chart_act_config.options = chart_act_config.options || {};
      // chart_act_config.options.legend = chart_act_config.options.legend || {display: false};

      var name = chart_act_config.label;
      var value = chart_act_config;

      var width = chart_act_config.width;
      var height = chart_act_config.height;

      if (width || height) {
        var fixed_size = true;
      }

      width = width || 100;
      height = height || 100;

      chart_act_config.options.responsive = !fixed_size;

      var new_html = $('<canvas width="' + width + '" height="' + height + '"></canvas>');

      $(this).html(new_html);

      var ctx = $(this).find('canvas');
      var myPieChart = new Chart(ctx, value);

      var head = $('th[data-col-type="' + chart_dct + '"]').not('.added-chart-legend');
      if (head.length > 0) {
        var headp = head.find('p.table-header-col-type');
        headp.html(name);
        head.addClass('no-sort added-chart-legend');
      }



    }).addClass('attached_report_chart');

    block.find('td[data-col-type^="select items:"]').not('.attached_report_select_items').each(function () {

      dct = $(this).attr('data-col-type');

      dct_parts = dct.split(':', 3);

      var dct_json = $(this).html();

      if (!dct_json || dct_json.trim() == '') return;

      var act_config = JSON.parse(dct_json);

      var name = act_config.field_name;
      var value = act_config.value;
      var checked = act_config.value.init_value ? 'checked="checked"' : ''
      var h = '<input type="checkbox" class="report-file-selector" name="' + name + '" ' + checked + '/>';
      var $h = $(h);
      $h.val(JSON.stringify(value));

      var new_html = $h;

      $(this).html(new_html);


    }).addClass('attached_report_select_items');

    if (!dct_parts) return;

    var dct_action = dct_parts[1].trim();
    if (dct_parts[2]) {
      var extra_val = dct_parts[2].trim();
    }

    var report_id = $('.report-container').attr('data-report-id');


    if (dct_action == 'download files') {
      var $f = $('<form id="itemselection-for-report" method="post" action="/nfs_store/downloads/multi" target="download_files"><input type="hidden" name="nfs_store_download[container_id]" value="multi"></form>');
    }
    else if (dct_action == 'add to list') {
      var $f = $('<form id="itemselection-for-report" method="post" action="/reports/' + report_id + '/add_to_list.json" class="report-add-to-list" data-remote="true"><input type="hidden" name="add_to_list[list_name]" value="' + extra_val + '"></form>');
    }
    else if (dct_action == 'update list') {
      var $f = $('<form id="itemselection-for-report" method="post" action="/reports/' + report_id + '/update_list.json" class="report-update-list" data-remote="true"><input type="hidden" name="update_list[list_name]" value="' + extra_val + '"></form>');
    }
    else if (dct_action == 'remove from list') {
      var $f = $('<form id="itemselection-for-report" method="post" action="/reports/' + report_id + '/remove_from_list.json" class="report-remove-from-list" data-remote="true"><input type="hidden" name="remove_from_list[list_name]" value="' + extra_val + '"></form>');

      var cblock = $('[data-result="#report-embedded"]');
      if (cblock.length == 0) cblock = $('body');

      cblock.find('#report_query_form').addClass('keep-notices');
      $f.on('ajax:success', function (e, data, status, xhr) {
        cblock.find('#report-form-submit-btn').addClass('keep-notices').click();
      });

    }

    var b = '<span class="report-files-actions"><input type="checkbox" id="report-select-all-files"><label for="report-select-all-files">select all</label></span><span class="report-files-actions-btn"><input id="submit-report-selections" type="submit" value="' + dct_action + '" class="btn btn-primary rep-sel-action-' + dct_action.replace(' ', '-') + '"/></span>'
    var $t = $('table.report-table');
    $f.insertBefore($t);
    $t.appendTo($('#itemselection-for-report'));

    // If the select all checkbox is changed
    // check or uncheck all the entries.
    // Briefly disable auto submit on the form, to avoid potentially
    // thousands of individual checkbox changes being submitted to the server.
    // Wait a moment then trigger the auto submit afterwards\
    $(document).off('change', '#report-select-all-files');
    $(document).on('change', '#report-select-all-files', function () {
      $f.addClass('report-select-prevent-auto-submit');
      var allels = $('.report-file-selector');
      if ($(this).is(':checked'))
        allels.attr('checked', true);
      else
        allels.attr('checked', null);

      window.setTimeout(function () {
        $f.removeClass('report-select-prevent-auto-submit');
        _fpa.reports.submit_selections();
      }, 100);
    });

    // For any individual selector checkbox submit selection
    $(document).off('change', 'input.report-file-selector');
    $(document).on('change', 'input.report-file-selector', function () {
      window.setTimeout(function () {
        _fpa.reports.submit_selections();
      }, 100);
    });

    $t.find('thead th').each(function () {
      if ($(this).find('p:first').html() == dct) {
        $(this).addClass('no-sort');
        $(this).append(b);
      }
    });


  },

  // If the update list, add to list or remove from list submit buttons are 
  // hidden, and the form is not marked to prevent auto submit,
  // then submit the recent changes to the list
  submit_selections: function () {
    var $form = $('#itemselection-for-report');
    var $submit = $form.find('#submit-report-selections');

    if ($submit.is(':visible') || $form.hasClass('report-select-prevent-auto-submit')) {
      return;
    }

    $submit[0].click();
  },

  run_autos: function (sel) {
    if (!sel) sel = '.report-auto';
    $(sel).each(function () {
      var t = $(this);
      var id = t.attr('data-report-id');
      _fpa.ajax_working(t);
      $.ajax({
        url: '/reports/' + id + '.json?search_attrs=_use_defaults_',
        success: function (data) {
          _fpa.ajax_done(t);
          var res;
          var sa;
          if (data && data.search_attributes) {
            sa = "";

            for (var i in data.search_attributes) {
              if (data.search_attributes.hasOwnProperty(i) && i !== 'ids_filter_previous' && i !== '_use_defaults_') {
                var d = data.search_attributes[i];
                sa += '<div class="report-search-attr"><span class="attr-label">' + i + '</span><span class="attr-val">' + _fpa.utils.pretty_print(d, { return_string: true }) + '</span></div>';
              }
            }

            //sa = JSON.stringify(data.search_attributes, null, '<div>  ').replace(/\{/g, '<div>  ').replace(/\}/g, '</div>').replace(/\"|\[|\]|/g, '').replace(/_/g ,' ');
          }
          if (data && data.results && data.results[0]) {
            // res = JSON.stringify(data.results, null, '  ').replace(/\{/g, '<div>  ').replace(/\},?/g, '</div>').replace(/\"|\[|\]|/g, '');
            var rcount = data.results.length;
            if (rcount == 1)
              res = rcount + ' result';
            else
              res = rcount + ' results';

          } else {
            res = '-';
          }
          t.find('.report-measure').html(res);
          if (sa)
            t.find('.report-search-attr').html(sa);
        }
      });

    });
  }


};
