_fpa.postprocessors_ref_data = {

  ref_data_table_list_block: function (block) {
    var $schema_select = $('#primary_tables_schema_select');
    var $foh_checkbox = $('#primary_tables_filter_out_history');

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

    // Handle dynamic loading of tables when the schema block is shown.
    // Responds to the collapse show event being fired for whatever reason
    $('.table-list').not('.tablelist-ev-setup').on('show.bs.collapse', function () {
      var $el = $(this)
      if ($el.hasClass('content-loading') || $el.hasClass('content-loaded')) return;

      $el.addClass('content-loading')
      var schema = $el.attr('data-schema-name')
      var url = `/admin/reference_data/table_list_tables?schema_name=${schema}`
      $.ajax(url).done(function (data, status, xhr) {
        $el.html(data)
        $el.addClass('content-loaded').removeClass('content-loading')
        setup_tables();
      })
    }).addClass('tablelist-ev-setup')

    filter_tables();

  }

}

$.extend(_fpa.postprocessors, _fpa.postprocessors_ref_data);
