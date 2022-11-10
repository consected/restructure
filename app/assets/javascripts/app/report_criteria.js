_fpa.report_criteria = class {

  static reports_form(block, data) {
    _fpa.form_utils.format_block(block);
    _fpa.reports.get_results_block().html('');


    _fpa.report_criteria.handle_search_form(block.find('form'));

    var by_auto_search_btn = $('#report-form-auto-submitter-btn');
    by_auto_search_btn.not('.asclick-attached').on('click', function () {
      by_auto_search_btn.attr('data-submitted', 'true');
    }).addClass('asclick-attached');

    block.find('a.btn[data-attribute]').click(function (ev) {
      ev.preventDefault();
      var da = $(this).attr('data-attribute');

      var v = $('#search_attrs_' + da);
      var newval = v.val();
      if (newval.length > 0) newval += "\n";
      var from_f = $('#multiple_attrs_' + da);
      var boxval = from_f.val();
      // Prevent empty values being put into the list
      if (boxval) {
        newval += boxval;
        v.val(newval);
        from_f.val('');
        v.change();
        from_f.change();
      }
    });

    block.find('form').not('.attached-complete-listener').on('submit', function () {
      // If there is a multivalue criteria field, ensure a field in the text box is added when we submit the form
      $('.multivalue-field-add').click();

    }).on('ajax:complete', function () {
      $('#search_attrs__filter_previous_').attr('checked', false);
      $('#filter_on_block').html('');
    }).addClass('attached-complete-listener');

    var cb = $('#search_attrs__filter_previous_').not('.attached-click-listener');
    var show_fob;
    if (cb.length === 1 && cb.is(':checked')) {
      window.setTimeout(function () {
        $('a#get_filter_previous').click();
      }, 100);
      show_fob = true;
    }

    cb.on('change', function () {
      if (!$('#search_attrs__filter_previous_').is(':checked')) {
        $('#filter_on_block').html('');
      } else {
        window.setTimeout(function () {
          $('a#get_filter_previous').click();
        }, 100);
      }
      return false;
    }).addClass('attached-click-listener');

    if (!show_fob) block.find('[type="submit"].auto-run').click();

  };

  static handle_search_form(forms) {

    // Step through all the search or report criteria forms
    forms.each(function () {
      var f = $(this);

      f.find('input[type="submit"]').on('click', function (e) {
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
      f.find('input, select, textarea').not('.no-auto-submit, .tt-input, .attached-change, [type="submit"]').on('change', function (e) {

        // Cancel any search-related Ajax requests that are still running
        _fpa.cancel_remote();


        // Handle the [data-only-for] marked up fields as special cases.
        // These fields will not automatically submit the form when changed, since they
        // are typically used to filter the content of a related select field.
        var dof = $(this).attr('data-only-for');
        var v = $(this).val();
        var all_null = true;
        if (dof) {
          // Allow multiple fields, any one of which may be entered
          $(dof).each(function () {
            var el = $(this);
            if (el.val() !== null && el.val() !== '' && !el.hasClass('prevent-submit')) all_null = false;
          });
        }
        if (!dof || !all_null) {
          // Assuming that we are not in data-only-for field, and all the fields on the form are not null,
          // then fire a submit
          // We do this within a timeout, to allow any DOM changes and CSS transitions to smoothly work through
          // otherwise the result is a very jerky experience
          // We delay longer than necessary to allow a form submit button click to process first, preventing this blocking
          // a valid button click
          window.setTimeout(function () {
            if (!_fpa.state.search_running) {
              var bel = f.find('[type="submit"].auto-submitter');
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
      f.find('input.tt-input').not('.attached-change').on('blur', function (e) {
        window.setTimeout(function () {
          f.find('[type="submit"].auto-submitter').click();
        }, 1);
      }).addClass('attached-change');



      f.find('[data-filter-selector]').on('change', function () {
        var fts = $(this).attr('data-filter-selector')
        _fpa.form_utils.select_filtering_changed($(this).val(), `[name="search_attrs[${fts}]"]`)
      })

      f.find('[type="submit"]').click(function () {
        var v = $(this).val();
        var dov = false;
        if (v === 'csv' || v === 'json') {
          dov = true;
        }
        var f = $(this).parents('form').first();
        // Must use data('remote') to disable the rails AJAX delegation. Setting the attribute doesn't work.
        f.data('remote', !dov).attr('target', (dov ? v : null));
        // For the report forms, set the 'part' to return appropriate results
        f.find('input[name="part"]').val(dov ? '' : 'results');

        if (dov) {
          $('#master_results_block').html('<h3 class="text-center">Exported ' + v + '</h3>');

          // UJS disables the buttons, but only ajax responses re-enable them.
          // For csv and json export requests, re-enable by hand
          window.setTimeout(function () {
            console.log('here')
            f.find('input[type="submit"][disabled], button[type="submit"][disabled]').attr('disabled', null).prop('disabled', null);
          }, 1500);
        }
      });
    }).on('keypress', function (e) {
      // On any keypress inside a form, cancel an existing ajax search, since the user is probably doing something else
      _fpa.cancel_remote();
    }).on('submit', function () {
      // When we submit the form, give the user a visual spinner so they know what's going on
      // This also clears existing search results to make it clear when a result is complete
      if ($(this).data('remote'))
        _fpa.reports.get_results_block().html('<h3 class="text-center"><span class="glyphicon glyphicon-search search-running"></span></h3>');
    });

  }

}