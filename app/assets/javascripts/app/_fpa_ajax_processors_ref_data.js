_fpa.postprocessors_ref_data = {

  ref_data_table_list_block: function (block) {
    var $schema_select = $('#primary_tables_schema_select');
    var $foh_checkbox = $('#primary_tables_filter_out_history');

    // Postprocessors replace the default block formatting, so attach the "chosen" schema select here
    _fpa.form_utils.setup_chosen(block);

    // Filter the schema blocks
    var filter_schemas = function () {
      var schema = $schema_select.val()
      $('.table-list').collapse('hide')
      $(`#table-list-${schema}`).collapse('show')
    }

    // Filter out tables based on whether we should show history or not
    var filter_tables = function () {
      var foh = $foh_checkbox.is(':checked');

      if (foh) {
        // Make sure the columns for the tables are also hidden
        $('.ref-tblock.in').each(function () {
          $(this).collapse('hide');
        })
        $('.ref-table-item.history-table').slideUp();
        $('.ref-table-item.regular-table').slideDown();
      } else {
        $('.ref-table-item').slideDown();
      }
    }

    var setup_tables = function () {

      filter_tables()

      // Handle dynamic loading of table columns when the table column block is shown.
      // Responds to the collapse show event being fired for whatever reason
      // It stops propagation of the event, otherwise this will bubble up to the
      // schema block containing this table, making it fire
      $('.ref-tblock').not('.table-ev-setup').on('show.bs.collapse', function (ev) {
        ev.stopPropagation()
        var $el = $(this)
        if ($el.hasClass('content-loading') || $el.hasClass('content-loaded')) return;

        $el.addClass('content-loading')
        var schema = $el.attr('data-schema-name')
        var table = $el.attr('data-table-name')
        var url = `/admin/reference_data/table_list_columns?schema_name=${schema}&table_name=${table}`
        $.ajax(url).done(function (data, status, xhr) {
          $el.html(data)
          $el.addClass('content-loaded').removeClass('content-loading')
        })
      }).addClass('table-ev-setup')

    }

    // When we change schema selection, filter the blocks
    $schema_select.on('change', function () {
      filter_schemas();
    })

    // When we change the "filter out history" selection, fitler tables
    $foh_checkbox.on('change', function () {
      filter_tables();
    });

    var run_after_load = function ($el) {
      var callbacks = $el.data('after-load') || [];
      $el.data('after-load', []);
      callbacks.forEach(function (callback) { callback() });
    }

    // Load the tables for a schema block once. Any callback is run once the tables are available.
    var load_schema_tables = function ($el, done) {
      if (done) $el.data('after-load', ($el.data('after-load') || []).concat([done]));
      if ($el.hasClass('content-loading')) return;

      if (!$el.hasClass('content-loaded')) {
        $el.addClass('content-loading')
        var schema = $el.attr('data-schema-name')
        var url = `/admin/reference_data/table_list_tables?schema_name=${schema}`
        $.ajax(url).done(function (data, status, xhr) {
          $el.html(data)
          $el.addClass('content-loaded').removeClass('content-loading')
          setup_tables();
          run_after_load($el);
        })
        return;
      }
      run_after_load($el);
    }

    // Handle dynamic loading of tables when the schema block is shown.
    // Responds to the collapse show event being fired for whatever reason
    $('.table-list').not('.tablelist-ev-setup').on('show.bs.collapse', function () {
      load_schema_tables($(this));
    }).addClass('tablelist-ev-setup')

    // Show a schema and expand a table or view within it
    var expand_table = function (schema, table) {
      $schema_select.val(schema).trigger('chosen:updated').trigger('change');
      load_schema_tables($(`#table-list-${schema}`), function () {
        if ($(`#tblock-${schema}-${table}`).hasClass('in')) return;
        $(`#t-${schema}-${table} a.table-name-collapser`).click();
      })
    }

    // Typeahead search for a table or view name, across all schemas
    var $search = $('#primary_tables_search');
    var $search_options = $('#primary_tables_search_options option');

    var find_matches = function (term) {
      var filter_history = $foh_checkbox.is(':checked');
      return $search_options.filter(function () {
        var $option = $(this);
        var table = $option.attr('data-table-name');
        if (filter_history && /_history$/.test(table)) return false;
        return table.toLowerCase().indexOf(term) !== -1 || $option.val().toLowerCase().indexOf(term) !== -1;
      });
    }

    // When exactly one table or view matches the search, expand it
    $search.on('input change', function () {
      var term = $search.val().trim().toLowerCase();
      if (!term) return;

      var $matches = find_matches(term);
      if ($matches.length === 1) {
        expand_table($matches.attr('data-schema-name'), $matches.attr('data-table-name'));
      }
    });

    filter_tables();

  }

}

// Show a view definition in a read-only SQL editor, the first time its section is opened
$(document).on('shown.bs.collapse', '.ref-view-definition > .collapse', function () {
  if (typeof CodeMirror === 'undefined') return;

  var textarea = $(this).find('textarea.ref-view-definition__sql')[0];
  if (!textarea) return;

  if (textarea.CodeMirror) {
    textarea.CodeMirror.refresh();
    return;
  }
  var cm = CodeMirror.fromTextArea(textarea, {
    mode: 'text/x-sql',
    readOnly: true,
    lineNumbers: true,
    lineWrapping: true
  });
  textarea.CodeMirror = cm;
  cm.refresh();
});

$.extend(_fpa.postprocessors, _fpa.postprocessors_ref_data);
