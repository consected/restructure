/*
 * Functionality specific to the FPHS Phase 1 app are found here
 * The aim is to keep most of the non-generic functionality outside of the main _fpa*.js files
 *
 */

_fpa.masters = {

    max_results: 100,

    switch_id_on_click: function (block) {
        block.find('.switch_id').not('attached-switch-click').click(function (ev) {
            ev.preventDefault();
            var p = $(this).parent();
            var alt_id = p.find('span.alt_id');
            var master_id = p.find('span.master_id');
            if (alt_id.is(':visible')) {
                alt_id.hide();
                master_id.show();
                $(this).attr('title', 'switch to Master ID');
            } else {
                master_id.hide();
                alt_id.show();
                $(this).attr('title', 'switch to alternative ID');
            }
        }).addClass('attached-switch-click');
    },

    // Function called when the main search page loads, initializing seach form specific functionality
    set_fields_to_search: function () {
        var forms = $('.search_master, form.search_report');

        _fpa.report_criteria.handle_search_form(forms);

        $('.clear-fields').not('.attached-clear-fields').on('click', function (ev) {
            if ($(this).attr('disabled')) return;
            ev.preventDefault();
            // Clear all values in the form
            forms.find('input, select').not('[type="submit"], [type="hidden"]').val(null).removeClass('has-value');
            // Handle the "Chosen" tag fields
            $('select.attached-chosen').trigger('chosen:updated');
            // Clear any existing results
            $('#master_results_block').html('<h3 class="text-center"></h3>');
            // Clear the results count
            $('#search_count_simple').html('');
            $('#search_count').html('');
        }).addClass('attached-clear-fields');

        $('#master_not_tracker_histories_attributes_0_sub_process_id').not('.attached-force-notice').on('change', function (ev) {
            var v = $(this).val();
            if (v && v !== '') {
                $('#search_count').html('');
                $('#master_results_block').html('<h3 class="text-center">Select any event to search for a protocol/category never having the selected process</h3>');
                $('.tsf-any-event-not').addClass('has-warning').one('change', function () {
                    $(this).removeClass('has-warning');
                });
                $('.tsf-any-event-not select').focus();
            } else {
                $(this).parents('form').submit();
            }
        }).addClass('attached-force-notice');

        $('#master_not_trackers_attributes_0_sub_process_id').not('.attached-force-notice').on('change', function (ev) {
            var v = $(this).val();
            if (v && v !== '') {
                $('#search_count').html('');
                $('#master_results_block').html('<h3 class="text-center">Select current event to search for a protocol/category not currently in the selected process</h3>');
                $('.tsf-current-event-not').addClass('has-warning').one('change', function () {
                    $(this).removeClass('has-warning');
                });
                $('.tsf-current-event-not select').focus();
            } else {
                $(this).parents('form').submit();
            }
        }).addClass('attached-force-notice');
    }

};

// Page specific loaded callback
_fpa.loaded.masters = function () {

    _fpa.masters.set_fields_to_search();

    $('#expand-adv-form').click(function () {
        $('#master_results_block').html('');
    });


    // On any entry in a form, clear the entries in the navbar search forms so there is no confusion
    // over what is being used
    $('form').not('.navbar-form').find('input, select').on('keypress change', function () {
        $('.navbar-form input[type="text"]').removeClass('has-value').val('');
    });

    $('form.new_master').on('submit', function () {
        _fpa.preprocessors.before_all($(this));
    });

    _fpa.report_criteria.handle_search_form($('form.auto_search_master'));


    // Prevent auto run reports under certain circumstances
    window.setTimeout(function () {

        var panel = $('.searchable-report-panel .collapse.in');
        if (panel && panel.length == 1) {
            if ($('#search-action').html() != ('MSID') && !$('#simple_m_id').val()) {
                // Prevent an auto run report if the page is refreshing with a requested master or result set
                if (!$('#master-search-accordion').hasClass('loading-results')) {
                    panel.find('[type="submit"].auto-run').click();
                }
            }
        }

        $('.searchable-report-panel').on('shown.bs.collapse', function () {
            $('#master_results_block').html('');
            var data = { count: { count: 0, show_count: 0 } };
            var h = _fpa.templates['search-count-template'](data);
            $('.search_count_reports').html(h);
            // Prevent an auto run report if the page is refreshing with a requested master or result set
            if (!$('#master-search-accordion').hasClass('loading-results')) {
                $(this).find('[type="submit"].auto-run').click();
            }
        });

        $('#master-search-accordion').removeClass('loading-results');

    }, 300);



    window.setTimeout(function () {
        $('.run-master-search').first().click();
    }, 500);



};
