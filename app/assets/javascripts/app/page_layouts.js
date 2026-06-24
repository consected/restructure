_fpa.loaded.page_layouts = function () {
  _fpa.page_layouts.load_columns()
  _fpa.page_layouts.setup_perspective_buttons($(document))

  // Update page title with the page layout label
  var $page = $('#standalone-page');
  if ($page.length) {
    var page_title = $page.attr('data-page-title');
    if (page_title) {
      _fpa.page_title.for_page_layout(page_title);
    }
  }
}

_fpa.page_layouts = class {
  // Load columns within a standalone page.
  // This is typically called when the page is loaded,
  // or through specific post processors, for example if
  // we embed a page layout in a standalone (portal) page
  static load_columns(target) {
    if (target) {
      // If this is a jQuery target, get the id to use, otherwise use the string provided or just set it to empty string
      if (target.attr) target = `#${target.prop('id')} `
      else target = `${target} `
    } else target = ''

    // Get the columns within the target and fire the URL for each specified in the data-url="" attribute
    $(`${target}.standalone-page-col`).each(function () {
      var block = $(this);
      var url = block.attr('data-url');
      _fpa.send_ajax_request(url, {
        try_app_callback: function (el, data) {
          var tb = block.find('.result-target-report');
          // If we are supposed to be returning a report result, process that
          if (tb.length > 0) {
            tb.html(data);
            _fpa.postprocessors.reports_result(block, {});
          }
          else {
            // We are processing a resource such as dynamic model or activity log. Handle the latter explicitly
            _fpa.page_layouts.handle_activity_log(block);
          }
          block.removeClass('ajax-running');
        }
      });

    });

  }

  // Activity logs embedded in the dashboards or standalone portal pages require controls to be stripped out
  // for more pleasing presentation. Handle this
  static handle_activity_log(block) {
    const tb = block.find('.result-target-resource');
    if (tb.length > 0) {
      window.setTimeout(function () {
        tb.find('.standalone-panel-generic-block.collapse').show();
        if (!tb.hasClass('keep-activity-log-sublist-controls')) {
          tb.find('.sublist-controls').remove();
        }
        if (!tb.hasClass('keep-activity-log-section-panel-header')) {
          tb.find('.section-panel-header').remove();
        }
        if (!tb.hasClass('keep-activity-log-header') && !tb.hasClass('keep-activity-log-action-buttons')) {
          tb.find('.activity-logs-header, .new-blocks-container').remove();
        }

        if (!tb.hasClass('keep-activity-log-header')) {
          tb.find('.activity-logs-header .list-group-item-heading').remove();
        }

        if (!tb.hasClass('keep-activity-log-action-controls')) {
          tb.find('.activity-logs-header .action-buttons, .new-blocks-container').remove();
        }

        tb.find('.panel.panel-default').removeClass('panel panel-default');
        tb.find('.common-template-item').addClass('col-md-24 col-lg-24').removeClass('col-md-8 col-lg-6 col-md-12 col-lg-12').css({ minHeight: 'auto' });
      }, 600);

    }
  }

  // Bind a delegated click handler to perspective buttons (.activity-log-perspectives__btn).
  // When a button is clicked it is marked active (siblings deactivated) and the standard
  // data-remote Rails UJS flow handles fetching and rendering the filtered list.
  // Uses event delegation so it works for buttons rendered dynamically from Handlebars templates.
  //
  // @param {jQuery} container - scope to bind within; call once with $(document).
  static setup_perspective_buttons(container) {
    if (container.data('perspectives-delegated')) return;
    container.data('perspectives-delegated', true);

    container.on('click', '.activity-log-perspectives__btn', function () {
      var $btn = $(this);
      var activePersp = $btn.data('perspective');

      // Update the injected clone immediately for visual feedback.
      $btn.closest('.activity-log-perspectives').find('.activity-log-perspectives__btn').removeClass('active');
      $btn.addClass('active');

      // Write the active perspective slug to the --source div so that when AJAX completes
      // and setup_sub_lists re-clones from --source, it can restore the correct active button.
      var $resourceBlock = $btn.closest('[data-sub-for-root]');
      if ($resourceBlock.length) {
        var $source = $resourceBlock.prevAll('.activity-log-perspectives--source').first();
        if ($source.length) {
          $source.attr('data-active-perspective', activePersp);
        }
      }

      // data-remote / Rails UJS handles the AJAX request automatically.
    });
  }

}
