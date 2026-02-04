/*
 * Functionality specific to the FPHS Phase 1 app are found here
 * The aim is to keep most of the non-generic functionality outside of the main _fpa*.js files
 *
 */

_fpa.masters = {

    max_results: 100,
    auto_run_init_delay: 300,
    default_search_delay: 500,

    /**
     * Initialize switchable IDs to show the first non-"(none)" ID.
     * If all IDs are "(none)", shows the first one.
     * @param {jQuery} block - The block containing switchable ID elements
     */
    init_switchable_ids: function (block) {
        block.find('.result-refs').not('.initialized-switchable-ids').each(function () {
            var container = $(this);
            var switch_btn = container.find('.switch_id');
            var id_items = container.find('span.alt-id-item');

            if (id_items.length <= 1) return;

            // Find the first ID that is not "(none)"
            var first_non_none_index = -1;
            id_items.each(function (i) {
                var item_text = $(this).text().trim();
                if (item_text !== '(none)') {
                    first_non_none_index = i;
                    return false; // break out of each loop
                }
            });

            // If all are "(none)", keep the first one visible (default behavior)
            if (first_non_none_index <= 0) {
                container.addClass('initialized-switchable-ids');
                return;
            }

            // Hide all items
            id_items.hide();

            // Show the first non-none item
            var visible_item = id_items.eq(first_non_none_index);
            visible_item.show();

            // Update the switch button title to indicate the next ID to switch to
            var next_index = (first_non_none_index + 1) % id_items.length;
            var next_item = id_items.eq(next_index);
            var next_title = next_item.data('idLabel') || 'alternative ID';
            switch_btn.attr('title', 'switch to ' + next_title);

            container.addClass('initialized-switchable-ids');
        });
    },

    switch_id_on_click: function (block) {
        block.find('.switch_id').not('.attached-switch-click').click(function (ev) {
            ev.preventDefault();
            var p = $(this).parent();
            var id_items = p.find('span.alt-id-item');

            if (id_items.length <= 1) return;

            // Find the currently visible item
            var visible_index = -1;
            id_items.each(function (i) {
                if ($(this).is(':visible')) {
                    visible_index = i;
                    return false;
                }
            });

            // Hide all items
            id_items.hide();

            // Show the next item (cycling back to first)
            var next_index = (visible_index + 1) % id_items.length;
            var next_item = id_items.eq(next_index);
            next_item.show();

            // Update the switch icon title to indicate the next ID to switch to
            var after_next_index = (next_index + 1) % id_items.length;
            var after_next_item = id_items.eq(after_next_index);
            var next_title = after_next_item.data('idLabel') || 'alternative ID';
            $(this).attr('title', 'switch to ' + next_title);
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


    /**
     * Handle report tab visibility change.
     * On return visits (when AJAX has already fired), re-trigger the auto-run button.
     * On first visits, the reports_form postprocessor handles the click.
     * @param {jQuery} $panel - The collapsible panel that was shown
     */
    var handleReportTabShown = function ($panel) {
        var panelId = $panel.attr('id');
        if (!panelId) return;

        var reportName = panelId.replace('master-report-', '');
        var $tabLink = $('#expand-searchable-report-' + reportName);
        var $autoRunBtn = $panel.find('[type="submit"].auto-run');

        // Check if this tab's AJAX has already fired at least once
        var isReturnVisit = $tabLink.hasClass('one-time-only-fired');
        // Check if auto-run was already triggered during this expansion
        // (either by reports_form postprocessor on first visit, or already by us)
        var wasAlreadyClicked = $autoRunBtn.hasClass('was-auto-run-clicked');

        // Only re-run on return visits when the button hasn't been clicked yet in this expansion
        if (isReturnVisit && $autoRunBtn.length > 0 && !wasAlreadyClicked) {
            // Use a small delay to ensure the panel is fully expanded before triggering
            window.setTimeout(function () {
                $autoRunBtn.addClass('was-auto-run-clicked').click();
            }, 100);
        }
    };

    /**
     * Initialize auto-run functionality for searchable report tabs.
     * Prevents double-running by checking loading state and existing click markers.
     */
    var initializeAutoRunReports = function () {
        var panel = $('.searchable-report-panel .collapse.in');
        if (panel && panel.length === 1) {
            var isPageRefresh = $('#search-action').html() === 'MSID' || $('#simple_m_id').val();
            var isLoading = $('#master-search-accordion').hasClass('loading-results');

            if (!isPageRefresh && !isLoading) {
                panel.find('[type="submit"].auto-run')
                    .not('.was-auto-run-clicked')
                    .addClass('was-auto-run-clicked')
                    .click();
            }
        }
    };

    // Prevent auto run reports under certain circumstances
    window.setTimeout(initializeAutoRunReports, _fpa.masters.auto_run_init_delay);

    /**
     * Handle searchable report tab collapse.
     * Resets the auto-run state so the button can be clicked again on next expansion.
     * NOTE: We don't clear results here because the new tab's results may already be loading
     * @event hidden.bs.collapse
     */
    $('.searchable-report-panel .collapse').on('hidden.bs.collapse', function () {
        var $panel = $(this);
        // Reset the auto-run click marker when panel collapses
        // This allows the auto-run to trigger again on the next expansion
        $panel.find('[type="submit"].auto-run.was-auto-run-clicked')
            .removeClass('was-auto-run-clicked');
    });

    /**
     * Handle searchable report tab expansion.
     * Triggers search on return visits (when AJAX has already loaded the form).
     * NOTE: We don't clear results here because:
     * 1. reports_form already clears results when the form loads
     * 2. Clearing here would race with AJAX responses and wipe results in flight
     * @event shown.bs.collapse
     */
    $('.searchable-report-panel .collapse').on('shown.bs.collapse', function () {
        var $panel = $(this);

        if (!$('#master-search-accordion').hasClass('loading-results')) {
            handleReportTabShown($panel);
        }
    });

    $('#master-search-accordion').removeClass('loading-results');



    window.setTimeout(function () {
        $('.run-master-search').first().click();
    }, _fpa.masters.default_search_delay);



};
