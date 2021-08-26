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

        filter_tables();

    }

}

$.extend(_fpa.postprocessors, _fpa.postprocessors_ref_data);
