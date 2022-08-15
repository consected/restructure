_fpa.loaded.page_layouts = function () {
  _fpa.page_layouts.load_columns()
}

_fpa.page_layouts = class {
  static load_columns(target) {
    if (target) target = `${target} `
    else target = ''
    $(`${target}.standalone-page-col`).each(function () {
      var block = $(this);
      var url = block.attr('data-url');
      _fpa.send_ajax_request(url, {
        try_app_callback: function (el, data) {
          var tb = block.find('.result-target-report');
          if (tb.length > 0) {
            tb.html(data);
            _fpa.postprocessors.reports_result(block, {});
          }
          else {
            tb = block.find('.result-target-resource');
            if (tb.length > 0) {
              window.setTimeout(function () {
                tb.find('.standalone-panel-generic-block.collapse').show();
                tb.find('.sublist-controls, .section-panel-header, .activity-logs-header, .new-blocks-container').remove();
                tb.find('.panel.panel-default').removeClass('panel panel-default');
                tb.find('.common-template-item').addClass('col-md-24 col-lg-24').removeClass('col-md-8 col-lg-6 col-md-12 col-lg-12').css({ minHeight: 'auto' });
              });

            }
          }
          block.removeClass('ajax-running');
        }
      });

    });

  }

}
