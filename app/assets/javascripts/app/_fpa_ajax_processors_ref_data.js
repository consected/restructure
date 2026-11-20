_fpa.postprocessors_ref_data = {

  ref_data_table_list_block: function (block) {
    var $schema_select = $('#primary_tables_schema_select');
    var $foh_checkbox = $('#primary_tables_filter_out_history');
    var $search = $('#primary_tables_search');
    var search_items = $search.data('search-items') || [];

    // The table or view chosen by searching, as {schema, table}, or null when no single match is chosen
    var selected_table = null;

    // Postprocessors replace the default block formatting, so attach the "chosen" schema select here
    _fpa.form_utils.setup_chosen(block);

    // Look up an element by id without a jQuery selector, as schema and table names may contain characters
    // that are special in selectors (for example ".")
    var by_id = function (id) {
      return $(document.getElementById(id));
    }

    // Show the schema chosen in the schema select, or only the schema of the table chosen by searching
    var filter_schemas = function () {
      var schema = selected_table ? selected_table.schema : $schema_select.val();
      var $schema_list = schema ? by_id(`table-list-${schema}`) : $();

      // Hide the other schemas without hiding the chosen one first, as a hide in progress blocks showing it
      $('.table-list').not($schema_list).collapse('hide');
      $schema_list.collapse('show');
    }

    // Show the tables that match the history filter, or only the table chosen by searching
    var filter_tables = function () {
      var foh = $foh_checkbox.is(':checked');
      var selected_id = selected_table ? `t-${selected_table.schema}-${selected_table.table}` : null;

      $('.ref-table-item').each(function () {
        var $item = $(this);
        var visible = !(foh && $item.hasClass('history-table')) && (!selected_id || $item.attr('id') === selected_id);

        if (visible) {
          $item.slideDown();
        } else {
          // The columns block follows the table item, so hide it too
          $item.next('.ref-tblock').collapse('hide');
          $item.slideUp();
        }
      });
    }

    // Load the columns of a table into its columns block. On failure, show a message with a retry link
    var load_columns = function ($el) {
      $el.removeClass('content-loaded').addClass('content-loading').find('.ref-tblock__error').remove();
      var schema = $el.attr('data-schema-name')
      var table = $el.attr('data-table-name')
      var url = `/admin/reference_data/table_list_columns?schema_name=${encodeURIComponent(schema)}&table_name=${encodeURIComponent(table)}`
      $.ajax(url).done(function (data, status, xhr) {
        $el.html(data)
        $el.addClass('content-loaded').removeClass('content-loading')
      }).fail(function () {
        $el.removeClass('content-loading').empty()
        $el.append('<li class="ref-tblock__error help-block">Could not load the columns. <a href="#" class="ref-tblock__retry">Retry</a></li>')
      })
    }

    $(document).on('click', '.ref-tblock__retry', function (ev) {
      ev.preventDefault()
      load_columns($(this).closest('.ref-tblock'))
    })

    var apply_filters = function () {
      filter_schemas();
      filter_tables();
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

        load_columns($el)
      }).addClass('table-ev-setup')

    }

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
        var url = `/admin/reference_data/table_list_tables?schema_name=${encodeURIComponent(schema)}`
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

    // Show only the table or view chosen by searching, expanded, within its schema
    var select_table = function (schema, table) {
      if (selected_table && selected_table.schema === schema && selected_table.table === table) return;

      clear_selection();
      selected_table = { schema: schema, table: table };
      $schema_select.val(schema).trigger('chosen:updated');
      apply_filters();

      load_schema_tables(by_id(`table-list-${schema}`), function () {
        if (by_id(`tblock-${schema}-${table}`).hasClass('in')) return;
        by_id(`t-${schema}-${table}`).find('a.table-name-collapser').click();
      })
    }

    // Collapse the table chosen by searching, and go back to the normal filtering
    var clear_selection = function () {
      if (!selected_table) return;

      by_id(`tblock-${selected_table.schema}-${selected_table.table}`).collapse('hide');
      selected_table = null;
    }

    // Hide the suggestions menu, so it does not stay open over the results
    var close_menu = function () {
      $search.typeahead('close');
    }

    // Search across all schemas for a table or view name, matching on the schema qualified name
    var find_matches = function (term) {
      var filter_history = $foh_checkbox.is(':checked');
      return search_items.filter(function (item) {
        if (filter_history && item.history) return false;
        return item.label.toLowerCase().indexOf(term) !== -1;
      });
    }

    $search.typeahead({
      hint: true,
      highlight: true,
      minLength: 1,
      autoselect: true
    }, {
      name: 'primary_tables_search',
      limit: 50,
      display: 'label',
      source: function (query, sync) {
        sync(find_matches(query.trim().toLowerCase()));
      }
    });

    // Choosing a suggestion selects that table or view
    $search.on('typeahead:select typeahead:autocomplete', function (_ev, suggestion) {
      if (suggestion && suggestion.schema) select_table(suggestion.schema, suggestion.table);
      close_menu();
    });

    // When exactly one table or view matches the search, select it. When it does not, go back to normal filtering
    $search.on('input change search', function () {
      var term = $search.val().trim().toLowerCase();
      var matches = term ? find_matches(term) : [];

      if (matches.length === 1) {
        select_table(matches[0].schema, matches[0].table);
        close_menu();
      } else if (selected_table) {
        clear_selection();
        apply_filters();
      }
    });

    // When we change schema selection, clear any search and show the schema
    $schema_select.on('change', function () {
      clear_selection();
      $search.typeahead('val', '');
      apply_filters();
    })

    // When we change the "filter out history" selection, filter tables
    $foh_checkbox.on('change', function () {
      filter_tables();
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
