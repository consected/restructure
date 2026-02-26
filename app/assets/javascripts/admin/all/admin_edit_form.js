// Common setup across all admin types
_fpa_admin.all.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  static setup(block, data) {

    var aef = new _fpa_admin.all.admin_edit_form(block, data)

    aef.item_specific_setup('admin_edit_form')
    aef.admin_edit_form_setup()
    aef.setup_filtered_selects()
    aef.fix_filtered_select_values() // Fix selection for optgroups with duplicate values
    aef.setup_codemirror_editors()
    aef.setup_yaml_help_viewers()
    aef.setup_auto_loading_links()
    _fpa.form_utils.setup_big_select_fields(aef.block)
    _fpa.form_utils.on_open_click(aef.block);
    _fpa.form_utils.setup_drag_and_drop(aef.block);
    _fpa.form_utils.setup_copy_blocks(aef.block);

  }

  item_specific_setup(setup_type) {
    var block = this.block
    var data = this.data
    // If a specific admin_edit_form handler is in place for the controller, call it:
    // For example _fpa.reports.admin_edit_form
    var admin_type = block.parents('.admin-result-index[data-admin-type]').attr('data-admin-type');
    console.log(admin_type)
    if (admin_type && _fpa_admin[admin_type] && _fpa_admin[admin_type][setup_type])
      _fpa_admin[admin_type][setup_type].setup(block, data);

  }


  // Do some initial setup
  admin_edit_form_setup(no_scroll) {
    var block = this.block
    // Ensure we only scroll back to the form, not the top of the page
    if (!no_scroll) {
      $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');
      _fpa.utils.scrollTo(block, 200, -50);
    }
    // If the form is marked as having been saved, attempt to run the sample embedded report
    var si = block.find('.saved-item');
    if (si.length) {
      si.removeClass('saved-item');
      window.setTimeout(function () {
        $('#report-form-submit-btn').click();
      }, 150)
    }
    $('tr.new-record').before($('tr.admin-list-item').first());
    $('.saved-row').removeClass('saved-row');
    $('.edit-as-custom-setup').removeClass('edit-as-custom-setup');
    _fpa.form_utils.format_block(block);
    block.find('#admin-edit-cancel').click(function (ev) {
      ev.preventDefault();
      // Destroy Chosen instances before clearing the form to prevent orphaned dropdowns
      block.find('select.attached-chosen').each(function () {
        $(this).chosen('destroy');
      });
      block.html('');
    });

    var blocks = $('.shrinkable-block, .config-error-block')
    _fpa.utils.make_readable_notes_expandable(blocks, 100);

    // Force some initial configuration of textarea blocks
    window.setTimeout(function () {
      var el = $('.admin-edit-form textarea, .admin-edit-form .auto-click-link');
      el.click();
    }, 300);

  }

  // Filter select drop downs based on the selection of a previous drop down (typically the App Type)
  // Common functionality across multiple admin types
  // NOTE: This version is for admin forms. User forms use setup_form_filtered_select in _fpa_form_utils.js
  setup_filtered_selects() {
    var block = this.block

    block.find('select[data-filters-select]').not('.filters-select-attached').each(function () {
      var $el = $(this);
      var filter_sel_attr = $el.attr('data-filters-select');
      var filter_sels = filter_sel_attr.split(',');

      $el.on('change', function () {
        var val = $el.val();
        for (var i in filter_sels) {
          var filter_sel = filter_sels[i];
          var $filtered_select = $(filter_sel);

          // Capture current value before hiding optgroups
          var current_value = $filtered_select.val();

          // Hide non-matching optgroups and set disabled attribute so Chosen.js hides those options
          $(filter_sel + ' optgroup[data-group-num]').hide().attr('disabled', 'disabled');
          $(filter_sel + ' optgroup[data-group-num="' + val + '"]').show().attr('disabled', null);

          // Re-select the value in the visible optgroup if it exists there
          if (current_value) {
            var $visible_og = $(filter_sel + ' optgroup[data-group-num="' + val + '"]');
            var $matching_opt = $visible_og.find('option[value="' + current_value + '"]');
            if ($matching_opt.length > 0) {
              var select_el = $filtered_select[0];
              var all_opts = select_el.options;

              // Clear selected property from ALL options and remove selected attribute
              for (var j = 0; j < all_opts.length; j++) {
                all_opts[j].selected = false;
                all_opts[j].removeAttribute('selected');
              }

              // Set selected property and attribute on the correct option
              var correct_opt = $matching_opt[0];
              correct_opt.selected = true;
              correct_opt.setAttribute('selected', 'selected');

              // Also update selectedIndex
              for (var k = 0; k < all_opts.length; k++) {
                if (all_opts[k] === correct_opt) {
                  select_el.selectedIndex = k;
                  break;
                }
              }
            }
          }

          // Trigger chosen:updated to refresh the dropdown display
          $(filter_sel).trigger('chosen:updated');
        }
      });

      for (var i in filter_sels) {
        var filter_sel = filter_sels[i];
        var val = $el.val();

        // Parse optgroup labels and set data-group-num for filtering
        // Hide non-matching optgroups and set disabled attribute so Chosen.js hides those options
        $(filter_sel + ' optgroup[label]').each(function () {
          if (!$(this).attr('data-group-num')) {
            var l = $(this).attr('label');
            var ls = l.split('/', 2);
            var last = ls.length - 1;
            var first = 0;
            $(this).attr('label', ls[last]);
            $(this).attr('data-group-num', ls[first]);
          }

        }).hide().attr('disabled', 'disabled');
        $(filter_sel + ' optgroup[data-group-num="' + val + '"]').show().attr('disabled', null);

        // Trigger chosen:updated to refresh the dropdown display
        $(filter_sel).trigger('chosen:updated');
      }
    }).addClass('filters-select-attached');

  }

  // Fix selection values for filtered selects that have duplicate values across optgroups
  // This handles the case where Rails sets selected="selected" on multiple options with
  // the same value (in different optgroups), and the browser selects the wrong one.
  // This method runs AFTER setup_filtered_selects() and handles already-attached selects.
  fix_filtered_select_values() {
    var block = this.block;

    // Find all filter selects (the ones that trigger filtering of other selects)
    block.find('select[data-filters-select]').each(function () {
      var $filterSelect = $(this);
      var filterSelAttr = $filterSelect.attr('data-filters-select');
      var filterSels = filterSelAttr.split(',');
      var filterVal = $filterSelect.val(); // Current value of the filter (e.g., app_type_id)

      // For each select that gets filtered by this filter
      for (var i in filterSels) {
        var filterSel = filterSels[i];
        var $filteredSelect = $(filterSel);
        if ($filteredSelect.length === 0) continue;

        // Find the option with selected="selected" attribute (set by Rails)
        var $origSelected = $filteredSelect.find('option[selected="selected"]');
        if ($origSelected.length === 0) continue;

        var originalValue = $origSelected.first().val();
        if (!originalValue) continue;

        // Find the visible optgroup (matching the filter value)
        var $visibleOg = $(filterSel + ' optgroup[data-group-num="' + filterVal + '"]');
        if ($visibleOg.length === 0) continue;

        // Find the matching option in the visible optgroup
        var $matchingOpt = $visibleOg.find('option[value="' + originalValue + '"]');
        if ($matchingOpt.length === 0) continue;

        // Schedule the fix to run after Chosen.js initializes (which uses setTimeout 1ms)
        (function (filterSel, originalValue, filterVal, $filteredSelect, $matchingOpt) {
          setTimeout(function () {
            var selectEl = $filteredSelect[0];
            var allOpts = selectEl.options;
            var correctOpt = $matchingOpt[0];

            // Find the index of the correct option
            var correctIndex = -1;
            for (var k = 0; k < allOpts.length; k++) {
              if (allOpts[k] === correctOpt) {
                correctIndex = k;
                break;
              }
            }

            if (correctIndex >= 0) {
              // Set selectedIndex and update selected property on all options
              selectEl.selectedIndex = correctIndex;
              for (var j = 0; j < allOpts.length; j++) {
                allOpts[j].selected = (j === correctIndex);
              }

              // Trigger chosen:updated to refresh the dropdown
              $filteredSelect.trigger('chosen:updated');
            }
          }, 100); // Run after Chosen init and filter setup
        })(filterSel, originalValue, filterVal, $filteredSelect, $matchingOpt);
      }
    });
  }

  setup_codemirror_editors() {
    var block = this.block

    block.find('.code-editor').not('.code-editor-formatted').each(function () {
      var code_el = $(this).get(0);
      var lint;
      var mode = $(this).attr('data-code-editor-type');
      if (!mode) mode = 'yaml';
      // if(mode == 'yaml') {
      //   lint = true;
      //   mode = 'text/x-yaml';
      // }

      var cm = CodeMirror.fromTextArea(code_el, {
        lineNumbers: true,
        mode: mode,
        foldGutter: true,
        lint: lint,
        gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
        extraKeys: {
          Tab: function (cm) { cm.execCommand("indentMore") },
          "Shift-Tab": function (cm) { cm.execCommand("indentLess") }
        }
      });
      var cme = cm.getWrapperElement();
      cme.style.width = '100%';
      cme.style.height = '100%';
      code_el.CodeMirror = cm;
      cm.refresh();
    }).addClass('code-editor-formatted');

  }

  // Help and information viewers that include readonly codemirror blocks for YAML
  // display require some extra setup, and careful refreshing if they are hidden
  // in panels (or other blocks) when they become visible
  setup_yaml_help_viewers() {
    var block = this.block
    var _this = this


    // Setup each viewer
    block.find('.extra-help-info').not('.code-extra-help-info-formatted').each(function () {
      if (!$(this).is(':visible')) return;
      _this.setup_yaml_viewer($(this));
    }).addClass('code-extra-help-info-formatted');


    // When a tab is shown
    $('[data-toggle="tab"]').filter(':visible').on('shown.bs.tab', function () {

      var tar = $($(this).attr('href'));
      if (!tar.is(':visible')) return;

      var ehi = tar.find('.extra-help-info').not('.code-extra-help-info-formatted-in-tab');
      if (ehi.length) {
        CodeMirror.fromTextArea(ehi[0]).refresh();
        ehi.addClass('code-extra-help-info-formatted-in-tab')
      }
    })

    // When a tab collapses
    $('.collapse.has-editor').on('shown.bs.collapse', function () {
      var ehi = $(this).find('.extra-help-info').not('.code-extra-help-info-formatted-in-collapse, .code-extra-help-info-formatted-in-tab').filter(':visible');
      ehi.each(function () {
        _this.setup_yaml_editor($(this));
        ehi.addClass('code-extra-help-info-formatted-in-collapse code-extra-help-info-formatted-in-tab')
      });
    })

  }

  setup_yaml_viewer(container) {

    var code_el = container.get(0);
    var mode = container.attr('data-code-editor-type');
    if (!mode) mode = 'yaml';

    var cm = CodeMirror.fromTextArea(code_el, {
      lineNumbers: true,
      mode: mode,
      readOnly: true,
      foldGutter: true,
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
    });

    var cme = cm.getWrapperElement();
    cme.style.width = '100%';
    cme.style.height = '100%';
    cme.style.backgroundColor = 'rgba(255,255,255, 0.2)';
    code_el.CodeMirror = cm;
    cm.refresh();

  }

  setup_yaml_editor(container) {
    var code_el = container.get(0);
    var mode = container.attr('data-code-editor-type');
    if (!mode) mode = 'yaml';

    var cm = CodeMirror.fromTextArea(code_el, {
      lineNumbers: true,
      mode: mode,
      readOnly: false,
      foldGutter: true,
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
    });

    var cme = cm.getWrapperElement();
    cme.style.width = '100%';
    cme.style.height = '100%';
    cme.style.backgroundColor = 'rgb(255,255,255)';
    code_el.CodeMirror = cm;
    cm.refresh();

  }


  // Some links are marked with a class *on-show-auto-click*, indicating they are
  // to be triggered automatically when the tab panel becomes visible
  setup_auto_loading_links() {
    var block = this.block

    window.setTimeout(function () {
      // Handle auto opening of links in tab panels
      block.find('[data-toggle="tab"]').on('show.bs.tab', function () {
        $($(this).attr('href')).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
      }).addClass('attached-tab-show');

      // Handle auto opening of links in tab panels when the initial panel is already open
      block.find('[data-toggle="tab"][aria-expanded="true"]').not('.attached-tab-init').each(function () {
        $($(this).attr('href')).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
      }).addClass('attached-tab-init')
    }, 100);

  }


}
