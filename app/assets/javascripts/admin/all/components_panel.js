// Lazy loading for the admin components panel.
// Elements with data-lazy-url have their content loaded asynchronously.
//
// Two cases:
// 1. #components-menu (Bootstrap collapse dropdown): loaded on first expand.
// 2. .admin-components-lazy-panel (index page sidebar): loaded on DOM ready.

$(document).on('show.bs.collapse', '#components-menu', function () {
  var $menu = $(this);
  var url = $menu.data('lazy-url');
  if (url && $menu.children().length === 0) {
    $menu.load(url);
  }
});

$(document).ready(function () {
  $('.admin-components-lazy-panel[data-lazy-url]').each(function () {
    var $panel = $(this);
    var url = $panel.data('lazy-url');
    if (url) {
      $panel.load(url);
    }
  });
});
