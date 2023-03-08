_fpa.preprocessors_reports = {
  report_edit_form: function (block) {

    $('.report-item-edit').find('.report-edit-cancel').click();

  },

  embedded_report: function (block, data) {
    var h = '<div id="modal_results_block" class=""></div>';
    _fpa.show_modal(h, null, true);
  },

};

_fpa.postprocessors_reports = {

  table_cell_types: {
    trackers:
      { protocols: 'protocol_id', sub_processes: 'sub_process_id', protocol_events: 'protocol_event_id', users: 'user_id' },
    tracker_history:
      { protocols: 'protocol_id', sub_processes: 'sub_process_id', protocol_events: 'protocol_event_id', users: 'user_id' },
    masters:
      { accuracy_scores: 'rank' },
    player_infos:
      { accuracy_scores: 'rank', users: 'user_id' },
    player_contacts:
      { 'general_selections-item_type+player_contacts_rank': 'rank', users: 'user_id' },
    addresses:
      { 'general_selections-item_type+addresses_rank': 'rank', users: 'user_id' }
  },

  embedded_report: function (block, data) {
    _fpa.report_criteria.reports_form(block, data);
    block.find('[type="submit"].auto-run').click();
    // Change the id, so that embedded report links inside the embedded report will function
    $('#modal_results_block').prop('id', 'modal_results_block_1')
  },

  report_embed_dynamic_block: function (block, data) {
    var us_name = block.attr('data-model-name')
    var hyph_name = us_name.hyphenate()
    var id = block.attr('data-id')
    var master_id = block.attr('data-master-id')
    var target_block = "report-result-embedded-block"
    var html = $(`<div id="${target_block}-outer"><div id="${target_block}" class="common-template-item index-1" data-model-data-type="dynamic_model" data-subscription="${hyph_name}-edit-form-${master_id}-${id}" data-template="${hyph_name}-result-template" data-item-class="dynamic_model__${us_name}" data-sub-item="dynamic_model__${us_name}" data-sub-id="${id}" data-item-id="" data-preprocessor="${us_name}_edit_form"></div></div>`)
    if ($(block).contents().length == 0) {
      _fpa.hide_modal(1);
      return;
    }
    _fpa.show_modal(html, null, true, 'embedded-dynamic-block', 1)
    window.setTimeout(function () {
      $(block).contents().appendTo(`#${target_block}`)
      $(block).html('');
      window.setTimeout(function () {
        _fpa.form_utils.resize_labels($(`#${target_block}`), null, true)
      }, 500);
    }, 500);
  },

  reports_form: function (block, data) {
    _fpa.report_criteria.reports_form(block, data);
  },
  reports_result: function (block, data) {
    block.removeClass('use-secure-view-on-links-setup');
    if (data) {
      // Update the search form results count bar manually
      var c = $('.result-count').html();
      var table_count = $('.count-only td[data-col-type="result_count"]').not('.report-el-was-from-new');
      var h;
      if (table_count.length === 1) {
        c = table_count.html();
      }
      c = parseInt(c);
      data.count = { count: c, show_count: c };

      if (_fpa.templates['search-count-template']) {
        var h = _fpa.templates['search-count-template'](data);
        $('.search_count_reports').html(h);
      }
    }


    window.setTimeout(function () {

      var by_auto_search_btn = $('#report-form-auto-submitter-btn');
      var by_auto_search = (by_auto_search_btn.attr('data-submitted') == 'true');
      by_auto_search_btn.attr('data-submitted', null);

      var table_cell_types = _fpa.postprocessors_reports.table_cell_types;
      if (data.count && data.count.count != 0 && !by_auto_search) {
        $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');
        _fpa.reports.report_position_buttons('go-to-results');
      }
      else {
        _fpa.reports.report_position_buttons('go-to-form');
        if (!by_auto_search) return;
      }

      $('td a.edit-entity').click(function () {
        $('.item-selected').removeClass('item-selected');
        $(this).parents('tr').first().addClass('item-selected');
      });
      $('td[data-col-type="master_id"]').on('click', function () {
        window.open('/masters/' + $(this).html().trim(), "_blank");
        $('.item-selected').removeClass('item-selected');
        $(this).addClass('item-selected');
      }).addClass('hover-link');

      for (var i in _fpa.state.alternative_id_fields) {
        var field = _fpa.state.alternative_id_fields[i];

        $('td[data-col-type="' + field + '"]').on('click', function () {
          window.open('/masters/' + $(this).html().trim() + '?type=' + $(this).attr('data-col-type'), "_blank");
          $('.item-selected').removeClass('item-selected');
          $(this).addClass('item-selected');
        }).addClass('hover-link');
      }

      for (var t in table_cell_types) {
        if (table_cell_types.hasOwnProperty(t)) {
          var table = table_cell_types[t];

          if ($('td[data-col-table="' + t + '"]').length > 0) {
            for (var i in table) {

              if (table.hasOwnProperty(i)) {

                col_types = table_cell_types[t];
                var idname = col_types[i];
                _fpa.cache.get_definition(i, function () {
                  var pe = _fpa.cache.fetch(i);
                  var cells = $('td[data-col-table="' + t + '"][data-col-type="' + idname + '"]');
                  cells.each(function () {
                    var cell = $(this);
                    var d = cell.html();
                    var p = _fpa.get_item_by('value', pe, d);

                    if (!p || p.value == null) {
                      p = _fpa.get_item_by('id', pe, d);
                    }
                    if (p) cell.append(' <em>' + p.name + '</em>');
                  });
                });
              }
            }
          }
        }
      }
      _fpa.reports.results_subsearch(block);
      _fpa.reports.results_perform_action_link(block);
      _fpa.reports.results_select_items_for_form(block);
      _fpa.reports_tree.show_table_as_tree(block.find('.report-results-table-block table.tree-table'));
      _fpa.form_utils.setup_tablesorter(block.find('.report-results-table-block'));
      block.find('.expandable').not('.attached-exp').on('click', function () {
        if ($(this).attr('disabled')) return;
        _fpa.form_utils.toggle_expandable($(this));
      }).addClass('attached-exp');
      $('prevent-scroll').removeClass('prevent-scroll');
      // Allow special handling when reports load 
      _fpa.reports.custom_results_handling(block, data);
    }, 50);

    window.setTimeout(function () {
      _fpa.postprocessors_reports.report_format_result_cells(block, data);
    }, 500);

  },

  report_format_result_cells: function (block, data) {
    $('td[data-col-type$="_when"], td[data-col-type$=" when"], td[data-col-type$="_date"], td[data-col-type$=" date"], td[data-col-type="date"], td[data-col-var-type="Date"], [data-col-var-type="Date"] rldata').not('.td-date-formatted, [data-col-var-type="Time"]').each(function () {
      var d = null;
      var val = $(this).html();
      if (val == 'Invalid DateTime')
        d = '';
      else if (!_fpa.utils.is_blank(val))
        d = _fpa.utils.YMDtoLocale(val);
      $(this).html(d);
    }).addClass('td-date-formatted');

    $('td[data-col-var-type="Time"], [data-col-var-type="Time"] rldata').not('.td-time-formatted').each(function () {
      var d = null;
      var val = $(this).html();
      if (val === 'Invalid DateTime')
        d = '';
      else if (!_fpa.utils.is_blank(val))
        d = _fpa.utils.YMDtimeToLocale(val);
      $(this).html(d);
    }).addClass('td-time-formatted');

    $('td[data-col-type$="_at"], td[data-col-type$="_time"], td[data-col-type$=" time"], td[data-col-type$=" at"]').not('.td-time-formatted').each(function () {
      var d = null;
      var val = $(this).html();
      if (val == 'Invalid DateTime')
        d = '';
      else if (val && val != '')
        d = _fpa.utils.YMDtimeToLocale(val);
      if (d && d.split(' ').length > 1) d = d.split(' ').slice(1).join(' ')
      $(this).html(d);
    }).addClass('td-time-formatted');

  },

  // Edit and New forms need some additional help, since we are attempting to push a form into a table row, which
  // is not valid HTML markup. Instead, we need to make use of the 'form' attribute on input, select and textarea elements,
  // which point the entry back to a form block that sits outside of the table.
  handle_report_edit_form: function (block, data) {


    var form = block.find('form');
    var form_id = form.attr('id');
    var row = block.find('tr');
    var item_id = form.attr('data-object-id');

    // if there is an item_id then we are editing a current row.
    // otherwise we are adding a new item
    if (item_id) {
      var orig_row = $('tr#report-item-' + item_id);
    }
    else {
      var orig_row = $('tr#report-item-new');
    }
    orig_row.after(row);
    orig_row.hide();

    // There are typically some hidden fields in the form that need to be moved in with the table fields
    var hidden = block.find('input');
    row.find('.report-edit-btn-cell').append(hidden);

    // Add the form attribute to the fields, pointing to the id of the form
    row.find('input, select, textarea, button').each(function () {
      $(this).attr('form', form_id);
    });

    // Format the block to ensure dates and masked fields, etc work as expected
    _fpa.form_utils.format_block(row);

    _fpa.utils.scrollTo(row, 200, -50);
    // Setup the cancel button
    row.find('#report-edit-cancel').click(function (ev) {
      ev.preventDefault();
      orig_row.show();
      row.remove();
      block.html('');
    });
  },


  report_edit_form: function (block, data) {

    // Copy the cells that aren't in the edit fields set
    window.setTimeout(function () {

      const $edit_row = $('tr.report-item-edit');

      // $edit_row.find('td').not('.report-edit-btn-cell').addClass('report-el-edit-cell');

      $('tr.item-selected td').not('.report-edit-btn-cell, .report-el-object-id, .attached_report_search').each(function () {
        const $this = $(this);
        const dct = $this.attr('data-col-type').replaceAll(/[^a-zA-Z0-9\-_]/g, '_');
        const $edit_cell = $(`td.report-el-edit-${dct}`);
        if ($edit_cell.length) return;

        const $newel = $this.clone();
        $newel.appendTo($edit_row);

        // If the field contains a canvas element, make sure it is set up
        const $canvas = $newel.find('canvas');
        if ($canvas.length === 0) return;

        const origcanvas = $this.find('canvas')[0];
        $canvas[0].getContext('2d').drawImage(origcanvas, 0, 0);
      })

      _fpa.postprocessors.handle_report_edit_form(block, data);
    }, 10)
  },

  edit_report_result: function (block, data) {
    $('#report-edit-').html("");
    var id = data.report_item.id;
    var row = $('#report-item-' + id);

    const mapping = {
      'div': 'div',
      'fixed-pre': 'pre',
      'checkbox': 'div',
      'options': 'div',
      'list': 'ul',
      'tags': 'div',
      'choice_label': 'div',
      'iframe': 'div'
    }


    // if we got a row, then we are simply replacing the data of an existing row based on an edit
    // otherwise we were adding a new item, and a row does not exist yet.
    if (row.length == 0) {
      var row = $('#report-item-new');
      row = row.after(row.clone());
      var newid = data.report_item['id'];
      row.attr('id', 'report-item-' + newid);
      var a = row.find('a.edit-entity');
      var href = a.attr('href');
      a.attr('href', href.replace('new', newid));
      row.find('.report-new-item-btn').remove();
      id = '';
    }

    var show_as = {};
    $('.table-header[data-col-show-as]').not('[data-col-show-as=""]').each(function () {
      const sa = $(this).attr('data-col-show-as');
      const name = $(this).attr('data-col-name');
      show_as[name] = sa;
    })

    for (var i in data.report_item) {
      if (data.report_item.hasOwnProperty(i)) {
        var cell_content = data.report_item[i];
        var cell = row.find('[data-col-type="' + i + '"]').first();

        // Show as a specific type
        var ct = cell.attr('data-col-type');
        var sa = show_as[ct];
        if (sa) {
          sa = mapping[sa] || sa
          cell_content = `<${sa}>${cell_content}</${sa}>`
        }

        // Format the cell if it is an array or show_as specifies it is tags
        var is_array = cell.attr('data-col-var-type') === 'Array';
        var is_tags = show_as[i] == 'tags';
        if (cell_content && (is_array || is_tags)) {
          var ul_class = is_tags ? 'report-result-cell-tags' : 'report-list-items'
          var $res = $(`<ul class="${ul_class}"></ul>`)
          cell_content.forEach((item) => {
            if (!item || item == '') return;

            var li = document.createElement('li');
            li.className = ul_class;
            li.innerHTML = item;
            $res.append(li)
          })

          cell_content = $res;
        }

        cell.html(cell_content);
      }
    };

    row.show();

    $('tr#report-item-edit-' + id).remove();
    $('tr#report-item-new').show();

    window.setTimeout(function () {
      row.find('.td-time-formatted').removeClass('td-time-formatted');
      row.find('.td-date-formatted').removeClass('td-date-formatted');
      _fpa.postprocessors_reports.report_format_result_cells(row, data);
    }, 50)

  },

  master_search_results: function (block, data) {
    $('#master_results_block').attr('data-report-res-name', data.report_res_name);
  }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_reports);
$.extend(_fpa.preprocessors, _fpa.preprocessors_reports);
