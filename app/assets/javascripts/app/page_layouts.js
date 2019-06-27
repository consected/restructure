_fpa.loaded.page_layouts = function() {

  $('.standalone-page-col').each(function() {
    var block = $(this);
    var url = block.attr('data-url');
    $.get(url).done(function(data) {
      block.find('.result-target').html(data);
      block.removeClass('ajax-running');
      _fpa.postprocessors.reports_result(block, {});
    });

  });

}
