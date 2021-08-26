_fpa.postprocessors_ref_data = {

  ref_data_table_list_block: function (block) {
    var $schema_select = $('#primary_tables_schema_select');
    var $foh_checkbox = $('#primary_tables_filter_out_history');

    var filter_tables = function () {
      var foh = $foh_checkbox.is(':checked');
      var schema = $schema_select.val();
      $('.ref-tblock.in').each(function () {
        $(this).collapse('hide');
      })
      $('.ref-table-item').slideUp();
      if (foh) {
        $('.ref-table-item.regular-table[data-schema="' + schema + '"]').slideDown();
      } else {
        $('.ref-table-item[data-schema="' + schema + '"]').slideDown();
      }
    }

    $('#table-list').css({
      height: 'auto'
    });

    $schema_select.on('change', function () {
      filter_tables();

    })

    $foh_checkbox.on('change', function () {
      filter_tables();
    });

    // Handle dynamic loading of table columns when the table column block is shown;
    // the collapse show event is fired for whatever reason
    $('.ref-tblock').not('.content-loading, .content-loaded').on('show.bs.collapse', function () {
      var $el = $(this)
      $el.addClass('content-loading')
      var table = $el.attr('data-table-name')
      var schema = $el.attr('data-schema-name')
      var url = `/admin/reference_data/table_list_columns?schema_name=${schema}&table_name=${table}`
      $.ajax(url).done(function (data, status, xhr) {
        $el.html(data)
        $el.addClass('content-loaded').removeClass('content-loading')
      })
    })


    filter_tables();

  }

}

$.extend(_fpa.postprocessors, _fpa.postprocessors_ref_data);
