/*
 * Functionality specific to the FPHS Phase 1 app are found here
 * The aim is to keep most of the non-generic functionality outside of the main _fpa*.js files
 *
 */

_fpa.masters = {

    max_results: 100,

    get_results_block: function () {
      return $('#embed_results_block,#master_results_block').last();
    },

    switch_id_on_click: function(block){
        block.find('.switch_id').not('attached-switch-click').click(function(ev){
            ev.preventDefault();
            var p = $(this).parent();
            var alt_id = p.find('span.alt_id');
            var master_id = p.find('span.master_id');
            if(alt_id.is(':visible')){
                alt_id.hide();
                master_id.show();
                $(this).attr('title', 'switch to Master ID');
            }else{
                master_id.hide();
                alt_id.show();
                $(this).attr('title', 'switch to alternative ID');
            }
        }).addClass('attached-switch-click');
    },

    handle_search_form:  function(forms){

        // There are currently two search forms available. Step through each of these in turn
        forms.each(function(){
            var f = $(this);

            f.find('input[type="submit"]').on('click', function(e) {
              if (_fpa.state.search_running) {
                e.preventDefault();
                return;
              }
            });

            // For every input and drop down on the form that is not a
            // typeahead field and is not already processed
            // check for changes
            // We add a class attached-change at the end to indicate that this field has been
            // has been processed and should not have another listener attached. Can avoid hard to debug
            // issues and provide extra information when looking at what has and hasn't been changed in the DOM
            f.find('input, select, textarea').not('.no-auto-submit, .tt-input, .attached-change, [type="submit"]').on('change', function(e){

                // Cancel any search-related Ajax requests that are still running
                _fpa.cancel_remote();


                // Handle the [data-only-for] marked up fields as special cases.
                // These fields will not automatically submit the form when changed, since they
                // are typically used to filter the content of a related select field.
                var dof = $(this).attr('data-only-for');
                var v = $(this).val();
                var all_null = true;
                if(dof){
                    // Allow multiple fields, any one of which may be entered
                    $(dof).each(function(){
                       var el = $(this);
                       if(el.val() !== null && el.val() !== '' && !el.hasClass('prevent-submit')) all_null = false;
                    });
                }
                if(!dof || !all_null){
                    // Assuming that we are not in data-only-for field, and all the fields on the form are not null,
                    // then fire a submit
                    // We do this within a timeout, to allow any DOM changes and CSS transitions to smoothly work through
                    // otherwise the result is a very jerky experience
                    // We delay longer than necessary to allow a form submit button click to process first, preventing this blocking
                    // a valid button click
                    window.setTimeout(function(){
                      if(!_fpa.state.search_running) {
                        var bel = f.find('input[type="submit"].auto-submitter');
                        if (bel.length > 0) {
                          bel.click();
                          _fpa.state.search_running = true;
                        }
                      }
                    }, 20);
                }
                // Clean up after ourselves
                $('.prevent-submit').removeClass('prevent-submit');

            }).addClass('attached-change');

            // Specifically for typeahead fields, we need to explicitly submit on blur. We assume that a typeahead can not
            // be a data-only-for field
            f.find('input.tt-input').not('.attached-change').on('blur', function(e){
                window.setTimeout(function(){
                    f.find('input[type="submit"].auto-submitter').click();
                },1);
            }).addClass('attached-change');




            f.find('input[type="submit"]').click(function(){
                var v = $(this).val();
                var dov = false;
                if(v === 'csv' || v === 'json'){
                    dov = true;
                }
                var f = $(this).parents('form').first();
                // Must use data('remote') to disable the rails AJAX delegation. Setting the attribute doesn't work.
                f.data('remote', !dov).attr('target', (dov ? v : null));
                // For the report forms, set the 'part' to return appropriate results
                f.find('input[name="part"]').val(dov ? '' : 'results');

                if(dov)
                    $('#master_results_block').html('<h3 class="text-center">Exported '+v+'</h3>');
            });
        }).on('keypress', function(e){
            // On any keypress inside a form, cancel an existing ajax search, since the user is probably doing something else
            _fpa.cancel_remote();
        }).on('submit', function(){
            // When we submit the form, give the user a visual spinner so they know what's going on
            // This also clears existing search results to make it clear when a result is complete
            if($(this).data('remote'))
                _fpa.masters.get_results_block().html('<h3 class="text-center"><span class="glyphicon glyphicon-search search-running"></span></h3>');
        });

    },

    // Function called when the main search page loads, initializing seach form specific functionality
    set_fields_to_search: function(){
        var forms = $('.search_master, form.search_report');

        _fpa.masters.handle_search_form(forms);

        $('.clear-fields').not('.attached-clear-fields').on('click', function(ev){
            if($(this).attr('disabled')) return;
            ev.preventDefault();
            // Clear all values in the form
            forms.find('input, select').not('[type="submit"], [type="hidden"]').val(null).removeClass('has-value');
            // Handle the "Chosen" tag fields
            $('select[multiple]').trigger('chosen:updated');
            // Clear any existing results
            $('#master_results_block').html('<h3 class="text-center"></h3>');
            // Clear the results count
            $('#search_count_simple').html('');
            $('#search_count').html('');
        }).addClass('attached-clear-fields');

        $('#master_not_tracker_histories_attributes_0_sub_process_id').not('.attached-force-notice').on('change', function(ev){
            var v = $(this).val();
            if(v && v !== ''){
                $('#search_count').html('');
                $('#master_results_block').html('<h3 class="text-center">Select any event to search for a protocol/category never having the selected process</h3>');
                $('.tsf-any-event-not').addClass('has-warning').one('change', function(){
                    $(this).removeClass('has-warning');
                });
                $('.tsf-any-event-not select').focus();
            }else
            {
                $(this).parents('form').submit();
            }
        }).addClass('attached-force-notice');

        $('#master_not_trackers_attributes_0_sub_process_id').not('.attached-force-notice').on('change', function(ev){
            var v = $(this).val();
            if(v && v !== ''){
                $('#search_count').html('');
                $('#master_results_block').html('<h3 class="text-center">Select current event to search for a protocol/category not currently in the selected process</h3>');
                $('.tsf-current-event-not').addClass('has-warning').one('change', function(){
                    $(this).removeClass('has-warning');
                });
                $('.tsf-current-event-not select').focus();
            }else
            {
                $(this).parents('form').submit();
            }
        }).addClass('attached-force-notice');
    }

};

// Page specific loaded callback
_fpa.loaded.masters = function(){

    _fpa.masters.set_fields_to_search();

    $('#expand-adv-form').click(function(){
        $('#master_results_block').html('');
    });


    // On any entry in a form, clear the entries in the navbar search forms so there is no confusion
    // over what is being used
    $('form').not('.navbar-form').find('input, select').on('keypress change', function(){
        $('.navbar-form input[type="text"]').removeClass('has-value').val('');
    });

    $('form.new_master').on('submit', function() {
      _fpa.preprocessors.before_all($(this));
    });

    _fpa.masters.handle_search_form($('form.auto_search_master'));


    // Prevent auto run reports under certain circumstances
    window.setTimeout(function(){

      var panel = $('.searchable-report-panel .collapse.in');
      if(panel && panel.length == 1) {
        if($('#search-action').html() != ('MSID')) {
          // Prevent an auto run report if the page is refreshing with a requested master or result set
          if(!$('#master-search-accordion').hasClass('loading-results')) {
            panel.find('input[type="submit"].auto-run').click();
          }
        }
      }

      $('.searchable-report-panel').on('shown.bs.collapse', function(){
        $('#master_results_block').html('');
        var data = {count: {count: 0, show_count: 0}};
        var h = _fpa.templates['search-count-template'](data);
        $('.search_count_reports').html(h);
        // Prevent an auto run report if the page is refreshing with a requested master or result set
        if(!$('#master-search-accordion').hasClass('loading-results')) {
          $(this).find('input[type="submit"].auto-run').click();
        }
      });

      $('#master-search-accordion').removeClass('loading-results');

    }, 300);



    window.setTimeout(function(){
      $('.run-master-search').first().click();
    }, 500);



};
