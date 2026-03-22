_fpa.reports_custom_handling.add_handler_implementation('expand_all_tree', function () {
  const $new = $('<a href="#">expand all</a>');
  $('th[data-col-name="id0"] p.table-header-col-type').html($new);
  $new.on('click', function (ev) {
    const $a = $('th[data-col-name="id0"] p.table-header-col-type a');
    const orig_text = $a.text();
    $a.text('...');

    window.setTimeout(function () {
      if (orig_text == 'expand all') {
        $('tr[data-tt-id]').each(function () { $(this)[0].trExpand(true) })
        $a.text('shrink all')
      }
      else {
        $('tr[data-tt-id]').each(function () { $(this)[0].trCollapse(true) })
        $a.text('expand all')
      }
    });

    ev.preventDefault();
  })
});